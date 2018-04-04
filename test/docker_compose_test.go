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
	"time"
)

type BuildRequest struct {
	OsName   string
	TestName string
	Dir      string
	Logger   *log.Logger
	Finished chan error
}

func TestUnitCouchbaseInDocker(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		testName string
		examplesFolderName string
		osName string
		clusterSize int
		couchbaseWebConsolePort int
		syncGatewayWebConsolePort int
	} {
		{"TestUnitCouchbaseSingleClusterUbuntuInDocker","couchbase-single-cluster", "ubuntu", 2, 8091, 4984},
		{"TestUnitCouchbaseMultiClusterUbuntuInDocker", "couchbase-multi-cluster","ubuntu", 3,7091, 3984},
		{"TestUnitCouchbaseSingleClusterAmazonLinuxInDocker","couchbase-single-cluster", "amazon-linux", 2, 6091, 2984},
		{"TestUnitCouchbaseMultiClusterAmazonLinuxInDocker", "couchbase-multi-cluster","amazon-linux", 3,5091, 1984},
	}

	// Running multiple Packer builds in parallel to build Docker images leads to really strange, intermittent errors
	// such as:
	//
	// Failed to upload to '/tmp' in container: Error response from daemon: Error processing tar file(exit status 1): chtimes /foo/bar: no such file or directory.
	//
	// It fails on different files and different builds every time, and setting different PACKER_TMP_DIR does not help.
	// Therefore, as a workaround, we spin up a single goroutine to do all the Packer builds. It will receive message
	// on a channel asking it to build a Docker image for a particular OS and then go off to either build that image,
	// or if it has already built it, simplify notify the caller the image is already done. This way, all the Packer
	// builds will happen sequentially and at most once for each OS we support.
	buildRequests := make(chan BuildRequest)
	go dockerImageBuilder(t, buildRequests)

	for _, testCase := range testCases {
		testCase := testCase // capture range variable; otherwise, only the very last test case will run!

		t.Run(testCase.testName, func(t *testing.T) {
			t.Parallel()
			testCouchbaseInDocker(t, testCase.testName, testCase.examplesFolderName, testCase.osName, testCase.clusterSize, testCase.couchbaseWebConsolePort, testCase.syncGatewayWebConsolePort, buildRequests)
		})
	}
}

func dockerImageBuilder(t *testing.T, buildRequests chan BuildRequest) {
	completedBuildsByOs := map[string]error{}

	for {
		processBuildRequest(<-buildRequests, completedBuildsByOs)
	}
}

func processBuildRequest(request BuildRequest, completedBuildsByOs map[string]error) {
	err, buildFinished := completedBuildsByOs[request.OsName]

	if !buildFinished {
		description := fmt.Sprintf("Packer build for Couchbase Docker image for test %s on OS %s in %s", request.TestName, request.OsName, request.Dir)
		maxRetries := 5
		sleepBetweenRetries := 15 * time.Second

		// For some reason, when we run multiple Packer builds with Docker builders in parallel in CircleCI, we
		// intermittently get the error:
		//
		// Failed to upload to '/tmp' in container: Error response from daemon: Error processing tar file(exit status 1): lchown <RANDOM_FILE>: no such file or directory
		//
		// There seems to be no workaround for this, so we just retry the build a few times if it fails.
		request.Logger.Println(description)
		_, err = util.DoWithRetry(description, maxRetries, sleepBetweenRetries, request.Logger, func() (string, error) {
			return buildCouchbaseWithPacker(request.Logger, fmt.Sprintf("%s-docker", request.OsName), "couchbase","us-east-1", request.Dir)
		})
	}

	request.Logger.Printf("Notifying test %s that Packer build for OS %s is done", request.TestName, request.OsName)
	completedBuildsByOs[request.OsName] = err
	request.Finished <- err
}

func testCouchbaseInDocker(t *testing.T, testName string, examplesFolderName string, osName string, clusterSize int, couchbaseWebConsolePort int, syncGatewayWebConsolePort int, buildRequests chan BuildRequest) {
	logger := terralog.NewLogger(testName)

	tmpExamplesDir := test_structure.CopyTerraformFolderToTemp(t, "../", "examples", testName, logger)
	couchbaseAmiDir := filepath.Join(tmpExamplesDir, "couchbase-ami")
	couchbaseSingleClusterDockerDir := filepath.Join(tmpExamplesDir, examplesFolderName, "local-test")
	uniqueId := util.UniqueId()

	test_structure.RunTestStage("setup_image", logger, func() {
		logger.Printf("Requesting Packer build for OS %s in %s", osName, couchbaseAmiDir)

		buildFinished := make(chan error)
		buildRequests <- BuildRequest{OsName: osName, TestName: testName, Dir: couchbaseAmiDir, Logger: logger, Finished: buildFinished}

		err := <-buildFinished
		if err != nil {
			t.Fatalf("Failed to build Couchbase Docker image: %v", err)
		}
	})

	test_structure.RunTestStage("setup_docker", logger, func() {
		startCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, testName, osName, couchbaseWebConsolePort, syncGatewayWebConsolePort, uniqueId, logger)
	})

	defer test_structure.RunTestStage("teardown", logger, func() {
		getDockerComposeLogs(t, couchbaseSingleClusterDockerDir, testName, osName, couchbaseWebConsolePort, syncGatewayWebConsolePort, uniqueId, logger)
		stopCouchbaseWithDockerCompose(t, couchbaseSingleClusterDockerDir, testName, osName, couchbaseWebConsolePort, syncGatewayWebConsolePort, uniqueId, logger)
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

func startCouchbaseWithDockerCompose(t *testing.T, exampleDir string, testName string, osName string, webConsolePort int, syncGatewayPort int, uniqueId string, logger *log.Logger) {
	runDockerCompose(t, exampleDir, testName, osName, webConsolePort, syncGatewayPort, uniqueId, logger, "up", "-d")
}

func getDockerComposeLogs(t *testing.T, exampleDir string, testName string, osName string, webConsolePort int, syncGatewayPort int, uniqueId string, logger *log.Logger) {
	logger.Printf("Fetching docker-compose logs:")
	runDockerCompose(t, exampleDir, testName, osName, webConsolePort, syncGatewayPort, uniqueId, logger, "logs")
}

func stopCouchbaseWithDockerCompose(t *testing.T, exampleDir string, testName string, osName string, webConsolePort int, syncGatewayPort int, uniqueId string, logger *log.Logger) {
	runDockerCompose(t, exampleDir, testName, osName, webConsolePort, syncGatewayPort, uniqueId, logger, "down")
	runDockerCompose(t, exampleDir, testName, osName, webConsolePort, syncGatewayPort, uniqueId, logger, "rm", "-f")
}

func runDockerCompose(t *testing.T, exampleDir string, testName string, osName string, webConsolePort int, syncGatewayPort int, uniqueId string, logger *log.Logger, args ... string) {
	cmd := shell.Command{
		Command:    "docker-compose",
		// We append --project-name to ensure containers from multiple different tests using Docker Compose don't end
		// up in the same project and end up conflicting with each other.
		Args:       append([]string{"--project-name", testName}, args...),
		WorkingDir: exampleDir,
		Env: map[string]string{
			"OS_NAME": osName,
			"WEB_CONSOLE_PORT": strconv.Itoa(webConsolePort),
			"SYNC_GATEWAY_PORT": strconv.Itoa(syncGatewayPort),
			"CONTAINER_BASE_NAME": fmt.Sprintf("couchbase-%s", uniqueId),
		},
	}

	if err := shell.RunCommand(cmd, logger); err != nil {
		t.Fatalf("Failed to run docker-compose %v in %s: %v", args, exampleDir, err)
	}
}
