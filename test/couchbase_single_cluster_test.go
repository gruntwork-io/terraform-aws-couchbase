package test

import (
	"testing"
	"path/filepath"
	"github.com/gruntwork-io/terratest"
	terralog "github.com/gruntwork-io/terratest/log"
	"fmt"
	"github.com/gruntwork-io/terratest/test-structure"
)

const couchbaseClusterVarName = "cluster_name"

func TestCouchbaseSingleClusterUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "TestCouchbaseSingleClusterUbuntu", "ubuntu")
}

func testCouchbaseSingleCluster(t *testing.T, testName string, osName string) {
	logger := terralog.NewLogger(testName)

	examplesFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples", testName, logger)
	couchbaseAmiDir := filepath.Join(examplesFolder, "couchbase-ami")
	couchbaseSingleClusterDir := filepath.Join(examplesFolder, "couchbase-single-cluster")

	test_structure.RunTestStage("setup_ami", logger, func() {
		testStageBuildCouchbaseAmi(t, osName, couchbaseAmiDir, couchbaseSingleClusterDir, logger)
		
	})

	test_structure.RunTestStage("setup_deploy", logger, func() {
		resourceCollection := test_structure.LoadRandomResourceCollection(t, couchbaseSingleClusterDir, logger)
		amiId := test_structure.LoadAmiId(t, couchbaseSingleClusterDir, logger)

		terratestOptions := createBaseTerratestOptions(t, testName, couchbaseSingleClusterDir, resourceCollection)
		terratestOptions.Vars = map[string]interface{} {
			"aws_region":            resourceCollection.AwsRegion,
			"ami_id":                amiId,
			couchbaseClusterVarName: fmt.Sprintf("single-cluster-%s", resourceCollection.UniqueId),
		}

		deploy(t, terratestOptions)

		test_structure.SaveTerratestOptions(t, couchbaseSingleClusterDir, terratestOptions, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		testStageTeardown(t, couchbaseSingleClusterDir, logger)
	})

	defer test_structure.RunTestStage("logs", logger, func() {
		testStageLogs(t, couchbaseSingleClusterDir, couchbaseClusterVarName, logger)
	})

	test_structure.RunTestStage("validation", logger, func() {
		terratestOptions := test_structure.LoadTerratestOptions(t, couchbaseSingleClusterDir, logger)
		clusterName := getClusterName(t, couchbaseClusterVarName, terratestOptions)

		couchbaseServerUrl, err := terratest.OutputRequired(terratestOptions, "couchbase_web_console_url")
		if err != nil {
			t.Fatal(err)
		}
		couchbaseServerUrl = fmt.Sprintf("http://%s:%s@%s", usernameForTest, passwordForTest, couchbaseServerUrl)

		syncGatewayUrl, err := terratest.OutputRequired(terratestOptions, "sync_gateway_url")
		if err != nil {
			t.Fatal(err)
		}
		syncGatewayUrl = fmt.Sprintf("http://%s/%s", syncGatewayUrl, clusterName)

		checkCouchbaseConsoleIsRunning(t, couchbaseServerUrl, logger)
		checkCouchbaseClusterIsInitialized(t, couchbaseServerUrl, 3, logger)
		checkCouchbaseDataNodesWorking(t, couchbaseServerUrl, logger)
		checkSyncGatewayWorking(t, syncGatewayUrl, logger)
	})
}
