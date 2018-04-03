package test

import (
	"testing"
	"github.com/gruntwork-io/terratest"
	"fmt"
	"github.com/gruntwork-io/terratest/packer"
	"log"
	"time"
	"net/http"
	"net/url"
	"io/ioutil"
	"strings"
)

// The username and password we use in all the examples, mocks, and tests
const usernameForTest = "admin"
const passwordForTest = "password"

func createBaseRandomResourceCollection(t * testing.T) *terratest.RandomResourceCollection {
	resourceCollectionOptions := terratest.NewRandomResourceCollectionOptions()

	randomResourceCollection, err := terratest.CreateRandomResourceCollection(resourceCollectionOptions)
	if err != nil {
		t.Fatalf("Failed to create Random Resource Collection: %s", err.Error())
	}

	return randomResourceCollection
}

func createBaseTerratestOptions(t *testing.T, testName string, folder string, resourceCollection *terratest.RandomResourceCollection) *terratest.TerratestOptions {
	terratestOptions := terratest.NewTerratestOptions()

	terratestOptions.UniqueId = resourceCollection.UniqueId
	terratestOptions.TemplatePath = folder
	terratestOptions.TestName = testName

	return terratestOptions
}

func buildCouchbaseWithPacker(t *testing.T, logger *log.Logger, builderName string, baseAmiName string, awsRegion string, folderPath string) string {
	templatePath := fmt.Sprintf("%s/couchbase.json", folderPath)

	// Explicitly specify /tmp here, as otherwise, on Mac, we get /var/folders/xx/yyy, which is not available in the
	// VM or mounted by default.
	packerTmpDir, err := ioutil.TempDir("/tmp", builderName)
	if err != nil {
		t.Fatal(err)
	}

	options := packer.PackerOptions{
		Template: templatePath,
		Only: builderName,
		Vars: map[string]string{
			"aws_region": awsRegion,
			"base_ami_name": baseAmiName,
		},

		// If you're using the Docker build with Packer and use the file provisioner to upload files, Packer will first
		// stage those files in a temporary directory it creates under home. If you're building multiple Docker images
		// with Packer at the same time, then these builds may overwrite each other's files in that temp directory. To
		// avoid that, we allow users to override that tmp dir. For more info, see:
		// https://www.packer.io/docs/builders/docker.html#overriding-the-host-directory
		Env: map[string]string{
			"PACKER_TMP_DIR": packerTmpDir,
		},
	}


	artifactId, err := packer.BuildAmi(options, logger)
	if err != nil {
		t.Fatalf("Failed to build Packer template %s: %v", templatePath, err)
	}

	return artifactId
}

func deploy(t *testing.T, terratestOptions *terratest.TerratestOptions) {
	_, err := terratest.Apply(terratestOptions)
	if err != nil {
		t.Fatalf("Failed to apply templates: %s", err.Error())
	}
}

func HttpPostForm(t *testing.T, postUrl string, postParams url.Values, logger *log.Logger) (int, string, error) {
	logger.Printf("Making an HTTP POST call to URL %s with body %v", postUrl, postParams)

	client := http.Client{
		// By default, Go does not impose a timeout, so an HTTP connection attempt can hang for a LONG time.
		Timeout: 10 * time.Second,
	}

	resp, err := client.PostForm(postUrl, postParams)
	if err != nil {
		return -1, "", err
	}

	defer resp.Body.Close()
	respBody, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		return -1, "", err
	}

	return resp.StatusCode, strings.TrimSpace(string(respBody)), nil
}