package test

import (
	"testing"
	"path/filepath"
	"fmt"
	"sync"
	"github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/aws"
)

const clusterNamePrimaryVarName = "cluster_name_primary"
const clusterNameReplicaVarName = "cluster_name_replica"

const savedAmiIdPrimary = "AmiPrimary"
const savedAmiIdReplica = "AmiReplica"

const savedAwsRegionPrimary = "AwsRegionPrimary"
const savedUniqueIdPrimary = "UniqueIdPrimary"

const savedAwsRegionReplica = "AwsRegionReplica"
const savedUniqueIdReplica = "UniqueIdReplica"

func TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiDataCenterReplication(t, "TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationUbuntu", "ubuntu", "enterprise")
}

func TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiDataCenterReplication(t, "TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationAmazonLinux", "amazon-linux", "enterprise")
}

func testCouchbaseMultiDataCenterReplication(t *testing.T, testName string, osName string, edition string) {
	examplesFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples", testName)
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
		var amiIdReplica string

		go func() {
			defer waitForPackerBuilds.Done()

			amiIdPrimary = buildCouchbaseAmi(t, osName, couchbaseAmiDir, edition, awsRegionPrimary, uniqueIdPrimary)
		}()

		go func() {
			defer waitForPackerBuilds.Done()
			amiIdReplica = buildCouchbaseAmi(t, osName, couchbaseAmiDir, edition, awsRegionReplica, uniqueIdReplica)
		}()

		waitForPackerBuilds.Wait()

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
			Vars: map[string]interface{} {
				"aws_region_primary":       awsRegionPrimary,
				"aws_region_replica":       awsRegionReplica,
				"ami_id_primary":           amiIdPrimary,
				"ami_id_replica":           amiIdReplica,
				clusterNamePrimaryVarName:  formatCouchbaseClusterName("primary", uniqueIdPrimary),
				clusterNameReplicaVarName:	formatCouchbaseClusterName("replica", uniqueIdReplica),
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

