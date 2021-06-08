package test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

const couchbaseClusterVarName = "cluster_name"

func TestIntegrationCouchbaseCommunitySingleClusterUbuntu20(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "ubuntu-20", "community")
}

func TestIntegrationCouchbaseCommunitySingleClusterUbuntu18(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "ubuntu-18", "community")
}

func TestIntegrationCouchbaseCommunitySingleClusterAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "amazon-linux", "community")
}

func TestIntegrationCouchbaseEnterpriseSingleClusterUbuntu20(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "ubuntu-20", "enterprise")
}

func TestIntegrationCouchbaseEnterpriseSingleClusterUbuntu18(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "ubuntu-18", "enterprise")
}

func TestIntegrationCouchbaseEnterpriseSingleClusterAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "amazon-linux", "enterprise")
}

func testCouchbaseSingleCluster(t *testing.T, osName string, edition string) {
	// For convenience - uncomment these as well as the "os" import
	// when doing local testing if you need to skip any sections.
	//os.Setenv("TERRATEST_REGION", "eu-west-1")
	//os.Setenv("SKIP_setup_ami", "true")
	//os.Setenv("SKIP_setup_deploy", "true")
	//os.Setenv("SKIP_validation", "true")
	//os.Setenv("SKIP_teardown", "true")
	//os.Setenv("SKIP_logs", "true")

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
