# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE THE PRIMARY AND REPLICA PROVIDERS FOR THIS EXAMPLE
# Note that we do this in a separate file so the automated tests can override it and set custom regions in these
# providers. Ideally, we'd use Terraform file overrides instead, but those do not properly override provider aliases
# in Terraform 0.11. This may be fixed in Terraform 0.12.
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  alias = "primary"

  # Region intentionally ommitted so this example will prompt the user for a region when run via Terraform Registry
  # instructions
}

provider "aws" {
  alias = "replica"

  # Region intentionally ommitted so this example will prompt the user for a region when run via Terraform Registry
  # instructions
}
