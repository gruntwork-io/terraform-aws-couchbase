package test

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/packer"
)

// The username and password we use in all the examples, mocks, and tests
const usernameForTest = "admin"
const passwordForTest = "password"

const savedAwsRegion = "AwsRegion"
const savedUniqueId = "UniqueId"

func getRandomAwsRegion(t *testing.T) string {
	// Include regions where Gruntwork's accounts have ACM certs for testing
	includedRegions := []string{
		"eu-west-1",
		"eu-central-1",
		"us-east-1",
		"us-east-2",
		"us-west-1",
		"us-west-2",
		"ap-northeast-1",
		"ca-central-1",
	}

	return aws.GetRandomRegion(t, includedRegions, nil)
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
		Only:     builderName,
		Vars: map[string]string{
			"aws_region":    awsRegion,
			"base_ami_name": baseAmiName,
			"edition":       edition,
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
