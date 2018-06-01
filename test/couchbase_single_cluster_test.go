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
	rootFolder := test_structure.CopyTerraformFolderToTemp(t, "../", ".")
	couchbaseAmiDir := filepath.Join(rootFolder, "examples", "couchbase-ami")

	test_structure.RunTestStage(t, "setup_ami", func() {
		awsRegion := getRandomAwsRegion(t)
		uniqueId := random.UniqueId()

		amiId := buildCouchbaseAmi(t, osName, couchbaseAmiDir, edition, awsRegion, uniqueId)

		test_structure.SaveAmiId(t, rootFolder, amiId)
		test_structure.SaveString(t, rootFolder, savedAwsRegion, awsRegion)
		test_structure.SaveString(t, rootFolder, savedUniqueId, uniqueId)
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, rootFolder)
		terraform.Destroy(t, terraformOptions)

		amiId := test_structure.LoadAmiId(t, rootFolder)
		awsRegion := test_structure.LoadString(t, rootFolder, savedAwsRegion)
		aws.DeleteAmi(t, awsRegion, amiId)
	})

	defer test_structure.RunTestStage(t, "logs", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, rootFolder)
		awsRegion := test_structure.LoadString(t, rootFolder, savedAwsRegion)
		testStageLogs(t, terraformOptions, couchbaseClusterVarName, awsRegion)
	})

	test_structure.RunTestStage(t, "setup_deploy", func() {
		amiId := test_structure.LoadAmiId(t, rootFolder)
		awsRegion := test_structure.LoadString(t, rootFolder, savedAwsRegion)
		uniqueId := test_structure.LoadString(t, rootFolder, savedUniqueId)

		terraformOptions := &terraform.Options{
			TerraformDir: rootFolder,
			Vars: map[string]interface{}{
				"ami_id":                amiId,
				couchbaseClusterVarName: formatCouchbaseClusterName("single-cluster", uniqueId),
			},
			EnvVars: map[string]string{
				AWS_DEFAULT_REGION_ENV_VAR: awsRegion,
			},
		}

		terraform.InitAndApply(t, terraformOptions)

		test_structure.SaveTerraformOptions(t, rootFolder, terraformOptions)
	})

	test_structure.RunTestStage(t, "validation", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, rootFolder)
		validateSingleClusterWorks(t, terraformOptions, couchbaseClusterVarName, "http")
	})
}
