package test

import (
	"testing"
	"fmt"
	"time"
	"net/http"
	"net/url"
	"io/ioutil"
	"strings"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/packer"
	"github.com/gruntwork-io/terratest/modules/aws"
)

// The username and password we use in all the examples, mocks, and tests
const usernameForTest = "admin"
const passwordForTest = "password"

const savedAwsRegion = "AwsRegion"
const savedUniqueId = "UniqueId"

func getRandomAwsRegion(t *testing.T) string {
	// Exclude regions where Gruntwork's accounts don't have ACM certs for testing
	excludedRegions := []string{
		"ap-northeast-2",
		"ap-southeast-1",
		"ap-southeast-2",
		"eu-central-1",
		"us-west-2",
		"sa-east-1", // Amazon Linux 2 doesn't seem to be available in this region
		"eu-north-1", // Many instance types are not available in this region
	}

	return aws.GetRandomRegion(t, nil, excludedRegions)
}

func buildCouchbaseWithPacker(t *testing.T, builderName string, baseAmiName string, awsRegion string, folderPath string, edition string) string {
	amiId, err := buildCouchbaseWithPackerE(t, builderName, baseAmiName, awsRegion, folderPath, edition)
	if err != nil {
		t.Fatal(err)
	}
	return amiId
}

func buildCouchbaseWithPackerE(t *testing.T, builderName string, baseAmiName string, awsRegion string, folderPath string, edition string) (string, error) {
	templatePath := fmt.Sprintf("%s/couchbase.json", folderPath)

	options := &packer.Options{
		Template: templatePath,
		Only: builderName,
		Vars: map[string]string{
			"aws_region": awsRegion,
			"base_ami_name": baseAmiName,
			"edition": edition,
		},
	}

	return packer.BuildAmiE(t, options)
}


func HttpPostForm(t *testing.T, postUrl string, postParams url.Values) (int, string, error) {
	logger.Logf(t, "Making an HTTP POST call to URL %s with body %v", postUrl, postParams)

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