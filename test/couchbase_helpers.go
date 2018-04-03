package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/http"
	"time"
	"github.com/stretchr/testify/assert"
	"testing"
	"log"
	"strings"
	"github.com/gruntwork-io/terratest/util"
	"encoding/json"
	"github.com/gruntwork-io/terratest"
	"github.com/gruntwork-io/terratest/test-structure"
	"github.com/gruntwork-io/terratest/aws"
)

func checkCouchbaseConsoleIsRunning(t *testing.T, clusterUrl string, logger *log.Logger) {
	maxRetries := 60
	sleepBetweenRetries := 5 * time.Second

	err := http_helper.HttpGetWithRetryWithCustomValidation(clusterUrl, maxRetries, sleepBetweenRetries, logger, func(status int, body string) bool {
		return status == 200 && strings.Contains(body, "Couchbase Console")
	})

	if err != nil {
		t.Fatalf("Failed to connect to Couchbase at %s: %v", clusterUrl, err)
	}
}

// A partial representation of the JSON structure returned by the server node API:
// https://developer.couchbase.com/documentation/server/3.x/admin/REST/rest-node-get-info.html
type ServerNodeResponse struct {
	Nodes []ServerNode `json:"nodes"`
}

type ServerNode struct {
	Status string `json:"status"`
	Hostname string `json:"hostname"`
	ClusterMembership string `json:"clusterMembership"`
}

func checkCouchbaseClusterIsInitialized(t *testing.T, clusterUrl string, expectedNodes int, logger *log.Logger) {
	maxRetries := 200
	sleepBetweenRetries := 5 * time.Second
	serverNodeUrl := fmt.Sprintf("%s/pools/nodes", clusterUrl)

	err := http_helper.HttpGetWithRetryWithCustomValidation(serverNodeUrl, maxRetries, sleepBetweenRetries, logger, func(status int, body string) bool {
		if status != 200 {
			logger.Printf("Expected a 200 OK from %s but got %d", serverNodeUrl, status)
			return false
		}

		var serverNodesReponse ServerNodeResponse
		if err := json.Unmarshal([]byte(body), &serverNodesReponse); err != nil {
			logger.Printf("Failed to parse response from %s due to error %v. Response body:\n%s", serverNodeUrl, err, body)
			return false
		}

		if len(serverNodesReponse.Nodes) != expectedNodes {
			logger.Printf("Expected to find %d nodes in the cluster, but %s returned %d. Response body:\n%s", expectedNodes, serverNodeUrl, len(serverNodesReponse.Nodes), body)
			return false
		}

		for _, serverNode := range serverNodesReponse.Nodes {
			logger.Printf("Checking state of node %s", serverNode.Hostname)

			if serverNode.Status != "healthy" {
				logger.Printf("Expected all nodes to be in 'healthy' state, but node %s is in state '%s'", serverNode.Hostname, serverNode.Status)
				return false
			}

			if serverNode.ClusterMembership != "active" {
				logger.Printf("Expected all nodes to be 'active' in the cluster, but node %s has cluster membership state '%s'", serverNode.Hostname, serverNode.ClusterMembership)
				return false
			}
		}

		return true
	})

	if err != nil {
		t.Fatalf("Failed to connect to Couchbase at %s: %v", serverNodeUrl, err)
	}
}

type TestData struct {
	Foo string `json:"foo"`
	Bar int `json:"bar"`
}

func (testData TestData) String() string {
	return fmt.Sprintf("TestData{Foo: '%s', Bar: %d}", testData.Foo, testData.Bar)
}

type CouchbaseTestDataResponse struct {
	Meta CouchbaseMeta `json:"meta"`
	Json TestData `json:"json"`
}

type CouchbaseMeta struct {
	Id string `json:"id"`
	Rev string `json:"rev"`
	Expiration int `json:"expiration"`
	Flags int `json:"flags"`
}

func checkCouchbaseDataNodesWorking(t *testing.T, dataNodesUrl string, logger *log.Logger) {
	uniqueId := util.UniqueId()
	testBucketName := fmt.Sprintf("test%s", uniqueId)
	testKey := fmt.Sprintf("test-key-%s", uniqueId)
	testValue := TestData{
		Foo: fmt.Sprintf("test-value-%s", uniqueId),
		Bar: 42,
	}

	createBucket(t, dataNodesUrl, testBucketName, logger)
	writeToBucket(t, dataNodesUrl, testBucketName, testKey, testValue, logger)

	actualValue := readFromBucket(t, dataNodesUrl, testBucketName, testKey, logger)
	assert.Equal(t, testValue, actualValue)
}

// Create a Couchbase bucket. Note that we do NOT use any Couchbase SDK here because this test runs against a
// Dockerized cluster, and the SDK does not work with Dockerized clusters, as it tries to use IPs that are only
// accessible from inside a Docker container. Therefore, we just use the HTTP API directly. For more info, search for
// "Connect via SDK" on this page: https://developer.couchbase.com/documentation/server/current/install/docker-deploy-multi-node-cluster.html
func createBucket(t *testing.T, clusterUrl string, bucketName string, logger *log.Logger) {
	description := fmt.Sprintf("Creating bucket %s", bucketName)
	maxRetries := 10
	sleepBetweenRetries := 5 * time.Second

	logger.Printf(description)

	// https://developer.couchbase.com/documentation/server/3.x/admin/REST/rest-bucket-create.html
	createBucketUrl := fmt.Sprintf("%s/pools/default/buckets", clusterUrl)
	postParams := map[string][]string{
		"name": {bucketName},
		"bucketType": {"couchbase"},
		"authType": {"sasl"},
		"saslPassword": {passwordForTest},
		"ramQuotaMB": {"100"},
	}

	_, err := util.DoWithRetry(description, maxRetries, sleepBetweenRetries, logger, func() (string, error) {
		statusCode, body, err := HttpPostForm(t, createBucketUrl, postParams, logger)
		if err != nil {
			return "", err
		}

		if statusCode == 202 {
			logger.Printf("Successfully created bucket %s", bucketName)
			return "", nil
		}

		logger.Printf("Expected status code 202, but got %d", statusCode)

		if strings.Contains(body, "Cannot create buckets during rebalance") {
			return "", fmt.Errorf("Cluster is currently rebalancing. Cannot create bucket right now.")
		} else {
			return "", fmt.Errorf("Unexpected error: %v", body)
		}
	})

	if err != nil {
		t.Fatalf("Failed to create bucket %s: %v", bucketName, err)
	}

	// It takes a little bit of time for Couchbase to create the bucket. If you don't wait and immediately try to open
	// the bucket, you get a confusing authentication error.
	logger.Printf("Waiting a few seconds for the bucket to be created")
	time.Sleep(15 * time.Second)
}

// Write to a Couchbase bucket. Note that we do NOT use any Couchbase SDK here because this test runs against a
// Dockerized cluster, and the SDK does not work with Dockerized clusters, as it tries to use IPs that are only
// accessible from inside a Docker container. Therefore, we just use the HTTP API directly. For more info, search for
// "Connect via SDK" on this page: https://developer.couchbase.com/documentation/server/current/install/docker-deploy-multi-node-cluster.html
func writeToBucket(t *testing.T, clusterUrl string, bucketName string, key string, value TestData, logger *log.Logger) {
	logger.Printf("Writing (%s, %s) to bucket %s", key, value, bucketName)

	jsonBytes, err := json.Marshal(value)
	if err != nil {
		t.Fatalf("Failed to encode value %v as JSON: %v", value, err)
	}

	// This is an undocumented API. I found it here: https://stackoverflow.com/a/37425574/483528. You can also find it
	// by using the Couchbase web console and inspecting the requests that it is sending.
	bucketUrl := fmt.Sprintf("%s/pools/default/buckets/%s/docs/%s", clusterUrl, bucketName, key)
	postParams := map[string][]string{
		"value": {string(jsonBytes)},
	}

	description := fmt.Sprintf("Write to bucket params: %s", string(jsonBytes))
	retries := 30
	timeBetweenRetries := 5 * time.Second

	// Buckets take a while to replicate, and until they do, you get vague errors such as "Unexpected server error",
	// so retry a few times.
	out, err := util.DoWithRetry(description, retries, timeBetweenRetries, logger, func() (string, error) {
		statusCode, body, err := HttpPostForm(t, bucketUrl, postParams, logger)
		if err != nil {
			return "", err
		}

		if statusCode != 200 {
			return "", fmt.Errorf("Expected status code 200 when writing (%s, %s) to bucket %s, but got %d. Repsonse body: %s", key, value, bucketName, statusCode, body)
		}

		return fmt.Sprintf("Successfully wrote (%s, %s) to bucket %s", key, value, bucketName), nil
	})

	if err != nil {
		t.Fatalf("Failed to write to (%s, %s) to bucket %s: %v", key, value, bucketName, err)
	}

	logger.Printf(out)
}
// Read from a Couchbase bucket. Note that we do NOT use any Couchbase SDK here because this test runs against a
// Dockerized cluster, and the SDK does not work with Dockerized clusters, as it tries to use IPs that are only
// accessible from inside a Docker container. Therefore, we just use the HTTP API directly. For more info, search for
// "Connect via SDK" on this page: https://developer.couchbase.com/documentation/server/current/install/docker-deploy-multi-node-cluster.html
func readFromBucket(t *testing.T, clusterUrl string, bucketName string, key string, logger *log.Logger) TestData {
	description := fmt.Sprintf("Reading key %s from bucket %s", key, bucketName)
	maxRetries := 10
	timeBetweenRetries := 5 * time.Second

	// This is an undocumented API. I found it here: https://stackoverflow.com/a/37425574/483528. You can also find it
	// by using the Couchbase web console and inspecting the requests that it is sending.
	bucketUrl := fmt.Sprintf("%s/pools/default/buckets/%s/docs/%s", clusterUrl, bucketName, key)

	logger.Printf(description)
	body, err := util.DoWithRetry(description, maxRetries, timeBetweenRetries, logger, func() (string, error) {
		statusCode, body, err := http_helper.HttpGet(bucketUrl, logger)

		if err != nil {
			return "", err
		}

		if statusCode != 200 {
			return "", fmt.Errorf("Expected status code 200 when reading key %s from bucket %s, but got %d", key, bucketName, statusCode)
		}

		return body, nil
	})

	if err != nil {
		t.Fatal(err)
	}

	var value CouchbaseTestDataResponse
	if err := json.Unmarshal([]byte(body), &value); err != nil {
		t.Fatalf("Failed to parse body '%s' for key %s in bucket %s: %v", body, key, bucketName, err)
	}

	logger.Printf("Got back %v for key %s from bucket %s", value, key, bucketName)

	return value.Json
}

func checkSyncGatewayWorking(t *testing.T, syncGatewayUrl string, logger *log.Logger) {
	// It can take a LONG time for the Couchbase cluster to rebalance itself, so we may have to wait a while
	maxRetries := 200
	sleepBetweenRetries := 5 * time.Second

	err := http_helper.HttpGetWithRetryWithCustomValidation(syncGatewayUrl, maxRetries, sleepBetweenRetries, logger, func(status int, body string) bool {
		return status == 200 && strings.Contains(body, `"state":"Online"`)
	})

	if err != nil {
		t.Fatalf("Unable to connect to Sync Gateway at %s: %v", syncGatewayUrl, err)
	}
}

func testStageBuildCouchbaseAmi(t *testing.T, osName string, couchbaseAmiDir string, couchbaseTerraformDir string, logger *log.Logger) {
	resourceCollection := createBaseRandomResourceCollection(t)
	amiId, err := buildCouchbaseWithPacker(logger, fmt.Sprintf("%s-ami", osName), fmt.Sprintf("couchbase-%s", resourceCollection.UniqueId), resourceCollection.AwsRegion, couchbaseAmiDir)
	if err != nil {
		t.Fatalf("Failed to build Couchbase AMI: %v", err)
	}

	test_structure.SaveAmiId(t, couchbaseTerraformDir, amiId, logger)
	test_structure.SaveRandomResourceCollection(t, couchbaseTerraformDir, resourceCollection, logger)
}

func testStageTeardown(t *testing.T, couchbaseTerraformDir string, logger *log.Logger) {
	resourceCollection := test_structure.LoadRandomResourceCollection(t, couchbaseTerraformDir, logger)
	terratestOptions := test_structure.LoadTerratestOptions(t, couchbaseTerraformDir, logger)

	if _, err := terratest.Destroy(terratestOptions, resourceCollection); err != nil {
		t.Fatalf("Failed to run destory: %v", err)
	}

	test_structure.CleanupAmiId(t, couchbaseTerraformDir, logger)
	test_structure.CleanupTerratestOptions(t, couchbaseTerraformDir, logger)
	test_structure.CleanupRandomResourceCollection(t, couchbaseTerraformDir, logger)
}

func getClusterName(t *testing.T, clusterVarName string, terratestOptions *terratest.TerratestOptions) string {
	clusterNameVal, ok := terratestOptions.Vars[clusterVarName]
	if !ok {
		t.Fatalf("Could not find cluster name in TerratestOptions Var %s", clusterVarName)
	}

	return fmt.Sprintf("%v", clusterNameVal)
}

func testStageLogs(t *testing.T, couchbaseTerraformDir string, clusterVarName string, logger *log.Logger) {
	resourceCollection := test_structure.LoadRandomResourceCollection(t, couchbaseTerraformDir, logger)
	terratestOptions := test_structure.LoadTerratestOptions(t, couchbaseTerraformDir, logger)

	clusterName := getClusterName(t, clusterVarName, terratestOptions)

	logs, err := aws.GetSyslogForInstancesInAsg(clusterName, resourceCollection.AwsRegion, logger)
	if err != nil {
		t.Fatalf("Failed to fetch syslog: %v", err)
	}

	logger.Printf("\n\n============== Logs for cluster %s ==============", clusterName)
	for instanceId, syslog := range logs {
		logger.Printf("Most recent 64 KB of logs for instance %s in %s:\n\n%s\n\n", instanceId, resourceCollection.AwsRegion, syslog)
	}
}

// Format a unique name for the Couchbase cluster. Note that Couchbase DB names must be lower case.
func formatCouchbaseClusterName(baseName string, resourceCollection *terratest.RandomResourceCollection) string {
	return strings.ToLower(fmt.Sprintf("%s-%s", baseName, resourceCollection.UniqueId))
}
