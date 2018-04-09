package test

import (
	"testing"
	"path/filepath"
	terralog "github.com/gruntwork-io/terratest/log"
	"github.com/gruntwork-io/terratest/test-structure"
)

const couchbaseClusterVarName = "cluster_name"

func TestIntegrationCouchbaseCommunitySingleClusterUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "TestIntegrationCouchbaseCommunitySingleClusterUbuntu", "ubuntu", "community")
}

func TestIntegrationCouchbaseCommunitySingleClusterAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "TestIntegrationCouchbaseCommunitySingleClusterAmazonLinux", "amazon-linux", "community")
}

func TestIntegrationCouchbaseEnterpriseSingleClusterUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "TestIntegrationCouchbaseEnterpriseSingleClusterUbuntu", "ubuntu", "enterprise")
}

func TestIntegrationCouchbaseEnterpriseSingleClusterAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "TestIntegrationCouchbaseEnterpriseSingleClusterAmazonLinux", "amazon-linux", "enterprise")
}

func testCouchbaseSingleCluster(t *testing.T, testName string, osName string, edition string) {
	logger := terralog.NewLogger(testName)

	examplesFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples", testName, logger)
	couchbaseAmiDir := filepath.Join(examplesFolder, "couchbase-ami")
	couchbaseSingleClusterDir := filepath.Join(examplesFolder, "couchbase-single-cluster")

	test_structure.RunTestStage("setup_ami", logger, func() {
		testStageBuildCouchbaseAmi(t, osName, edition, couchbaseAmiDir, couchbaseSingleClusterDir, logger)
	})

	test_structure.RunTestStage("setup_deploy", logger, func() {
		resourceCollection := test_structure.LoadRandomResourceCollection(t, couchbaseSingleClusterDir, logger)
		amiId := test_structure.LoadAmiId(t, couchbaseSingleClusterDir, logger)

		terratestOptions := createBaseTerratestOptions(t, testName, couchbaseSingleClusterDir, resourceCollection)
		terratestOptions.Vars = map[string]interface{} {
			"aws_region":            resourceCollection.AwsRegion,
			"ami_id":                amiId,
			couchbaseClusterVarName: formatCouchbaseClusterName("single-cluster", resourceCollection),
		}

		deploy(t, terratestOptions)

		test_structure.SaveTerratestOptions(t, couchbaseSingleClusterDir, terratestOptions, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		testStageTeardown(t, couchbaseSingleClusterDir, logger)
	})

	defer test_structure.RunTestStage("logs", logger, func() {
		resourceCollection := test_structure.LoadRandomResourceCollection(t, couchbaseSingleClusterDir, logger)
		testStageLogs(t, couchbaseSingleClusterDir, couchbaseClusterVarName, resourceCollection, logger)
	})

	test_structure.RunTestStage("validation", logger, func() {
		validateSingleClusterWorks(t, couchbaseSingleClusterDir, couchbaseClusterVarName, "http", logger)
	})
}
