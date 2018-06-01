# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_DEFAULT_REGION

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "ami_id" {
  description = "The ID of the AMI to run in the cluster. This should be an AMI built from the Packer template under examples/couchbase-ami/couchbase.json. Leave blank to use one of the example AMIs we have published publicly."
  default     = ""
}

variable "cluster_name" {
  description = "What to name the Couchbase cluster and all of its associated resources"
  default     = "couchbase-server"
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair."
  default     = ""
}

variable "data_volume_device_name" {
  description = "The device name to use for the EBS Volume used for the data directory on Couchbase nodes."
  default     = "/dev/xvdh"
}

variable "data_volume_mount_point" {
  description = "The mount point (folder path) to use for the EBS Volume used for the data directory on Couchbase nodes."
  default     = "/couchbase-data"
}

variable "index_volume_device_name" {
  description = "The device name to use for the EBS Volume used for the index directory on Couchbase nodes."
  default     = "/dev/xvdi"
}

variable "index_volume_mount_point" {
  description = "The mount point (folder path) to use for the EBS Volume used for the index directory on Couchbase nodes."
  default     = "/couchbase-index"
}

variable "volume_owner" {
  description = "The OS user who should be made the owner of the data and index volume mount points."
  default     = "couchbase"
}

variable "couchbase_load_balancer_port" {
  description = "The port the load balancer should listen on for Couchbase Web Console requests."
  default     = 8091
}

variable "sync_gateway_load_balancer_port" {
  description = "The port the load balancer should listen on for Sync Gateway requests."
  default     = 4984
}
