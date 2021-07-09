package test

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"testing"

	"github.com/gruntwork-io/terratest/modules/docker"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestUnitCouchbaseInDocker(t *testing.T) {
	t.Parallel()

	basicTestCases := []struct {
		testName                  string
		examplesFolderName        string
		osName                    string
		edition                   string
		clusterSize               int
		couchbaseWebConsolePort   int
		syncGatewayWebConsolePort int
	}{
		{"TestUnitCouchbaseCommunitySingleClusterUbuntu16InDocker", "couchbase-cluster-simple", "ubuntu", "community", 2, 8091, 4984},
		{"TestUnitCouchbaseCommunitySingleClusterUbuntu18InDocker", "couchbase-cluster-simple", "ubuntu-18", "community", 2, 8091, 4984},
		{"TestUnitCouchbaseEnterpriseMultiClusterAmazonLinuxInDocker", "couchbase-cluster-mds", "amazon-linux", "enterprise", 3, 7091, 3984},
	}

	for _, testCase := range basicTestCases {
		testCase := testCase // capture range variable; otherwise, only the very last test case will run!

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()
			skipInCircleCi(t)
			testCouchbaseInDockerBasic(t, testCase.examplesFolderName, testCase.osName, testCase.edition, testCase.clusterSize, testCase.couchbaseWebConsolePort, testCase.syncGatewayWebConsolePort)
		})
	}

	replicationTestCases := []struct {
		testName                    string
		examplesFolderName          string
		osName                      string
		edition                     string
		clusterSize                 int
		couchbaseWebConsolePortEast int
		couchbaseWebConsolePortWest int
	}{
		{"TestUnitCouchbaseEnterpriseMultiDataCenterUbuntu16InDocker", "couchbase-multi-datacenter-replication", "ubuntu", "enterprise", 2, 6091, 5091},
		{"TestUnitCouchbaseEnterpriseMultiDataCenterUbuntu18InDocker", "couchbase-multi-datacenter-replication", "ubuntu-18", "enterprise", 2, 6091, 5091},
	}

	for _, testCase := range replicationTestCases {
		testCase := testCase // capture range variable; otherwise, only the very last test case will run!

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()
			skipInCircleCi(t)
			testCouchbaseInDockerReplication(t, testCase.examplesFolderName, testCase.osName, testCase.edition, testCase.clusterSize, testCase.couchbaseWebConsolePortEast, testCase.couchbaseWebConsolePortWest)
		})
	}
}

func skipInCircleCi(t *testing.T) {
	if os.Getenv("CIRCLECI") != "" {
		t.Skip("Skipping Docker unit tests in CircleCI, as for some crazy reason, Couchbase often fails to start in a Docker container when running in CircleCI. See https://github.com/gruntwork-io/terraform-aws-couchbase/pull/10 for details.")
	}
}

func testCouchbaseInDockerBasic(t *testing.T, examplesFolderName string, osName string, edition string, clusterSize int, couchbaseWebConsolePort int, syncGatewayWebConsolePort int) {
	uniqueId := random.UniqueId()
	envVars := map[string]string{
		"OS_NAME":             osName,
		"CONTAINER_BASE_NAME": fmt.Sprintf("couchbase-%s", uniqueId),
		"WEB_CONSOLE_PORT":    strconv.Itoa(couchbaseWebConsolePort),
		"SYNC_GATEWAY_PORT":   strconv.Itoa(syncGatewayWebConsolePort),
	}

	tmpExamplesDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples")
	couchbaseAmiDir := filepath.Join(tmpExamplesDir, "couchbase-ami")
	couchbaseSingleClusterDockerDir := filepath.Join(tmpExamplesDir, examplesFolderName, "local-test")

	test_structure.RunTestStage(t, "setup_image", func() {
		buildCouchbaseWithPacker(t, fmt.Sprintf("%s-docker", osName), "couchbase", "us-east-1", couchbaseAmiDir, edition)
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		getDockerComposeLogs(t, couchbaseSingleClusterDockerDir, envVars)
		stopCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, envVars)
	})

	test_structure.RunTestStage(t, "setup_docker", func() {
		startCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, envVars)
	})

	test_structure.RunTestStage(t, "validation", func() {
		consoleUrl := fmt.Sprintf("http://localhost:%d", couchbaseWebConsolePort)
		checkCouchbaseConsoleIsRunning(t, consoleUrl)

		dataNodesUrl := fmt.Sprintf("http://%s:%s@localhost:%d", usernameForTest, passwordForTest, couchbaseWebConsolePort)
		checkCouchbaseClusterIsInitialized(t, dataNodesUrl, clusterSize)
		checkCouchbaseDataNodesWorking(t, dataNodesUrl)

		syncGatewayUrl := fmt.Sprintf("http://localhost:%d/mock-couchbase-asg", syncGatewayWebConsolePort)
		checkSyncGatewayWorking(t, syncGatewayUrl)
	})
}

func testCouchbaseInDockerReplication(t *testing.T, examplesFolderName string, osName string, edition string, clusterSize int, couchbaseWebConsolePortEast int, couchbaseWebConsolePortWest int) {
	uniqueId := random.UniqueId()
	envVars := map[string]string{
		"OS_NAME":               osName,
		"CONTAINER_BASE_NAME":   fmt.Sprintf("couchbase-%s", uniqueId),
		"WEB_CONSOLE_EAST_PORT": strconv.Itoa(couchbaseWebConsolePortEast),
		"WEB_CONSOLE_WEST_PORT": strconv.Itoa(couchbaseWebConsolePortWest),
	}

	tmpExamplesDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples")
	couchbaseAmiDir := filepath.Join(tmpExamplesDir, "couchbase-ami")
	couchbaseSingleClusterDockerDir := filepath.Join(tmpExamplesDir, examplesFolderName, "local-test")

	test_structure.RunTestStage(t, "setup_image", func() {
		buildCouchbaseWithPacker(t, fmt.Sprintf("%s-docker", osName), "couchbase", "us-east-1", couchbaseAmiDir, edition)
	})

	test_structure.RunTestStage(t, "setup_docker", func() {
		startCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, envVars)
	})

	defer test_structure.RunTestStage(t, "teardown", func() {
		getDockerComposeLogs(t, couchbaseSingleClusterDockerDir, envVars)
		stopCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, envVars)
	})

	test_structure.RunTestStage(t, "validation", func() {
		consoleUrlEast := fmt.Sprintf("http://localhost:%d", couchbaseWebConsolePortEast)
		checkCouchbaseConsoleIsRunning(t, consoleUrlEast)

		consoleUrlWest := fmt.Sprintf("http://localhost:%d", couchbaseWebConsolePortWest)
		checkCouchbaseConsoleIsRunning(t, consoleUrlWest)

		dataNodesUrlEast := fmt.Sprintf("http://%s:%s@localhost:%d", usernameForTest, passwordForTest, couchbaseWebConsolePortEast)
		checkCouchbaseClusterIsInitialized(t, dataNodesUrlEast, clusterSize)

		dataNodesUrlWest := fmt.Sprintf("http://%s:%s@localhost:%d", usernameForTest, passwordForTest, couchbaseWebConsolePortWest)
		checkCouchbaseClusterIsInitialized(t, dataNodesUrlWest, clusterSize)

		checkReplicationIsWorking(t, dataNodesUrlEast, dataNodesUrlWest, "test-bucket", "test-bucket-replica")
	})
}

func startCouchbaseWithDockerCompose(t *testing.T, exampleDir string, envVars map[string]string) {
	docker.RunDockerCompose(t, &docker.Options{WorkingDir: exampleDir, EnvVars: envVars}, "up", "-d")
}

func getDockerComposeLogs(t *testing.T, exampleDir string, envVars map[string]string) {
	logger.Logf(t, "Fetching docker-compose logs:")
	docker.RunDockerCompose(t, &docker.Options{WorkingDir: exampleDir, EnvVars: envVars}, "logs")
}

func stopCouchbaseWithDockerCompose(t *testing.T, exampleDir string, envVars map[string]string) {
	docker.RunDockerCompose(t, &docker.Options{WorkingDir: exampleDir, EnvVars: envVars}, "down")
	docker.RunDockerCompose(t, &docker.Options{WorkingDir: exampleDir, EnvVars: envVars}, "rm", "-f")
}
