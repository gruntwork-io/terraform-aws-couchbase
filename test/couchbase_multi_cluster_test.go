package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/test-structure"
	"github.com/gruntwork-io/terratest"
	"path/filepath"
	"fmt"
	terralog "github.com/gruntwork-io/terratest/log"
)

const dataNodeClusterVarName = "couchbase_data_node_cluster_name"
const indexQuerySearchClusterVarName = "couchbase_index_query_search_node_cluster_name"
const syncGatewayClusterVarName = "sync_gateway_cluster_name"

func TestIntegrationCouchbaseMultiClusterUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiCluster(t, "TestIntegrationCouchbaseMultiClusterUbuntu", "ubuntu")
}

func TestIntegrationCouchbaseMultiClusterAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiCluster(t, "TestIntegrationCouchbaseMultiClusterAmazonLinux", "amazon-linux")
}

func testCouchbaseMultiCluster(t *testing.T, testName string, osName string) {
	logger := terralog.NewLogger(testName)

	examplesFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples", testName, logger)
	couchbaseAmiDir := filepath.Join(examplesFolder, "couchbase-ami")
	couchbaseMultiClusterDir := filepath.Join(examplesFolder, "couchbase-multi-cluster")

	test_structure.RunTestStage("setup_ami", logger, func() {
		testStageBuildCouchbaseAmi(t, osName, couchbaseAmiDir, couchbaseMultiClusterDir, logger)
	})

	test_structure.RunTestStage("setup_deploy", logger, func() {
		resourceCollection := test_structure.LoadRandomResourceCollection(t, couchbaseMultiClusterDir, logger)
		amiId := test_structure.LoadAmiId(t, couchbaseMultiClusterDir, logger)

		terratestOptions := createBaseTerratestOptions(t, testName, couchbaseMultiClusterDir, resourceCollection)
		terratestOptions.Vars = map[string]interface{} {
			"aws_region":                   resourceCollection.AwsRegion,
			"ami_id":                       amiId,
			dataNodeClusterVarName:         formatCouchbaseClusterName("data", resourceCollection),
			indexQuerySearchClusterVarName: formatCouchbaseClusterName("search", resourceCollection),
			syncGatewayClusterVarName: 		formatCouchbaseClusterName("sync", resourceCollection),
		}

		deploy(t, terratestOptions)

		test_structure.SaveTerratestOptions(t, couchbaseMultiClusterDir, terratestOptions, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		testStageTeardown(t, couchbaseMultiClusterDir, logger)
	})

	defer test_structure.RunTestStage("logs", logger, func() {
		testStageLogs(t, couchbaseMultiClusterDir, dataNodeClusterVarName, logger)
		testStageLogs(t, couchbaseMultiClusterDir, indexQuerySearchClusterVarName, logger)
		testStageLogs(t, couchbaseMultiClusterDir, syncGatewayClusterVarName, logger)
	})

	test_structure.RunTestStage("validation", logger, func() {
		terratestOptions := test_structure.LoadTerratestOptions(t, couchbaseMultiClusterDir, logger)
		clusterName := getClusterName(t, dataNodeClusterVarName, terratestOptions)

		couchbaseDataNodesUrl, err := terratest.OutputRequired(terratestOptions, "couchbase_data_nodes_web_console_url")
		if err != nil {
			t.Fatal(err)
		}
		couchbaseDataNodesUrl = fmt.Sprintf("http://%s:%s@%s", usernameForTest, passwordForTest, couchbaseDataNodesUrl)

		couchbaseIndexSearchQueryNodesUrl, err := terratest.OutputRequired(terratestOptions, "couchbase_index_query_search_nodes_web_console_url")
		if err != nil {
			t.Fatal(err)
		}
		couchbaseIndexSearchQueryNodesUrl = fmt.Sprintf("http://%s:%s@%s", usernameForTest, passwordForTest, couchbaseIndexSearchQueryNodesUrl)

		syncGatewayUrl, err := terratest.OutputRequired(terratestOptions, "sync_gateway_url")
		if err != nil {
			t.Fatal(err)
		}
		syncGatewayUrl = fmt.Sprintf("http://%s/%s", syncGatewayUrl, clusterName)

		checkCouchbaseConsoleIsRunning(t, couchbaseDataNodesUrl, logger)
		checkCouchbaseClusterIsInitialized(t, couchbaseDataNodesUrl, 5, logger)
		checkCouchbaseDataNodesWorking(t, couchbaseDataNodesUrl, logger)
		checkCouchbaseConsoleIsRunning(t, couchbaseIndexSearchQueryNodesUrl, logger)
		checkSyncGatewayWorking(t, syncGatewayUrl, logger)
	})
}

