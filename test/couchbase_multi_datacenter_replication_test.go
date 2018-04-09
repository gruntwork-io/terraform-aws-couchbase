package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/test-structure"
	"path/filepath"
	"github.com/gruntwork-io/terratest"
	"fmt"
	terralog "github.com/gruntwork-io/terratest/log"
	"log"
	"sync"
)

const primaryName = "primary"
const replicaName = "replica"

const clusterNamePrimaryVarName = "cluster_name_primary"
const clusterNameReplicaVarName = "cluster_name_replica"

func TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiDataCenterReplication(t, "TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationUbuntu", "ubuntu", "enterprise")
}

func TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationAmazonLinux(t *testing.T) {
	t.Parallel()
	testCouchbaseMultiDataCenterReplication(t, "TestIntegrationCouchbaseEnterpriseMultiDataCenterReplicationAmazonLinux", "amazon-linux", "enterprise")
}

func testCouchbaseMultiDataCenterReplication(t *testing.T, testName string, osName string, edition string) {
	logger := terralog.NewLogger(testName)

	examplesFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples", testName, logger)
	couchbaseAmiDir := filepath.Join(examplesFolder, "couchbase-ami")
	couchbaseMultiClusterDir := filepath.Join(examplesFolder, "couchbase-multi-datacenter-replication")

	test_structure.RunTestStage("setup_ami", logger, func() {
		resourceCollectionPrimary := createBaseRandomResourceCollection(t)
		resourceCollectionReplica := createBaseRandomResourceCollection(t)

		var waitForPackerBuilds sync.WaitGroup
		waitForPackerBuilds.Add(2)

		var amiIdPrimary string
		var amiIdReplica string

		go func() {
			defer waitForPackerBuilds.Done()

			amiIdPrimary = buildCouchbaseAmi(t, osName, couchbaseAmiDir, edition, resourceCollectionPrimary, logger)
		}()

		go func() {
			defer waitForPackerBuilds.Done()
			amiIdReplica = buildCouchbaseAmi(t, osName, couchbaseAmiDir, edition, resourceCollectionReplica, logger)
		}()

		waitForPackerBuilds.Wait()

		saveAmiId(t, couchbaseMultiClusterDir, primaryName, amiIdPrimary, logger)
		saveAmiId(t, couchbaseMultiClusterDir, replicaName, amiIdReplica, logger)

		saveRandomResourceCollection(t, couchbaseMultiClusterDir, primaryName, resourceCollectionPrimary, logger)
		saveRandomResourceCollection(t, couchbaseMultiClusterDir, replicaName, resourceCollectionReplica, logger)
	})

	test_structure.RunTestStage("setup_deploy", logger, func() {
		resourceCollectionPrimary := loadRandomResourceCollection(t, couchbaseMultiClusterDir, primaryName, logger)
		resourceCollectionReplica := loadRandomResourceCollection(t, couchbaseMultiClusterDir, replicaName, logger)

		amiIdPrimary := loadAmiId(t, couchbaseMultiClusterDir, primaryName, logger)
		amiIdReplica := loadAmiId(t, couchbaseMultiClusterDir, replicaName, logger)

		terratestOptions := createBaseTerratestOptions(t, testName, couchbaseMultiClusterDir, resourceCollectionPrimary)
		terratestOptions.Vars = map[string]interface{} {
			"aws_region_primary":       resourceCollectionPrimary.AwsRegion,
			"aws_region_replica":       resourceCollectionReplica.AwsRegion,
			"ami_id_primary":           amiIdPrimary,
			"ami_id_replica":           amiIdReplica,
			clusterNamePrimaryVarName:  formatCouchbaseClusterName("primary", resourceCollectionPrimary),
			clusterNameReplicaVarName:	formatCouchbaseClusterName("replica", resourceCollectionReplica),
		}

		deploy(t, terratestOptions)

		test_structure.SaveTerratestOptions(t, couchbaseMultiClusterDir, terratestOptions, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		resourceCollectionPrimary := loadRandomResourceCollection(t, couchbaseMultiClusterDir, primaryName, logger)
		resourceCollectionReplica := loadRandomResourceCollection(t, couchbaseMultiClusterDir, replicaName, logger)
		terratestOptions := test_structure.LoadTerratestOptions(t, couchbaseMultiClusterDir, logger)

		if _, err := terratest.Destroy(terratestOptions, resourceCollectionPrimary); err != nil {
			t.Fatalf("Failed to run destory: %v", err)
		}

		if err := resourceCollectionReplica.DestroyResources(); err != nil {
			t.Fatalf("Failed to destroy resource collection: %v", err)
		}

		cleanupAmiId(t, couchbaseMultiClusterDir, primaryName, logger)
		cleanupAmiId(t, couchbaseMultiClusterDir, replicaName, logger)

		test_structure.CleanupTerratestOptions(t, couchbaseMultiClusterDir, logger)

		cleanupRandomResourceCollection(t, couchbaseMultiClusterDir, primaryName, logger)
		cleanupRandomResourceCollection(t, couchbaseMultiClusterDir, replicaName, logger)
	})

	defer test_structure.RunTestStage("logs", logger, func() {
		resourceCollectionPrimary := loadRandomResourceCollection(t, couchbaseMultiClusterDir, primaryName, logger)
		resourceCollectionReplica := loadRandomResourceCollection(t, couchbaseMultiClusterDir, replicaName, logger)

		testStageLogs(t, couchbaseMultiClusterDir, clusterNamePrimaryVarName, resourceCollectionPrimary, logger)
		testStageLogs(t, couchbaseMultiClusterDir, clusterNameReplicaVarName, resourceCollectionReplica, logger)
	})

	test_structure.RunTestStage("validation", logger, func() {
		terratestOptions := test_structure.LoadTerratestOptions(t, couchbaseMultiClusterDir, logger)

		consoleUrlPrimary, err := terratest.OutputRequired(terratestOptions, "couchbase_primary_web_console_url")
		if err != nil {
			t.Fatal(err)
		}
		consoleUrlPrimary = fmt.Sprintf("http://%s:%s@%s", usernameForTest, passwordForTest, consoleUrlPrimary)

		consoleUrlReplica, err := terratest.OutputRequired(terratestOptions, "couchbase_replica_web_console_url")
		if err != nil {
			t.Fatal(err)
		}
		consoleUrlReplica = fmt.Sprintf("http://%s:%s@%s", usernameForTest, passwordForTest, consoleUrlReplica)

		checkCouchbaseConsoleIsRunning(t, consoleUrlPrimary, logger)
		checkCouchbaseConsoleIsRunning(t, consoleUrlReplica, logger)

		checkCouchbaseClusterIsInitialized(t, consoleUrlPrimary, 3, logger)
		checkCouchbaseClusterIsInitialized(t, consoleUrlReplica, 3, logger)

		checkReplicationIsWorking(t, consoleUrlPrimary, consoleUrlReplica, "test-bucket", "test-bucket-replica", logger)
	})
}

func saveRandomResourceCollection(t *testing.T, testFolder string, collectionName string, resourceCollection *terratest.RandomResourceCollection, logger *log.Logger) {
	test_structure.SaveTestData(t, test_structure.FormatTestDataPath(testFolder, fmt.Sprintf("RandomResourceCollection-%s.json", collectionName)), resourceCollection, logger)
}

func loadRandomResourceCollection(t *testing.T, testFolder string, collectionName string, logger *log.Logger) *terratest.RandomResourceCollection {
	var resourceCollection terratest.RandomResourceCollection
	test_structure.LoadTestData(t, test_structure.FormatTestDataPath(testFolder, fmt.Sprintf("RandomResourceCollection-%s.json", collectionName)), &resourceCollection, logger)
	return &resourceCollection
}

func cleanupRandomResourceCollection(t *testing.T, testFolder string, collectionName string, logger *log.Logger) {
	test_structure.CleanupTestData(t, test_structure.FormatTestDataPath(testFolder, fmt.Sprintf("RandomResourceCollection-%s.json", collectionName)), logger)
}

func saveAmiId(t *testing.T, testFolder string, amiName string, amiId string, logger *log.Logger) {
	test_structure.SaveTestData(t, test_structure.FormatTestDataPath(testFolder, fmt.Sprintf("AmiId-%s.json", amiName)), amiId, logger)
}

func loadAmiId(t *testing.T, testFolder string, amiName string, logger *log.Logger) string {
	var amiId string
	test_structure.LoadTestData(t, test_structure.FormatTestDataPath(testFolder, fmt.Sprintf("AmiId-%s.json", amiName)), &amiId, logger)
	return amiId
}

func cleanupAmiId(t *testing.T, testFolder string, amiName string, logger *log.Logger) {
	test_structure.CleanupTestData(t, test_structure.FormatTestDataPath(testFolder, fmt.Sprintf("AmiId-%s.json", amiName)), logger)
}
