# Local mocks

This folder contains some mocks that make it possible to run and test Couchbase locally, using Docker and Docker 
Compose. The mocks here replace external dependencies, such as EC2 metadata and AWS API calls, with mocks that work 
locally. This is solely to make testing and iterating on the code faster and easier and should NOT be used in 
production!





## Quick start

First, use the Packer template in the [couchbase-ami 
example](https://github.com/gruntwork-io/terraform-aws-couchbase/tree/master/examples/couchbase-ami) to build a Docker 
image with Couchbase and Sync Gateway installed: 

```
packer build -only=ubuntu-docker couchbase.json
```

To run the Docker image, head into one of the `examples/couchbase-xxx/local-test` folders and run:

```
docker-compose up
```

Wait 10-15 seconds and then open your browser to http://localhost:8091/ and you will see the Couchbase Web Console!
You can use the credentials in `local-mocks/systemd/mock-couchbase.env` to login (default: `admin/password`).

You can also open your browser to http://localhost:4984 to access Sync Gateway.

