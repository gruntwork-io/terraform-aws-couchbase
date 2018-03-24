# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name to use for the Load Balancer"
}

variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the Load Balancer"
}

variable "subnet_ids" {
  description = "The subnet IDs into which the Load Balancer should be deployed."
  type        = "list"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "allow_http_inbound_from_cidr_blocks" {
  description = "A list of IP addresses in CIDR notation from which the load balancer will allow incoming HTTP/HTTPS requests. At least one of var.allow_http_inbound_from_cidr_blocks or var.allow_http_inbound_from_security_groups must be non-empty or the Load Balancer won't allow any incoming requests!"
  type        = "list"
  default     = []
}

variable "allow_http_inbound_from_security_groups" {
  description = "A list of Security Group IDs from which the load balancer will allow incoming HTTP/HTTPS requests. At least one of var.allow_http_inbound_from_cidr_blocks or var.allow_http_inbound_from_security_groups must be non-empty or the Load Balancer won't allow any incoming requests!"
  type        = "list"
  default     = []
}

variable "default_target_group_arn" {
  description = "The ARN of a Target Group where all requests that don't match any Load Balancer Listener Rules will be sent. If you set this to empty string, we will send the requests to a \"black hole\" target group that always returns a 503, so we strongly recommend configuring this to be a target group that can instead return a reasonable 404 page."
  default     = ""
}

variable "internal" {
  description = "Set to true to make this an internal load balancer that is only accessible from within the VPC. Set to false to make it publicly accessible."
  default     = false
}

variable "enable_http2" {
  description = "Set to true to enable HTTP/2 on the load balancer."
  default     = true
}

variable "ip_address_type" {
  description = "The type of IP address to use on the load balancer. Must be one of: ipv4, dualstack."
  default     = "ipv4"
}

variable "tags" {
  description = "Custom tags to apply to the load balancer."
  type        = "map"
  default     = {}
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle."
  default     = 30
}

variable "include_http_listener" {
  description = "Set to true to include an HTTP listener with the Load Balancer."
  default     = true
}

variable "include_https_listener" {
  description = "Set to true to include an HTTPS listener with the Load Balancer. If set to true, you must also specify var.certificate_arn."
  default     = false
}

variable "certificate_arn" {
  description = "The ARN of an ACM or IAM TLS certificate to use with the Load Balancer's HTTPS listener. Only used if var.include_https_listener is true."
  default     = ""
}

variable "http_port" {
  description = "The port the Load Balancer should listen on for HTTP requests. Only used if var.include_http_listener is true."
  default     = 80
}

variable "https_port" {
  description = "The port the Load Balancer should listen on for HTTPS requests. Only used if var.include_https_listener is true."
  default     = 443
}

variable "route53_records" {
  description = "A list of DNS A records to create in Route 53 that point at this Load Balancer. Each item in the list should be an object with the keys 'domain' (the domain name to create) and 'zone_id' (the Route 53 Hosted Zone ID in which to create the DNS A record)."
  type        = "list"
  default     = []

  # Example:
  #
  # default = [
  #   {
  #     domain  = "foo.acme.com"
  #     zone_id = "Z1234ABCDEFG"
  #   }
  # ]
}
