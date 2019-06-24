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
  description = "The ID of the AMI to run in the cluster. This should be an AMI built from the Packer template under examples/couchbase-ami/couchbase.json. Set to null to use one of the example AMIs we have published publicly."
  type        = string
  default     = null
}

variable "couchbase_data_node_cluster_name" {
  description = "What to name the Couchbase data nodes cluster and all of its associated resources"
  type        = string
  default     = "couchbase-server-data"
}

variable "couchbase_index_query_search_node_cluster_name" {
  description = "What to name the Couchbase index/query/search nodes cluster and all of its associated resources"
  type        = string
  default     = "couchbase-server-search"
}

variable "sync_gateway_cluster_name" {
  description = "What to name the Sync Gateway cluster and all of its associated resources"
  type        = string
  default     = "couchbase-sync-gateway"
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to null to not associate a Key Pair."
  type        = string
  default     = null
}

variable "data_volume_device_name" {
  description = "The device name to use for the EBS Volume used for the data directory on Couchbase nodes."
  type        = string
  default     = "/dev/xvdh"
}

variable "data_volume_mount_point" {
  description = "The mount point (folder path) to use for the EBS Volume used for the data directory on Couchbase nodes."
  type        = string
  default     = "/couchbase-data"
}

variable "index_volume_device_name" {
  description = "The device name to use for the EBS Volume used for the index directory on Couchbase nodes."
  type        = string
  default     = "/dev/xvdi"
}

variable "index_volume_mount_point" {
  description = "The mount point (folder path) to use for the EBS Volume used for the index directory on Couchbase nodes."
  type        = string
  default     = "/couchbase-index"
}

variable "volume_owner" {
  description = "The OS user who should be made the owner of the data and index volume mount points."
  type        = string
  default     = "couchbase"
}

variable "data_nodes_load_balancer_port" {
  description = "The port the load balancer should listen on for Couchbase Web Console requests for the data nodes."
  type        = number
  default     = 8091
}

variable "index_query_search_nodes_load_balancer_port" {
  description = "The port the load balancer should listen on for Couchbase Web Console requests for the index, query, and search nodes."
  type        = number
  default     = 9091
}

variable "sync_gateway_load_balancer_port" {
  description = "The port the load balancer should listen on for Sync Gateway requests."
  type        = number
  default     = 4984
}

