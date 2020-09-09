package test

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

const AWS_DEFAULT_REGION_ENV_VAR = "AWS_DEFAULT_REGION"

func checkCouchbaseConsoleIsRunning(t *testing.T, clusterUrl string) {
	maxRetries := 180
	sleepBetweenRetries := 5 * time.Second

	webConsoleUrl := fmt.Sprintf("%s/ui/index.html", clusterUrl)
	http_helper.HttpGetWithRetryWithCustomValidation(t, webConsoleUrl, nil, maxRetries, sleepBetweenRetries, func(status int, body string) bool {
		return status == 200 && strings.Contains(body, "Couchbase Server")
	})
}

// A partial representation of the JSON structure returned by the server node API:
// https://developer.couchbase.com/documentation/server/3.x/admin/REST/rest-node-get-info.html
type ServerNodeResponse struct {
	Nodes []ServerNode `json:"nodes"`
}

type ServerNode struct {
	Status            string `json:"status"`
	Hostname          string `json:"hostname"`
	ClusterMembership string `json:"clusterMembership"`
}

func checkCouchbaseClusterIsInitialized(t *testing.T, clusterUrl string, expectedNodes int) {
	maxRetries := 300
	sleepBetweenRetries := 5 * time.Second
	serverNodeUrl := fmt.Sprintf("%s/pools/nodes", clusterUrl)

	http_helper.HttpGetWithRetryWithCustomValidation(t, serverNodeUrl, nil, maxRetries, sleepBetweenRetries, func(status int, body string) bool {
		if status != 200 {
			logger.Logf(t, "Expected a 200 OK from %s but got %d", serverNodeUrl, status)
			return false
		}

		var serverNodesReponse ServerNodeResponse
		if err := json.Unmarshal([]byte(body), &serverNodesReponse); err != nil {
			logger.Logf(t, "Failed to parse response from %s due to error %v. Response body:\n%s", serverNodeUrl, err, body)
			return false
		}

		if len(serverNodesReponse.Nodes) != expectedNodes {
			logger.Logf(t, "Expected to find %d nodes in the cluster, but %s returned %d. Response body:\n%s", expectedNodes, serverNodeUrl, len(serverNodesReponse.Nodes), body)
			return false
		}

		for _, serverNode := range serverNodesReponse.Nodes {
			logger.Logf(t, "Checking state of node %s", serverNode.Hostname)

			if serverNode.Status != "healthy" {
				logger.Logf(t, "Expected all nodes to be in 'healthy' state, but node %s is in state '%s'", serverNode.Hostname, serverNode.Status)
				return false
			}

			if serverNode.ClusterMembership != "active" {
				logger.Logf(t, "Expected all nodes to be 'active' in the cluster, but node %s has cluster membership state '%s'", serverNode.Hostname, serverNode.ClusterMembership)
				return false
			}
		}

		return true
	})
}

type TestData struct {
	Foo string `json:"foo"`
	Bar int    `json:"bar"`
}

func (testData TestData) String() string {
	return fmt.Sprintf("TestData{Foo: '%s', Bar: %d}", testData.Foo, testData.Bar)
}

type CouchbaseTestDataResponse struct {
	Meta CouchbaseMeta `json:"meta"`
	Json string        `json:"json"`
}

type CouchbaseMeta struct {
	Id         string `json:"id"`
	Rev        string `json:"rev"`
	Expiration int    `json:"expiration"`
	Flags      int    `json:"flags"`
}

func checkCouchbaseDataNodesWorking(t *testing.T, dataNodesUrl string) {
	uniqueId := random.UniqueId()
	testBucketName := fmt.Sprintf("test%s", uniqueId)
	testKey := fmt.Sprintf("test-key-%s", uniqueId)
	testValue := TestData{
		Foo: fmt.Sprintf("test-value-%s", uniqueId),
		Bar: 42,
	}

	createBucket(t, dataNodesUrl, testBucketName)
	writeToBucket(t, dataNodesUrl, testBucketName, testKey, testValue)

	actualValue := readFromBucket(t, dataNodesUrl, testBucketName, testKey)
	assert.Equal(t, testValue, actualValue)
}

func checkReplicationIsWorking(t *testing.T, dataNodesUrlPrimary string, dataNodesUrlReplica string, bucketPrimary string, bucketReplica string) {
	uniqueId := random.UniqueId()
	testKey := fmt.Sprintf("test-key-%s", uniqueId)
	testValue := TestData{
		Foo: fmt.Sprintf("test-value-%s", uniqueId),
		Bar: 42,
	}

	writeToBucket(t, dataNodesUrlPrimary, bucketPrimary, testKey, testValue)
	actualValue := readFromBucket(t, dataNodesUrlReplica, bucketReplica, testKey)

	assert.Equal(t, testValue, actualValue)
}

// Create a Couchbase bucket. Note that we do NOT use any Couchbase SDK here because this test runs against a
// Dockerized cluster, and the SDK does not work with Dockerized clusters, as it tries to use IPs that are only
// accessible from inside a Docker container. Therefore, we just use the HTTP API directly. For more info, search for
// "Connect via SDK" on this page: https://developer.couchbase.com/documentation/server/current/install/docker-deploy-multi-node-cluster.html
func createBucket(t *testing.T, clusterUrl string, bucketName string) {
	description := fmt.Sprintf("Creating bucket %s", bucketName)
	maxRetries := 120
	sleepBetweenRetries := 5 * time.Second

	logger.Log(t, description)

	// https://developer.couchbase.com/documentation/server/3.x/admin/REST/rest-bucket-create.html
	createBucketUrl := fmt.Sprintf("%s/pools/default/buckets", clusterUrl)
	postParams := map[string][]string{
		"name":         {bucketName},
		"bucketType":   {"couchbase"},
		"authType":     {"sasl"},
		"saslPassword": {passwordForTest},
		"ramQuotaMB":   {"100"},
	}

	retry.DoWithRetry(t, description, maxRetries, sleepBetweenRetries, func() (string, error) {
		statusCode, body, err := HttpPostForm(t, createBucketUrl, postParams)
		if err != nil {
			return "", err
		}

		if statusCode == 202 {
			logger.Logf(t, "Successfully created bucket %s", bucketName)
			return "", nil
		}

		logger.Logf(t, "Expected status code 202, but got %d", statusCode)

		if strings.Contains(body, "Cannot create buckets during rebalance") {
			return "", fmt.Errorf("Cluster is currently rebalancing. Cannot create bucket right now.")
		} else {
			return "", fmt.Errorf("Unexpected error: %v", body)
		}
	})

	// It takes a little bit of time for Couchbase to create the bucket. If you don't wait and immediately try to open
	// the bucket, you get a confusing authentication error.
	logger.Logf(t, "Waiting a few seconds for the bucket to be created")
	time.Sleep(15 * time.Second)
}

// Write to a Couchbase bucket. Note that we do NOT use any Couchbase SDK here because this test runs against a
// Dockerized cluster, and the SDK does not work with Dockerized clusters, as it tries to use IPs that are only
// accessible from inside a Docker container. Therefore, we just use the HTTP API directly. For more info, search for
// "Connect via SDK" on this page: https://developer.couchbase.com/documentation/server/current/install/docker-deploy-multi-node-cluster.html
func writeToBucket(t *testing.T, clusterUrl string, bucketName string, key string, value TestData) {
	logger.Logf(t, "Writing (%s, %s) to bucket %s", key, value, bucketName)

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
	retries := 180
	timeBetweenRetries := 5 * time.Second

	// Buckets take a while to replicate, and until they do, you get vague errors such as "Unexpected server error",
	// so retry a few times.
	out := retry.DoWithRetry(t, description, retries, timeBetweenRetries, func() (string, error) {
		statusCode, body, err := HttpPostForm(t, bucketUrl, postParams)
		if err != nil {
			return "", err
		}

		if statusCode != 200 {
			return "", fmt.Errorf("Expected status code 200 when writing (%s, %s) to bucket %s, but got %d. Repsonse body: %s", key, value, bucketName, statusCode, body)
		}

		return fmt.Sprintf("Successfully wrote (%s, %s) to bucket %s", key, value, bucketName), nil
	})

	logger.Logf(t, out)
}

// Read from a Couchbase bucket. Note that we do NOT use any Couchbase SDK here because this test runs against a
// Dockerized cluster, and the SDK does not work with Dockerized clusters, as it tries to use IPs that are only
// accessible from inside a Docker container. Therefore, we just use the HTTP API directly. For more info, search for
// "Connect via SDK" on this page: https://developer.couchbase.com/documentation/server/current/install/docker-deploy-multi-node-cluster.html
func readFromBucket(t *testing.T, clusterUrl string, bucketName string, key string) TestData {
	description := fmt.Sprintf("Reading key %s from bucket %s", key, bucketName)
	maxRetries := 180
	timeBetweenRetries := 5 * time.Second

	// This is an undocumented API. I found it here: https://stackoverflow.com/a/37425574/483528. You can also find it
	// by using the Couchbase web console and inspecting the requests that it is sending.
	bucketUrl := fmt.Sprintf("%s/pools/default/buckets/%s/docs/%s", clusterUrl, bucketName, key)

	logger.Logf(t, description)
	body := retry.DoWithRetry(t, description, maxRetries, timeBetweenRetries, func() (string, error) {
		statusCode, body, err := http_helper.HttpGetE(t, bucketUrl, nil)

		if err != nil {
			return "", err
		}

		if statusCode != 200 {
			return "", fmt.Errorf("Expected status code 200 when reading key %s from bucket %s, but got %d", key, bucketName, statusCode)
		}

		return body, nil
	})

	// Unmarshal the surrounding data
	var value CouchbaseTestDataResponse
	if err := json.Unmarshal([]byte(body), &value); err != nil {
		t.Fatalf("Failed to parse body '%s' for key %s in bucket %s: %v", body, key, bucketName, err)
	}

	logger.Logf(t, "Got back %v for key %s from bucket %s", value, key, bucketName)

	// The data we wrote comes back as a string, but inside that string is JSON, so now we unmarshal that
	var testData TestData
	if err := json.Unmarshal([]byte(value.Json), &testData); err != nil {
		t.Fatalf("Failed to parse Json param '%s' for key %s in bucket %s: %v", value.Json, key, bucketName, err)
	}

	return testData
}

func checkSyncGatewayWorking(t *testing.T, syncGatewayUrl string) {
	// It can take a LONG time for the Couchbase cluster to rebalance itself, so we may have to wait a while
	maxRetries := 200
	sleepBetweenRetries := 5 * time.Second

	http_helper.HttpGetWithRetryWithCustomValidation(t, syncGatewayUrl, nil, maxRetries, sleepBetweenRetries, func(status int, body string) bool {
		return status == 200 && strings.Contains(body, `"state":"Online"`)
	})
}

func buildCouchbaseAmi(t *testing.T, osName string, couchbaseAmiDir string, edition string, awsRegion string, uniqueId string) string {
	amiId, err := buildCouchbaseAmiE(t, osName, couchbaseAmiDir, edition, awsRegion, uniqueId)
	if err != nil {
		t.Fatal(err)
	}
	return amiId
}

func buildCouchbaseAmiE(t *testing.T, osName string, couchbaseAmiDir string, edition string, awsRegion string, uniqueId string) (string, error) {
	return buildCouchbaseWithPackerE(t, fmt.Sprintf("%s-ami", osName), fmt.Sprintf("couchbase-%s", uniqueId), awsRegion, couchbaseAmiDir, edition)
}

func getClusterName(t *testing.T, clusterVarName string, terraformOptions *terraform.Options) string {
	clusterNameVal, ok := terraformOptions.Vars[clusterVarName]
	if !ok {
		t.Fatalf("Could not find cluster name in TerratestOptions Var %s", clusterVarName)
	}

	return fmt.Sprintf("%v", clusterNameVal)
}

func testStageLogs(t *testing.T, terraformOptions *terraform.Options, clusterVarName string, awsRegion string) {
	clusterName := getClusterName(t, clusterVarName, terraformOptions)

	logs := aws.GetSyslogForInstancesInAsg(t, clusterName, awsRegion)

	logger.Logf(t, "\n\n============== Logs for cluster %s ==============", clusterName)
	for instanceId, syslog := range logs {
		logger.Logf(t, "Most recent 64 KB of logs for instance %s in %s:\n\n%s\n\n", instanceId, awsRegion, syslog)
	}
}

// Format a unique name for the Couchbase cluster. Note that Couchbase DB names must be lower case.
func formatCouchbaseClusterName(baseName string, uniqueId string) string {
	return strings.ToLower(fmt.Sprintf("%s-%s", baseName, uniqueId))
}

func validateSingleClusterWorks(t *testing.T, terraformOptions *terraform.Options, couchbaseClusterVarName string, loadBalancerProtocol string) {
	clusterName := getClusterName(t, couchbaseClusterVarName, terraformOptions)

	couchbaseServerUrl := terraform.OutputRequired(t, terraformOptions, "couchbase_web_console_url")
	couchbaseServerUrl = fmt.Sprintf("%s://%s:%s@%s", loadBalancerProtocol, usernameForTest, passwordForTest, couchbaseServerUrl)
	syncGatewayUrl := fmt.Sprintf("%s://%s/%s", loadBalancerProtocol, terraform.OutputRequired(t, terraformOptions, "sync_gateway_url"), clusterName)

	checkCouchbaseConsoleIsRunning(t, couchbaseServerUrl)
	checkCouchbaseClusterIsInitialized(t, couchbaseServerUrl, 3)
	checkCouchbaseDataNodesWorking(t, couchbaseServerUrl)
	checkSyncGatewayWorking(t, syncGatewayUrl)
}
