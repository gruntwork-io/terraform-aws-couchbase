package test

import (
	"fmt"
	"path/filepath"
	"sync"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

const clusterNamePrimaryVarName = "cluster_name_primary"
const clusterNameReplicaVarName = "cluster_name_replica"

const savedAmiIdPrimary = "AmiPrimary"
const savedAmiIdReplica = "AmiReplica"

const savedAwsRegionPrimary = "AwsRegionPrimary"
const savedUniqueIdPrimary = "UniqueIdPrimary"

const savedAwsRegionReplica = "AwsRegionReplica"
const savedUniqueIdReplica = "UniqueIdReplica"

const providersFile = "providers.tf"
const providersFileBackup = "providers.tf.bak"

func TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationUbuntu20(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiDataCenterReplication(t, "ubuntu-20", "enterprise")
}

func TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationUbuntu18(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiDataCenterReplication(t, "ubuntu-18", "enterprise")
}

func TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiDataCenterReplication(t, "amazon-linux", "enterprise")
}

func testCouchbaseMultiDataCenterReplication(t *testing.T, osName string, edition string) {
	// For convenience - uncomment these as well as the "os" import
	// when doing local testing if you need to skip any sections.
	//os.Setenv("TERRATEST_REGION", "eu-west-1")
	//os.Setenv("SKIP_setup_ami", "true")
	//os.Setenv("SKIP_setup_deploy", "true")
	//os.Setenv("SKIP_validation", "true")
	//os.Setenv("SKIP_teardown", "true")
	//os.Setenv("SKIP_logs", "true")

	examplesFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples")
	couchbaseAmiDir := filepath.Join(examplesFolder, "couchbase-ami")
	couchbaseMultiClusterDir := filepath.Join(examplesFolder, "couchbase-multi-datacenter-replication")

	test_structure.RunTestStage(t, "setup_ami", func() {
		awsRegionPrimary := getRandomAwsRegion(t)
		uniqueIdPrimary := random.UniqueId()

		awsRegionReplica := getRandomAwsRegion(t)
		uniqueIdReplica := random.UniqueId()

		var waitForPackerBuilds sync.WaitGroup
		waitForPackerBuilds.Add(2)

		var amiIdPrimary string
		var amiErrPrimary error

		var amiIdReplica string
		var amiErrReplica error

		go func() {
			defer waitForPackerBuilds.Done()

			amiIdPrimary, amiErrPrimary = buildCouchbaseAmiE(t, osName, couchbaseAmiDir, edition, awsRegionPrimary, uniqueIdPrimary)
		}()

		go func() {
			defer waitForPackerBuilds.Done()
			amiIdReplica, amiErrReplica = buildCouchbaseAmiE(t, osName, couchbaseAmiDir, edition, awsRegionReplica, uniqueIdReplica)
		}()

		waitForPackerBuilds.Wait()

		// We cannot call t.Fatal in the goroutines above, as t.Fatal only works in the original goroutine for the
		// test. Therefore, we instead check for errors explicitly here.
		if amiErrPrimary != nil {
			t.Fatal(amiErrPrimary)
		}
		if amiErrReplica != nil {
			t.Fatal(amiErrReplica)
		}

		test_structure.SaveString(t, couchbaseMultiClusterDir, savedAmiIdPrimary, amiIdPrimary)
		test_structure.SaveString(t, couchbaseMultiClusterDir, savedAmiIdReplica, amiIdReplica)

		test_structure.SaveString(t, couchbaseMultiClusterDir, savedAwsRegionPrimary, awsRegionPrimary)
		test_structure.SaveString(t, couchbaseMultiClusterDir, savedAwsRegionReplica, awsRegionReplica)

		test_structure.SaveString(t, couchbaseMultiClusterDir, savedUniqueIdPrimary, uniqueIdPrimary)
		test_structure.SaveString(t, couchbaseMultiClusterDir, savedUniqueIdReplica, uniqueIdReplica)
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, couchbaseMultiClusterDir)
		terraform.Destroy(t, terraformOptions)

		amiIdPrimary := test_structure.LoadString(t, couchbaseMultiClusterDir, savedAmiIdPrimary)
		amiIdReplica := test_structure.LoadString(t, couchbaseMultiClusterDir, savedAmiIdReplica)

		awsRegionPrimary := test_structure.LoadString(t, couchbaseMultiClusterDir, savedAwsRegionPrimary)
		awsRegionReplica := test_structure.LoadString(t, couchbaseMultiClusterDir, savedAwsRegionReplica)

		aws.DeleteAmi(t, awsRegionPrimary, amiIdPrimary)
		aws.DeleteAmi(t, awsRegionReplica, amiIdReplica)
	})

	defer test_structure.RunTestStage(t, "logs", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, couchbaseMultiClusterDir)
		awsRegionPrimary := test_structure.LoadString(t, couchbaseMultiClusterDir, savedAwsRegionPrimary)
		awsRegionReplica := test_structure.LoadString(t, couchbaseMultiClusterDir, savedAwsRegionReplica)

		testStageLogs(t, terraformOptions, clusterNamePrimaryVarName, awsRegionPrimary)
		testStageLogs(t, terraformOptions, clusterNameReplicaVarName, awsRegionReplica)
	})

	test_structure.RunTestStage(t, "setup_deploy", func() {
		amiIdPrimary := test_structure.LoadString(t, couchbaseMultiClusterDir, savedAmiIdPrimary)
		amiIdReplica := test_structure.LoadString(t, couchbaseMultiClusterDir, savedAmiIdReplica)

		awsRegionPrimary := test_structure.LoadString(t, couchbaseMultiClusterDir, savedAwsRegionPrimary)
		awsRegionReplica := test_structure.LoadString(t, couchbaseMultiClusterDir, savedAwsRegionReplica)

		uniqueIdPrimary := test_structure.LoadString(t, couchbaseMultiClusterDir, savedUniqueIdPrimary)
		uniqueIdReplica := test_structure.LoadString(t, couchbaseMultiClusterDir, savedUniqueIdReplica)

		terraformOptions := &terraform.Options{
			TerraformDir: couchbaseMultiClusterDir,
			Vars: map[string]interface{}{
				"primary_region":          awsRegionPrimary,
				"replica_region":          awsRegionReplica,
				"ami_id_primary":          amiIdPrimary,
				"ami_id_replica":          amiIdReplica,
				clusterNamePrimaryVarName: formatCouchbaseClusterName("primary", uniqueIdPrimary),
				clusterNameReplicaVarName: formatCouchbaseClusterName("replica", uniqueIdReplica),
			},
		}

		terraform.InitAndApply(t, terraformOptions)

		test_structure.SaveTerraformOptions(t, couchbaseMultiClusterDir, terraformOptions)
	})

	test_structure.RunTestStage(t, "validation", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, couchbaseMultiClusterDir)

		consoleUrlPrimary := fmt.Sprintf("http://%s:%s@%s", usernameForTest, passwordForTest, terraform.OutputRequired(t, terraformOptions, "couchbase_primary_web_console_url"))
		consoleUrlReplica := fmt.Sprintf("http://%s:%s@%s", usernameForTest, passwordForTest, terraform.OutputRequired(t, terraformOptions, "couchbase_replica_web_console_url"))

		checkCouchbaseConsoleIsRunning(t, consoleUrlPrimary)
		checkCouchbaseConsoleIsRunning(t, consoleUrlReplica)

		checkCouchbaseClusterIsInitialized(t, consoleUrlPrimary, 3)
		checkCouchbaseClusterIsInitialized(t, consoleUrlReplica, 3)

		checkReplicationIsWorking(t, consoleUrlPrimary, consoleUrlReplica, "test-bucket", "test-bucket-replica")
	})
}
