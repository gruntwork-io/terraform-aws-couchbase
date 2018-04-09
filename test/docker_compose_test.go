package test

import (
	"testing"
	"fmt"
	"path/filepath"
	"github.com/gruntwork-io/terratest/test-structure"
	terralog "github.com/gruntwork-io/terratest/log"
	"log"
	"github.com/gruntwork-io/terratest/shell"
	"strconv"
	"github.com/gruntwork-io/terratest/util"
	"os"
)

func TestUnitCouchbaseInDocker(t *testing.T) {
	t.Parallel()

	basicTestCases := []struct {
		testName string
		examplesFolderName string
		osName string
		edition string
		clusterSize int
		couchbaseWebConsolePort int
		syncGatewayWebConsolePort int
	} {
		{"TestUnitCouchbaseCommunitySingleClusterUbuntuInDocker","couchbase-single-cluster", "ubuntu", "community", 2, 8091, 4984},
		{"TestUnitCouchbaseEnterpriseMultiClusterAmazonLinuxInDocker", "couchbase-multi-cluster", "amazon-linux", "enterprise", 3,7091, 3984},
	}

	for _, testCase := range basicTestCases {
		testCase := testCase // capture range variable; otherwise, only the very last test case will run!

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()
			skipInCircleCi(t)
			testCouchbaseInDockerBasic(t, testCase.testName, testCase.examplesFolderName, testCase.osName, testCase.edition, testCase.clusterSize, testCase.couchbaseWebConsolePort, testCase.syncGatewayWebConsolePort)
		})
	}

	replicationTestCases := []struct {
		testName string
		examplesFolderName string
		osName string
		edition string
		clusterSize int
		couchbaseWebConsolePortEast int
		couchbaseWebConsolePortWest int
	} {
		{"TestUnitCouchbaseEnterpriseMultiDataCenterUbuntuInDocker", "couchbase-multi-datacenter-replication", "ubuntu", "enterprise", 2,6091, 5091},
	}

	for _, testCase := range replicationTestCases {
		testCase := testCase // capture range variable; otherwise, only the very last test case will run!

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()
			skipInCircleCi(t)
			testCouchbaseInDockerReplication(t, testCase.testName, testCase.examplesFolderName, testCase.osName, testCase.edition, testCase.clusterSize, testCase.couchbaseWebConsolePortEast, testCase.couchbaseWebConsolePortWest)
		})
	}
}

func skipInCircleCi(t *testing.T) {
	if os.Getenv("CIRCLECI") != "" {
		t.Skip("Skipping Docker unit tests in CircleCI, as for some crazy reason, Couchbase often fails to start in a Docker container when running in CircleCI. See https://github.com/gruntwork-io/terraform-aws-couchbase/pull/10 for details.")
	}
}

func testCouchbaseInDockerBasic(t *testing.T, testName string, examplesFolderName string, osName string, edition string, clusterSize int, couchbaseWebConsolePort int, syncGatewayWebConsolePort int) {
	logger := terralog.NewLogger(testName)

	uniqueId := util.UniqueId()
	envVars := map[string]string{
		"OS_NAME": osName,
		"CONTAINER_BASE_NAME": fmt.Sprintf("couchbase-%s", uniqueId),
		"WEB_CONSOLE_PORT": strconv.Itoa(couchbaseWebConsolePort),
		"SYNC_GATEWAY_PORT": strconv.Itoa(syncGatewayWebConsolePort),
	}

	tmpExamplesDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples", testName, logger)
	couchbaseAmiDir := filepath.Join(tmpExamplesDir, "couchbase-ami")
	couchbaseSingleClusterDockerDir := filepath.Join(tmpExamplesDir, examplesFolderName, "local-test")

	test_structure.RunTestStage("setup_image", logger, func() {
		buildCouchbaseWithPacker(logger, fmt.Sprintf("%s-docker", osName), "couchbase","us-east-1", couchbaseAmiDir, edition)
	})

	test_structure.RunTestStage("setup_docker", logger, func() {
		startCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, testName, envVars, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		getDockerComposeLogs(t, couchbaseSingleClusterDockerDir, testName, envVars, logger)
		stopCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, testName, envVars, logger)
	})

	test_structure.RunTestStage("validation", logger, func() {
		consoleUrl := fmt.Sprintf("http://localhost:%d", couchbaseWebConsolePort)
		checkCouchbaseConsoleIsRunning(t, consoleUrl, logger)

		dataNodesUrl := fmt.Sprintf("http://%s:%s@localhost:%d", usernameForTest, passwordForTest, couchbaseWebConsolePort)
		checkCouchbaseClusterIsInitialized(t, dataNodesUrl, clusterSize, logger)
		checkCouchbaseDataNodesWorking(t, dataNodesUrl, logger)

		syncGatewayUrl := fmt.Sprintf("http://localhost:%d/mock-couchbase-asg", syncGatewayWebConsolePort)
		checkSyncGatewayWorking(t, syncGatewayUrl, logger)
	})
}

func testCouchbaseInDockerReplication(t *testing.T, testName string, examplesFolderName string, osName string, edition string, clusterSize int, couchbaseWebConsolePortEast int, couchbaseWebConsolePortWest int) {
	logger := terralog.NewLogger(testName)

	uniqueId := util.UniqueId()
	envVars := map[string]string{
		"OS_NAME": osName,
		"CONTAINER_BASE_NAME": fmt.Sprintf("couchbase-%s", uniqueId),
		"WEB_CONSOLE_EAST_PORT": strconv.Itoa(couchbaseWebConsolePortEast),
		"WEB_CONSOLE_WEST_PORT": strconv.Itoa(couchbaseWebConsolePortWest),
	}

	tmpExamplesDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples", testName, logger)
	couchbaseAmiDir := filepath.Join(tmpExamplesDir, "couchbase-ami")
	couchbaseSingleClusterDockerDir := filepath.Join(tmpExamplesDir, examplesFolderName, "local-test")

	test_structure.RunTestStage("setup_image", logger, func() {
		buildCouchbaseWithPacker(logger, fmt.Sprintf("%s-docker", osName), "couchbase","us-east-1", couchbaseAmiDir, edition)
	})

	test_structure.RunTestStage("setup_docker", logger, func() {
		startCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, testName, envVars, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		getDockerComposeLogs(t, couchbaseSingleClusterDockerDir, testName, envVars, logger)
		stopCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, testName, envVars, logger)
	})

	test_structure.RunTestStage("validation", logger, func() {
		consoleUrlEast := fmt.Sprintf("http://localhost:%d", couchbaseWebConsolePortEast)
		checkCouchbaseConsoleIsRunning(t, consoleUrlEast, logger)

		consoleUrlWest := fmt.Sprintf("http://localhost:%d", couchbaseWebConsolePortWest)
		checkCouchbaseConsoleIsRunning(t, consoleUrlWest, logger)

		dataNodesUrlEast := fmt.Sprintf("http://%s:%s@localhost:%d", usernameForTest, passwordForTest, couchbaseWebConsolePortEast)
		checkCouchbaseClusterIsInitialized(t, dataNodesUrlEast, clusterSize, logger)

		dataNodesUrlWest := fmt.Sprintf("http://%s:%s@localhost:%d", usernameForTest, passwordForTest, couchbaseWebConsolePortWest)
		checkCouchbaseClusterIsInitialized(t, dataNodesUrlWest, clusterSize, logger)

		checkReplicationIsWorking(t, dataNodesUrlEast, dataNodesUrlWest, "test-bucket", "test-bucket-replica", logger)
	})
}

func startCouchbaseWithDockerCompose(t *testing.T, exampleDir string, testName string, envVars map[string]string, logger *log.Logger) {
	runDockerCompose(t, exampleDir, testName, envVars, logger, "up", "-d")
}

func getDockerComposeLogs(t *testing.T, exampleDir string, testName string, envVars map[string]string, logger *log.Logger) {
	logger.Printf("Fetching docker-compose logs:")
	runDockerCompose(t, exampleDir, testName, envVars, logger, "logs")
}

func stopCouchbaseWithDockerCompose(t *testing.T, exampleDir string, testName string, envVars map[string]string, logger *log.Logger) {
	runDockerCompose(t, exampleDir, testName, envVars, logger, "down")
	runDockerCompose(t, exampleDir, testName, envVars, logger, "rm", "-f")
}

func runDockerCompose(t *testing.T, exampleDir string, testName string, envVars map[string]string, logger *log.Logger, args ... string) {
	cmd := shell.Command{
		Command:    "docker-compose",
		// We append --project-name to ensure containers from multiple different tests using Docker Compose don't end
		// up in the same project and end up conflicting with each other.
		Args:       append([]string{"--project-name", testName}, args...),
		WorkingDir: exampleDir,
		Env: envVars,
	}

	if err := shell.RunCommand(cmd, logger); err != nil {
		t.Fatalf("Failed to run docker-compose %v in %s: %v", args, exampleDir, err)
	}
}
