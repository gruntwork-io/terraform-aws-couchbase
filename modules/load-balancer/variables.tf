# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name to use for the Load Balancer"
  type        = string
}

variable "http_listener_ports" {
  description = "A list of ports to listen on for HTTP requests."
  type        = list(number)
  # Example:
  #
  # default = [80]
}

variable "https_listener_ports_and_certs" {
  description = "A list of objects that define the ports to listen on for HTTPS requests. Each object should have the keys 'port' (the port number to listen on) and 'certificate_arn' (the ARN of an ACM or IAM TLS cert to use on this listener)."
  type = list(object({
    port            = number
    certificate_arn = string
  }))

  # Example:
  #
  # default = [
  #   {
  #     port            = 443
  #     certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  #   }
  # ]
}

variable "allow_inbound_from_cidr_blocks" {
  description = "A list of IP addresses in CIDR notation from which the load balancer will allow incoming HTTP/HTTPS requests."
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the Load Balancer"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs into which the Load Balancer should be deployed."
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "allow_inbound_from_security_groups" {
  description = "A list of Security Group IDs from which the load balancer will allow incoming HTTP/HTTPS requests. Any time you change this value, make sure to update var.allow_inbound_from_security_groups too!"
  type        = list(string)
  default     = []
}

variable "num_inbound_security_groups" {
  description = "The number of Security Group IDs in var.allow_inbound_from_security_groups. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.allow_inbound_from_cidr_blocks, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
  default     = 0
}

variable "default_target_group_arn" {
  description = "The ARN of a Target Group where all requests that don't match any Load Balancer Listener Rules will be sent. If you set this to empty string, we will send the requests to a \"black hole\" target group that always returns a 503, so we strongly recommend configuring this to be a target group that can instead return a reasonable 404 page."
  type        = string
  default     = null
}

variable "internal" {
  description = "Set to true to make this an internal load balancer that is only accessible from within the VPC. Set to false to make it publicly accessible."
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Set to true to enable HTTP/2 on the load balancer."
  type        = bool
  default     = true
}

variable "ip_address_type" {
  description = "The type of IP address to use on the load balancer. Must be one of: ipv4, dualstack."
  type        = string
  default     = "ipv4"
}

variable "tags" {
  description = "Custom tags to apply to the load balancer."
  type        = map(string)
  default     = {}
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle."
  type        = number
  default     = 30
}

variable "route53_records" {
  description = "A list of DNS A records to create in Route 53 that point at this Load Balancer. Each item in the list should be an object with the keys 'domain' (the domain name to create) and 'zone_id' (the Route 53 Hosted Zone ID in which to create the DNS A record)."
  type = list(object({
    domain  = string
    zone_id = string
  }))
  default = []

  # Example:
  #
  # default = [
  #   {
  #     domain  = "foo.acme.com"
  #     zone_id = "Z1234ABCDEFG"
  #   }
  # ]
}

