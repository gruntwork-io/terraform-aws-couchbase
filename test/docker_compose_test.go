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
	t.Parallel()
	testCouchbaseInDocker(t, "TestUnitCouchbaseSingleClusterUbuntuInDocker","couchbase-single-cluster", "ubuntu", 2, 8091, 4984)
}

func TestUnitCouchbaseMultiClusterUbuntuInDocker(t *testing.T) {
	t.Parallel()
	testCouchbaseInDocker(t, "TestUnitCouchbaseMultiClusterUbuntuInDocker", "couchbase-multi-cluster","ubuntu", 3,7091, 3984)
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
		startCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, logger)
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

func startCouchbaseWithDockerCompose(t *testing.T, exampleDir string, logger *log.Logger) {
	runDockerCompose(t, exampleDir, logger, "up", "-d")
}

func getDockerComposeLogs(t *testing.T, exampleDir string, logger *log.Logger) {
	logger.Printf("Fetching docker-compose logs:")
	runDockerCompose(t, exampleDir, logger, "logs")
}

func stopCouchbaseWithDockerCompose(t *testing.T, exampleDir string, logger *log.Logger) {
	runDockerCompose(t, exampleDir, logger, "down")
}

func runDockerCompose(t *testing.T, exampleDir string, logger *log.Logger, args ... string) {
	cmd := shell.Command{
		Command:    "docker-compose",
		Args:       args,
		WorkingDir: exampleDir,
		Env: map[string]string{
			// Without this line, running docker-compose up in parallel gives the error "Renaming a container with the
			// same name as its current name". This is because Docker-compose has no way of knowing different containers
			// are from a different "project" unless we tell it so directly. https://github.com/docker/compose/issues/3966#issuecomment-248773016
			"COMPOSE_PROJECT_NAME": filepath.Base(exampleDir),
		},
	}

	if err := shell.RunCommand(cmd, logger); err != nil {
		t.Fatalf("Failed to run docker-compose %v in %s: %v", args, exampleDir, err)
	}
}
