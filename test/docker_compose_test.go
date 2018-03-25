package test

import (
	"testing"
	"fmt"
	"path/filepath"
	"github.com/gruntwork-io/terratest/test-structure"
	"time"
	terralog "github.com/gruntwork-io/terratest/log"
	"github.com/gruntwork-io/terratest/files"
	"log"
	"github.com/gruntwork-io/terratest/packer"
	"github.com/gruntwork-io/terratest/shell"
	"github.com/gruntwork-io/terratest/http"
	"strings"
	"github.com/stretchr/testify/assert"
	"github.com/gruntwork-io/terratest/util"
	"net/http"
	"io/ioutil"
	"net/url"
	"encoding/json"
)

// The port numbers used by docker-compose.yml in the couchbase-ami example
var testWebConsolePorts = map[string]int{
	"ubuntu": 8091,
}
var testSyncGatewayPorts = map[string]int{
	"ubuntu": 4984,
}

// The username and password we use in all the examples, mocks, and tests
const usernameForTest = "admin"
const passwordForTest = "password"

func TestUnitCouchbaseSingleClusterUbuntuInDocker(t *testing.T) {
	t.Parallel()
	testCouchbaseInDocker(t, "TestUnitCouchbaseSingleClusterUbuntuInDocker","ubuntu")
}

func testCouchbaseInDocker(t *testing.T, testName string, osName string) {
	logger := terralog.NewLogger(testName)

	tmpRootDir, err := files.CopyTerraformFolderToTemp("../", testName)
	if err != nil {
		t.Fatal(err)
	}
	couchbaseAmiDir := filepath.Join(tmpRootDir, "examples", "couchbase-ami")
	couchbaseSingleClusterDockerDir := filepath.Join(tmpRootDir, "examples", "couchbase-single-cluster", "local-test")

	test_structure.RunTestStage("setup_image", logger, func() {
		buildCouchbaseWithPacker(t, logger, fmt.Sprintf("%s-docker", osName), "us-east-1", couchbaseAmiDir)
	})

	test_structure.RunTestStage("setup_docker", logger, func() {
		startCouchbaseWithDockerCompose(t, osName, couchbaseSingleClusterDockerDir, logger)
	})

	test_structure.RunTestStage("validation", logger, func() {
		checkCouchbaseConsoleIsRunning(t, osName, logger)
		checkCouchbaseDataNodesWorking(t, osName, logger)
		checkSyncGatewayWorking(t, osName, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		getDockerComposeLogs(t, couchbaseSingleClusterDockerDir, logger)
		stopCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, logger)
	})
}

func buildCouchbaseWithPacker(t *testing.T, logger *log.Logger, builderName string, awsRegion string, folderPath string) string {
	templatePath := fmt.Sprintf("%s/couchbase.json", folderPath)

	options := packer.PackerOptions{
		Template: templatePath,
		Only: builderName,
		Vars: map[string]string{
			"aws_region": awsRegion,
		},
	}

	artifactId, err := packer.BuildAmi(options, logger)
	if err != nil {
		t.Fatalf("Failed to build Packer template %s: %v", templatePath, err)
	}

	return artifactId
}

func startCouchbaseWithDockerCompose(t *testing.T, os string, exampleDir string, logger *log.Logger) {
	cmd := shell.Command{
		Command:    "docker-compose",
		Args:       []string{"up", "-d"},
		WorkingDir: exampleDir,
	}

	if err := shell.RunCommand(cmd, logger); err != nil {
		t.Fatalf("Failed to start Couchbase using Docker Compose: %v", err)
	}
}

func getDockerComposeLogs(t *testing.T, exampleDir string, logger *log.Logger) {
	cmd := shell.Command{
		Command:    "docker-compose",
		Args:       []string{"logs"},
		WorkingDir: exampleDir,
	}

	if err := shell.RunCommand(cmd, logger); err != nil {
		t.Fatalf("Failed to get Docker Compose logs: %v", err)
	}
}

func stopCouchbaseWithDockerCompose(t *testing.T, exampleDir string, logger *log.Logger) {
	cmd := shell.Command{
		Command:    "docker-compose",
		Args:       []string{"down"},
		WorkingDir: exampleDir,
	}

	if err := shell.RunCommand(cmd, logger); err != nil {
		t.Fatalf("Failed to stop Couchbase using Docker Compose: %v", err)
	}
}

func checkCouchbaseConsoleIsRunning(t *testing.T, osName string, logger *log.Logger) {
	clusterUrl := fmt.Sprintf("http://localhost:%d", testWebConsolePorts[osName])
	maxRetries := 20
	sleepBetweenRetries := 5 * time.Second

	err := http_helper.HttpGetWithRetryWithCustomValidation(clusterUrl, maxRetries, sleepBetweenRetries, logger, func(status int, body string) bool {
		return status == 200 && strings.Contains(body, "Couchbase Console")
	})

	if err != nil {
		t.Fatalf("Failed to connect to Couchbase at %s: %v", clusterUrl, err)
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

func checkCouchbaseDataNodesWorking(t *testing.T, osName string, logger *log.Logger) {
	clusterUrl := fmt.Sprintf("http://%s:%s@localhost:%d", usernameForTest, passwordForTest, testWebConsolePorts[osName])

	uniqueId := util.UniqueId()
	testBucketName := fmt.Sprintf("test%s", uniqueId)
	testKey := fmt.Sprintf("test-key-%s", uniqueId)
	testValue := TestData{
		Foo: fmt.Sprintf("test-value-%s", uniqueId),
		Bar: 42,
	}

	createBucket(t, clusterUrl, testBucketName, logger)
	writeToBucket(t, clusterUrl, testBucketName, testKey, testValue, logger)

	actualValue := readFromBucket(t, clusterUrl, testBucketName, testKey, logger)
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
			return "", fmt.Errorf("Expected status code 200 when writing (%s, %s) to bucket %s, but got %d. Repsonse body: %s", key, value, bucketName, body)
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
	logger.Printf("Reading key %s from bucket %s", key, bucketName)

	// This is an undocumented API. I found it here: https://stackoverflow.com/a/37425574/483528. You can also find it
	// by using the Couchbase web console and inspecting the requests that it is sending.
	bucketUrl := fmt.Sprintf("%s/pools/default/buckets/%s/docs/%s", clusterUrl, bucketName, key)
	statusCode, body, err := http_helper.HttpGet(bucketUrl, logger)

	if err != nil {
		t.Fatalf("Failed to read key %s from bucket %s: %v", key, bucketName, err)
	}

	if statusCode != 200 {
		t.Fatalf("Expected status code 200 when reading key %s from bucket %s, but got %d", key, bucketName, statusCode)
	}

	var value CouchbaseTestDataResponse
	if err := json.Unmarshal([]byte(body), &value); err != nil {
		t.Fatalf("Failed to parse body '%s' for key %s in bucket %s: %v", body, key, bucketName, err)
	}

	logger.Printf("Got back %v for key %s from bucket %s", value, key, bucketName)

	return value.Json
}

func HttpPostForm(t *testing.T, postUrl string, postParams url.Values, logger *log.Logger) (int, string, error) {
	logger.Println("Making an HTTP POST call to URL %s with body %v", postUrl, postParams)

	client := http.Client{
		// By default, Go does not impose a timeout, so an HTTP connection attempt can hang for a LONG time.
		Timeout: 10 * time.Second,
	}

	resp, err := client.PostForm(postUrl, postParams)
	if err != nil {
		return -1, "", err
	}

	defer resp.Body.Close()
	respBody, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		return -1, "", err
	}

	return resp.StatusCode, strings.TrimSpace(string(respBody)), nil
}

func checkSyncGatewayWorking(t *testing.T, osName string, logger *log.Logger) {
	clusterUrl := fmt.Sprintf("http://localhost:%d/mock-couchbase-asg", testSyncGatewayPorts[osName])
	maxRetries := 20
	sleepBetweenRetries := 5 * time.Second

	err := http_helper.HttpGetWithRetryWithCustomValidation(clusterUrl, maxRetries, sleepBetweenRetries, logger, func(status int, body string) bool {
		return status == 200 && strings.Contains(body, `"state":"Online"`)
	})

	if err != nil {
		t.Fatalf("Unable to connect to Sync Gateway at %s: %v", clusterUrl, err)
	}
}