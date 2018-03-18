package test

import (
	"testing"
	"fmt"
	"path/filepath"
	"github.com/gruntwork-io/terratest/test-structure"
	"time"
	terralog "github.com/gruntwork-io/terratest/log"
	"github.com/gruntwork-io/terratest/files"
	"log"
	"github.com/gruntwork-io/terratest/packer"
	"github.com/gruntwork-io/terratest/shell"
	"github.com/gruntwork-io/terratest/http"
	"strings"
)

// The port numbers used by docker-compose.yml in the couchbase-ami example
var testPorts = map[string]int{
	"ubuntu": 8091,
}

func TestUnitCouchbaseUbuntuInDocker(t *testing.T) {
	t.Parallel()
	testCouchbaseInDocker(t, "ubuntu")
}

func testCouchbaseInDocker(t *testing.T, osName string) {
	testName := fmt.Sprintf("TestCouchbaseInDocker-%s", osName)
	logger := terralog.NewLogger(testName)

	tmpRootDir, err := files.CopyTerraformFolderToTemp("../", testName)
	if err != nil {
		t.Fatal(err)
	}
	couchbaseExampleDir := filepath.Join(tmpRootDir, "examples", "couchbase-ami")

	test_structure.RunTestStage("setup", logger, func() {
		buildCouchbaseWithPacker(t, logger, fmt.Sprintf("%s-docker", osName), "us-east-1", couchbaseExampleDir)
	})

	test_structure.RunTestStage("validation", logger, func() {
		startCouchbaseWithDockerCompose(t, osName, couchbaseExampleDir, logger)
		defer stopCouchbaseWithDockerCompose(t, couchbaseExampleDir, logger)

		testUrl := fmt.Sprintf("http://localhost:%d", testPorts[osName])
		checkCouchbaseConsoleIsRunning(t, testUrl, logger)

		// TODO: connect to Couchbase and write some data
	})
}

func buildCouchbaseWithPacker(t *testing.T, logger *log.Logger, builderName string, awsRegion string, folderPath string) string {
	templatePath := fmt.Sprintf("%s/couchbase.json", folderPath)

	options := packer.PackerOptions{
		Template: templatePath,
		Only: builderName,
		Vars: map[string]string{
			"aws_region": awsRegion,
		},
	}

	artifactId, err := packer.BuildAmi(options, logger)
	if err != nil {
		t.Fatalf("Failed to build Packer template %s: %v", templatePath, err)
	}

	return artifactId
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

func checkCouchbaseConsoleIsRunning(t * testing.T, url string, logger *log.Logger) {
	maxRetries := 20
	sleepBetweenRetries := 5 * time.Second

	err := http_helper.HttpGetWithRetryWithCustomValidation(url, maxRetries, sleepBetweenRetries, logger, func(status int, body string) bool {
		return status == 200 && strings.Contains(body, "Couchbase Console")
	})

	if err != nil {
		t.Fatalf("Failed to connect to Couchbase at %s: %v", url, err)
	}
}