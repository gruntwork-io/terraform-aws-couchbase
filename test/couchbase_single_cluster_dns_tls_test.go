package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/test-structure"
	"path/filepath"
	terralog "github.com/gruntwork-io/terratest/log"
)

// This domain name is registered in the Gruntwork Phx DevOps account. It also has ACM certs in all regions.
const domainNameForTest = "gruntwork.in"

func TestIntegrationCouchbaseCommunitySingleClusterDnsTlsUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleClusterDnsTls(t, "TestIntegrationCouchbaseCommunitySingleClusterDnsTlsUbuntu", "ubuntu", "community")
}

func testCouchbaseSingleClusterDnsTls(t *testing.T, testName string, osName string, edition string) {
	logger := terralog.NewLogger(testName)

	examplesFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples", testName, logger)
	couchbaseAmiDir := filepath.Join(examplesFolder, "couchbase-ami")
	couchbaseSingleClusterDnsTlsDir := filepath.Join(examplesFolder, "couchbase-single-cluster-dns-tls")

	test_structure.RunTestStage("setup_ami", logger, func() {
		testStageBuildCouchbaseAmi(t, osName, edition, couchbaseAmiDir, couchbaseSingleClusterDnsTlsDir, logger)
	})

	test_structure.RunTestStage("setup_deploy", logger, func() {
		resourceCollection := test_structure.LoadRandomResourceCollection(t, couchbaseSingleClusterDnsTlsDir, logger)
		amiId := test_structure.LoadAmiId(t, couchbaseSingleClusterDnsTlsDir, logger)

		terratestOptions := createBaseTerratestOptions(t, testName, couchbaseSingleClusterDnsTlsDir, resourceCollection)
		terratestOptions.Vars = map[string]interface{} {
			"aws_region":            resourceCollection.AwsRegion,
			"ami_id":                amiId,
			"domain_name":           domainNameForTest,
			couchbaseClusterVarName: formatCouchbaseClusterName("single-cluster", resourceCollection),
		}

		deploy(t, terratestOptions)

		test_structure.SaveTerratestOptions(t, couchbaseSingleClusterDnsTlsDir, terratestOptions, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		testStageTeardown(t, couchbaseSingleClusterDnsTlsDir, logger)
	})

	defer test_structure.RunTestStage("logs", logger, func() {
		resourceCollection := test_structure.LoadRandomResourceCollection(t, couchbaseSingleClusterDnsTlsDir, logger)
		testStageLogs(t, couchbaseSingleClusterDnsTlsDir, couchbaseClusterVarName, resourceCollection, logger)
	})

	test_structure.RunTestStage("validation", logger, func() {
		validateSingleClusterWorks(t, couchbaseSingleClusterDnsTlsDir, couchbaseClusterVarName, "https", logger)
	})
}
