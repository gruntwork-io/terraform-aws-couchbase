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

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "ami_id_primary" {
  description = "The ID of the AMI to run in the primary cluster. This should be an AMI built from the Packer template under examples/couchbase-ami/couchbase.json. Leave blank to use one of the example AMIs we have published publicly."
  default     = ""
}

variable "ami_id_replica" {
  description = "The ID of the AMI to run in the replica cluster. This should be an AMI built from the Packer template under examples/couchbase-ami/couchbase.json. Leave blank to use one of the example AMIs we have published publicly."
  default     = ""
}

variable "cluster_name_primary" {
  description = "What to name the primary Couchbase cluster and all of its associated resources"
  default     = "couchbase-server-primary"
}

variable "cluster_name_replica" {
  description = "What to name the replica Couchbase cluster and all of its associated resources"
  default     = "couchbase-server-replica"
}

variable "ssh_key_name_primary" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in the primary Couchbase cluster. Must be a Key Pair in the same region as the primary cluster. Set to an empty string to not associate a Key Pair."
  default     = ""
}

variable "ssh_key_name_replica" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in the replica Couchbase cluster. Must be a Key Pair in the same region as the replica cluster. Set to an empty string to not associate a Key Pair."
  default     = ""
}

variable "couchbase_load_balancer_port" {
  description = "The port the load balancer should listen on for Couchbase Web Console requests."
  default     = 8091
}
