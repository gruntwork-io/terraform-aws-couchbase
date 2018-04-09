package test

import "testing"

func TestIntegrationCouchbaseCommunitySingleClusterDnsTlsUbuntu(t *testing.T) {
	t.Parallel()
	testCouchbaseSingleCluster(t, "TestIntegrationCouchbaseCommunitySingleClusterDnsTlsUbuntu", "ubuntu", "community", "https")
}

