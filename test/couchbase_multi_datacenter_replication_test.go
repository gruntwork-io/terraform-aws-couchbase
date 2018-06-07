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
	"github.com/gruntwork-io/terratest/modules/files"
	"os"
	"github.com/gruntwork-io/terratest/modules/logger"
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

func TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiDataCenterReplication(t, "ubuntu", "enterprise")
}

func TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiDataCenterReplication(t, "amazon-linux", "enterprise")
}

func testCouchbaseMultiDataCenterReplication(t *testing.T, osName string, edition string) {
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

		restoreProvider(t, couchbaseMultiClusterDir)

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

		overrideProvider(t, couchbaseMultiClusterDir, awsRegionPrimary, awsRegionReplica)

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

const providerOverrideTemplate = `
# This file temporarily overrides the providers at test time. The original providers file should be restored at the
# end of the test!

provider "aws" {
  alias  = "primary"
  region = "%s"
}

provider "aws" {
  alias  = "replica"
  region = "%s"
}
`

// In order for the examples to work well with the Terraform Registry, where they are wrapped in a module, we cannot
// define the AWS regions in those providers. This works OK for manual usage, where the user can specify the region
// interactively, but not at test time. Therefore, as a workaround, we override the providers.tf file at test time
// with the regions fully defined, and then put it back at the end of the test in the restoreProvider function.
func overrideProvider(t *testing.T, couchbaseMultiClusterDir string, awsRegionPrimary string, awsRegionReplica string) {
	providersFilePath := filepath.Join(couchbaseMultiClusterDir, providersFile)
	providersFileBackupPath := filepath.Join(couchbaseMultiClusterDir, providersFileBackup)

	logger.Logf(t, "Backing up %s to %s", providersFilePath, providersFileBackupPath)
	if err := files.CopyFile(providersFilePath, providersFileBackupPath); err != nil {
		t.Fatal(err)
	}

	newProvidersFileContents := fmt.Sprintf(providerOverrideTemplate, awsRegionPrimary, awsRegionReplica)

	logger.Logf(t, "Creating override proviers file at %s with contents:\n%s", providersFilePath, newProvidersFileContents)
	if err := files.WriteFileWithSamePermissions(providersFilePath, providersFilePath, []byte(newProvidersFileContents)); err != nil {
		t.Fatal(err)
	}
}

// See the overrideProvider method for details
func restoreProvider(t *testing.T, couchbaseMultiClusterDir string) {
	providersFilePath := filepath.Join(couchbaseMultiClusterDir, providersFile)
	providersFileBackupPath := filepath.Join(couchbaseMultiClusterDir, providersFileBackup)

	logger.Logf(t, "Restoring %s from %s", providersFilePath, providersFileBackupPath)
	if err := files.CopyFile(providersFileBackupPath, providersFilePath); err != nil {
		t.Fatal(err)
	}

	logger.Logf(t, "Deleting %s", providersFileBackupPath)
	if err := os.Remove(providersFileBackupPath); err != nil {
		t.Fatal(err)
	}
}