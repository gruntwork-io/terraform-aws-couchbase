package test

import (
	"testing"
	"path/filepath"
	"github.com/gruntwork-io/terratest"
	terralog "github.com/gruntwork-io/terratest/log"
	"github.com/gruntwork-io/terratest/files"
	"fmt"
	"github.com/gruntwork-io/terratest/test-structure"
)

func TestCouchbaseSingleClusterUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "TestCouchbaseSingleClusterUbuntu", "ubuntu")
}

func testCouchbaseSingleCluster(t *testing.T, testName string, osName string) {
	logger := terralog.NewLogger(testName)

	tmpRootDir, err := files.CopyTerraformFolderToTemp("../", testName)
	if err != nil {
		t.Fatal(err)
	}
	couchbaseAmiDir := filepath.Join(tmpRootDir, "examples", "couchbase-ami")
	couchbaseSingleClusterDir := filepath.Join(tmpRootDir, "examples", "couchbase-single-cluster")

	test_structure.RunTestStage("setup_ami", logger, func() {
		resourceCollection := createBaseRandomResourceCollection(t)
		amiId := buildCouchbaseWithPacker(t, logger, fmt.Sprintf("%s-ami", osName), resourceCollection.AwsRegion, couchbaseAmiDir)

		test_structure.SaveAmiId(t, couchbaseSingleClusterDir, amiId, logger)
		test_structure.SaveRandomResourceCollection(t, couchbaseSingleClusterDir, resourceCollection, logger)
	})

	test_structure.RunTestStage("setup_deploy", logger, func() {
		resourceCollection := test_structure.LoadRandomResourceCollection(t, couchbaseSingleClusterDir, logger)
		amiId := test_structure.LoadAmiId(t, couchbaseSingleClusterDir, logger)

		terratestOptions := createBaseTerratestOptions(t, testName, couchbaseSingleClusterDir, resourceCollection)
		terratestOptions.Vars = map[string]interface{} {
			"aws_region": resourceCollection.AwsRegion,
			"ami_id": amiId,
			"cluster_name": fmt.Sprintf("single-cluster-%s", resourceCollection.UniqueId),
		}

		deploy(t, terratestOptions)

		test_structure.SaveTerratestOptions(t, couchbaseSingleClusterDir, terratestOptions, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		resourceCollection := test_structure.LoadRandomResourceCollection(t, couchbaseSingleClusterDir, logger)
		terratestOptions := test_structure.LoadTerratestOptions(t, couchbaseSingleClusterDir, logger)

		terratest.Destroy(terratestOptions, resourceCollection)
	})

	test_structure.RunTestStage("validation", logger, func() {
		terratestOptions := test_structure.LoadTerratestOptions(t, couchbaseSingleClusterDir, logger)

		couchbaseServerUrl, err := terratest.OutputRequired(terratestOptions, "couchbase_web_console_url")
		if err != nil {
			t.Fatal(err)
		}
		couchbaseServerUrl = fmt.Sprintf("http://%s:%s@%s", usernameForTest, passwordForTest, couchbaseServerUrl)

		syncGatewayUrl, err := terratest.OutputRequired(terratestOptions, "sync_gateway_url")
		if err != nil {
			t.Fatal(err)
		}
		syncGatewayUrl = fmt.Sprintf("http://%s:%s@%s/%s", usernameForTest, passwordForTest, couchbaseServerUrl, terratestOptions.Vars["cluster_name"])

		checkCouchbaseConsoleIsRunning(t, couchbaseServerUrl, logger)
		checkCouchbaseDataNodesWorking(t, couchbaseServerUrl, logger)
		checkSyncGatewayWorking(t, syncGatewayUrl, logger)
	})
}
