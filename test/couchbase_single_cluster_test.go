package test

import (
	"testing"
	"path/filepath"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/aws"
)

const couchbaseClusterVarName = "cluster_name"

func TestIntegrationCouchbaseCommunitySingleClusterUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "ubuntu", "community")
}

func TestIntegrationCouchbaseCommunitySingleClusterAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "amazon-linux", "community")
}

func TestIntegrationCouchbaseEnterpriseSingleClusterUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "ubuntu", "enterprise")
}

func TestIntegrationCouchbaseEnterpriseSingleClusterAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "amazon-linux", "enterprise")
}

func testCouchbaseSingleCluster(t *testing.T, osName string, edition string) {
	examplesFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples")
	couchbaseAmiDir := filepath.Join(examplesFolder, "couchbase-ami")
	couchbaseSingleClusterDir := filepath.Join(examplesFolder, "couchbase-cluster-simple")

	test_structure.RunTestStage(t, "setup_ami", func() {
		awsRegion := getRandomAwsRegion(t)
		uniqueId := random.UniqueId()

		amiId := buildCouchbaseAmi(t, osName, couchbaseAmiDir, edition, awsRegion, uniqueId)

		test_structure.SaveAmiId(t, couchbaseSingleClusterDir, amiId)
		test_structure.SaveString(t, couchbaseSingleClusterDir, savedAwsRegion, awsRegion)
		test_structure.SaveString(t, couchbaseSingleClusterDir, savedUniqueId, uniqueId)
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, couchbaseSingleClusterDir)
		terraform.Destroy(t, terraformOptions)

		amiId := test_structure.LoadAmiId(t, couchbaseSingleClusterDir)
		awsRegion := test_structure.LoadString(t, couchbaseSingleClusterDir, savedAwsRegion)
		aws.DeleteAmi(t, awsRegion, amiId)
	})

	defer test_structure.RunTestStage(t, "logs", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, couchbaseSingleClusterDir)
		awsRegion := test_structure.LoadString(t, couchbaseSingleClusterDir, savedAwsRegion)
		testStageLogs(t, terraformOptions, couchbaseClusterVarName, awsRegion)
	})

	test_structure.RunTestStage(t, "setup_deploy", func() {
		amiId := test_structure.LoadAmiId(t, couchbaseSingleClusterDir)
		awsRegion := test_structure.LoadString(t, couchbaseSingleClusterDir, savedAwsRegion)
		uniqueId := test_structure.LoadString(t, couchbaseSingleClusterDir, savedUniqueId)

		terraformOptions := &terraform.Options{
			TerraformDir: couchbaseSingleClusterDir,
			Vars: map[string]interface{}{
				"ami_id":                amiId,
				couchbaseClusterVarName: formatCouchbaseClusterName("single-cluster", uniqueId),
			},
			EnvVars: map[string]string{
				AWS_DEFAULT_REGION_ENV_VAR: awsRegion,
			},
		}

		terraform.InitAndApply(t, terraformOptions)

		test_structure.SaveTerraformOptions(t, couchbaseSingleClusterDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "validation", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, couchbaseSingleClusterDir)
		validateSingleClusterWorks(t, terraformOptions, couchbaseClusterVarName, "http")
	})
}
