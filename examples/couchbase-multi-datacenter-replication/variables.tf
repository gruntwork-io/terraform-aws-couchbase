# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "primary_region" {
  description = "The region to deploy the primary to"
  type        = string
}

variable "replica_region" {
  description = "The region to deploy the replica to"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "ami_id_primary" {
  description = "The ID of the AMI to run in the primary cluster. This should be an AMI built from the Packer template under examples/couchbase-ami/couchbase.json. Set to null to use one of the example AMIs we have published publicly."
  type        = string
  default     = null
}

variable "ami_id_replica" {
  description = "The ID of the AMI to run in the replica cluster. This should be an AMI built from the Packer template under examples/couchbase-ami/couchbase.json. Set to null to use one of the example AMIs we have published publicly."
  type        = string
  default     = null
}

variable "cluster_name_primary" {
  description = "What to name the primary Couchbase cluster and all of its associated resources"
  type        = string
  default     = "couchbase-server-primary"
}

variable "cluster_name_replica" {
  description = "What to name the replica Couchbase cluster and all of its associated resources"
  type        = string
  default     = "couchbase-server-replica"
}

variable "ssh_key_name_primary" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in the primary Couchbase cluster. Must be a Key Pair in the same region as the primary cluster. Set to null to not associate a Key Pair."
  type        = string
  default     = null
}

variable "ssh_key_name_replica" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in the replica Couchbase cluster. Must be a Key Pair in the same region as the replica cluster. Set to null to not associate a Key Pair."
  type        = string
  default     = null
}

variable "couchbase_load_balancer_port" {
  description = "The port the load balancer should listen on for Couchbase Web Console requests."
  type        = number
  default     = 8091
}

