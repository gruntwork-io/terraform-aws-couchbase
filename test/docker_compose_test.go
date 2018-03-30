package test

import (
	"testing"
	"fmt"
	"path/filepath"
	"github.com/gruntwork-io/terratest/test-structure"
	terralog "github.com/gruntwork-io/terratest/log"
	"github.com/gruntwork-io/terratest/files"
	"log"
	"github.com/gruntwork-io/terratest/shell"
)

func TestUnitCouchbaseSingleClusterUbuntuInDocker(t *testing.T) {
	// It seems that running multiple Couchbase clusters in Docker at the same time is more CPU/memory usage than
	// CircleCI can handle, and they all fail to start, so we are disabling parallelism to see if that helps.
	// t.Parallel()
	testCouchbaseInDocker(t, "TestUnitCouchbaseSingleClusterUbuntuInDocker","couchbase-single-cluster", "ubuntu", 3, 8091, 4984)
}

func TestUnitCouchbaseMultiClusterUbuntuInDocker(t *testing.T) {
	// It seems that running multiple Couchbase clusters in Docker at the same time is more CPU/memory usage than
	// CircleCI can handle, and they all fail to start, so we are disabling parallelism to see if that helps.
	// t.Parallel()
	testCouchbaseInDocker(t, "TestUnitCouchbaseMultiClusterUbuntuInDocker", "couchbase-multi-cluster","ubuntu", 4,7091, 3984)
}

func testCouchbaseInDocker(t *testing.T, testName string, examplesFolderName string, osName string, clusterSize int, couchbaseWebConsolePort int, syncGatewayWebConsolePort int) {
	logger := terralog.NewLogger(testName)

	tmpRootDir, err := files.CopyTerraformFolderToTemp("../", testName)
	if err != nil {
		t.Fatal(err)
	}
	couchbaseAmiDir := filepath.Join(tmpRootDir, "examples", "couchbase-ami")
	couchbaseSingleClusterDockerDir := filepath.Join(tmpRootDir, "examples", examplesFolderName, "local-test")

	test_structure.RunTestStage("setup_image", logger, func() {
		buildCouchbaseWithPacker(t, logger, fmt.Sprintf("%s-docker", osName), "couchbase","us-east-1", couchbaseAmiDir)
	})

	test_structure.RunTestStage("setup_docker", logger, func() {
		startCouchbaseWithDockerCompose(t, osName, couchbaseSingleClusterDockerDir, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		getDockerComposeLogs(t, couchbaseSingleClusterDockerDir, logger)
		stopCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, logger)
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

func startCouchbaseWithDockerCompose(t *testing.T, os string, exampleDir string, logger *log.Logger) {
	cmd := shell.Command{
		Command:    "docker-compose",
		Args:       []string{"up", "-d"},
		WorkingDir: exampleDir,
	}

	if err := shell.RunCommand(cmd, logger); err != nil {
		t.Fatalf("Failed to start Couchbase using Docker Compose: %v", err)
	}
}

func getDockerComposeLogs(t *testing.T, exampleDir string, logger *log.Logger) {
	logger.Printf("Fetching docker-compse logs:")

	cmd := shell.Command{
		Command:    "docker-compose",
		Args:       []string{"logs"},
		WorkingDir: exampleDir,
	}

	if err := shell.RunCommand(cmd, logger); err != nil {
		t.Fatalf("Failed to get Docker Compose logs: %v", err)
	}
}

func stopCouchbaseWithDockerCompose(t *testing.T, exampleDir string, logger *log.Logger) {
	cmd := shell.Command{
		Command:    "docker-compose",
		Args:       []string{"down"},
		WorkingDir: exampleDir,
	}

	if err := shell.RunCommand(cmd, logger); err != nil {
		t.Fatalf("Failed to stop Couchbase using Docker Compose: %v", err)
	}
}

