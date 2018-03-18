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
	"gopkg.in/couchbase/gocb.v1"
	"github.com/stretchr/testify/assert"
	"github.com/gruntwork-io/terratest/util"
)

// The port numbers used by docker-compose.yml in the couchbase-ami example
var testWebConsolePorts = map[string]int{
	"ubuntu": 8091,
}

// The username and password we use in all the examples, mocks, and tests
const usernameForTest = "admin"
const passwordForTest = "password"

func TestUnitCouchbaseUbuntuInDocker(t *testing.T) {
	t.Parallel()
	testCouchbaseInDocker(t, "ubuntu")
}

func testCouchbaseInDocker(t *testing.T, osName string) {
	testName := fmt.Sprintf("TestCouchbaseInDocker-%s", osName)
	logger := terralog.NewLogger(testName)

	tmpRootDir, err := files.CopyTerraformFolderToTemp("../", testName)
	if err != nil {
		t.Fatal(err)
	}
	couchbaseExampleDir := filepath.Join(tmpRootDir, "examples", "couchbase-ami")

	test_structure.RunTestStage("setup_image", logger, func() {
		buildCouchbaseWithPacker(t, logger, fmt.Sprintf("%s-docker", osName), "us-east-1", couchbaseExampleDir)
	})

	test_structure.RunTestStage("setup_docker", logger, func() {
		startCouchbaseWithDockerCompose(t, osName, couchbaseExampleDir, logger)
	})

	test_structure.RunTestStage("validation", logger, func() {
		checkCouchbaseConsoleIsRunning(t, osName, logger)
		checkCouchbaseDataNodesWorking(t, osName, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		stopCouchbaseWithDockerCompose(t, couchbaseExampleDir, logger)
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
	url := fmt.Sprintf("http://localhost:%d", testWebConsolePorts[osName])
	maxRetries := 20
	sleepBetweenRetries := 5 * time.Second

	err := http_helper.HttpGetWithRetryWithCustomValidation(url, maxRetries, sleepBetweenRetries, logger, func(status int, body string) bool {
		return status == 200 && strings.Contains(body, "Couchbase Console")
	})

	if err != nil {
		t.Fatalf("Failed to connect to Couchbase at %s: %v", url, err)
	}
}

func checkCouchbaseDataNodesWorking(t *testing.T, osName string, logger *log.Logger) {
	url := fmt.Sprintf("http://localhost:%d", testWebConsolePorts[osName])

	uniqueId := util.UniqueId()
	testBucketName := fmt.Sprintf("test%s", uniqueId)
	testKey := fmt.Sprintf("test-key-%s", uniqueId)
	testValue := TestData{
		Id: testKey,
		Foo: fmt.Sprintf("test-value-%s", uniqueId),
		Bar: 42,
	}

	cluster := connectToCluster(t, url, usernameForTest, logger)
	bucket := createBucket(t, cluster, testBucketName, logger)

	writeToBucket(t, bucket, testKey, testValue, logger)
	actualValue := readFromBucket(t, bucket, testKey, logger)

	assert.Equal(t, testValue, actualValue)
}

func connectToCluster(t *testing.T, url string, clusterUsername string, logger *log.Logger) *gocb.Cluster {
	logger.Printf("Connecting to Couchbase at %s", url)

	cluster, err := gocb.Connect(url)
	if err != nil {
		t.Fatalf("Failed to connect to Couchbase cluster at %s: %v", url, err)
	}

	authenticator := gocb.PasswordAuthenticator{
		Username: clusterUsername,
		Password: passwordForTest,
	}

	if err := cluster.Authenticate(authenticator); err != nil {
		t.Fatalf("Failed to authenticate to Couchbase cluster at %s: %v", url, err)
	}

	return cluster
}

func createBucket(t *testing.T, cluster *gocb.Cluster, bucketName string, logger *log.Logger) *gocb.Bucket {
	logger.Printf("Creating bucket %s", bucketName)

	bucketSettings := gocb.BucketSettings{
		Name: bucketName,
		Type: gocb.Couchbase,
		Quota: 100,
	}

	clusterManager := cluster.Manager(usernameForTest, passwordForTest)
	if err := clusterManager.InsertBucket(&bucketSettings); err != nil {
		t.Fatalf("Failed to create bucket %s: %v", bucketName, err)
	}

	// It takes a little bit of time for Couchbase to create the bucket. If you don't wait and immediately try to open
	// the bucket, you get a confusing authentication error.
	// being invalid.
	logger.Printf("Waiting a few seconds for the bucket to be created")
	time.Sleep(5 * time.Second)

	logger.Printf("Opening bucket %s", bucketName)

	bucket, err := cluster.OpenBucket(bucketName, passwordForTest)
	if err != nil {
		t.Fatalf("Failed to open bucket %s: %v", bucketName, err)
	}

	return bucket
}

type TestData struct {
	Id string `json:"uid"`
	Foo string `json:"foo"`
	Bar int `json:"bar"`
}

func writeToBucket(t *testing.T, bucket *gocb.Bucket, key string, value TestData, logger *log.Logger) {
	logger.Printf("Writing (%s, %s) to bucket %s", key, value, bucket.Name())

	if _, err := bucket.Insert(key, value, 0); err != nil {
		t.Fatalf("Failed to insert (%s, %s) into bucket %s: %v", key, value, bucket.Name(), err)
	}
}

func readFromBucket(t *testing.T, bucket *gocb.Bucket, key string, logger *log.Logger) TestData {
	logger.Printf("Reading key %s from bucket %s", key, bucket.Name())

	var value TestData
	if _, err := bucket.Get(key, &value); err != nil {
		t.Fatalf("Failed to retrieve key %s from bucket %s: %v", key, bucket.Name(), err)
	}

	return value
}