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

# https://developer.couchbase.com/documentation/mobile/1.5/guides/sync-gateway/nginx/index.html#aws-elastic-load-balancer-elb
variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle. Since Sync Gateway and Couchbase Lite can have long running connections for changes feeds, we recommend setting the idle timeout to the maximum value of 3,600 seconds (1 hour)."
  default     = 3600
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

variable "include_couchbase_server_target_group" {
  description = "Set to true to include a target group and health checks for Couchbase Servers."
  default     = true
}

variable "couchbase_server_port" {
  description = "The port your Couchbase Servers are listening on. Only used if var.include_couchbase_server_target_group is true."
  default     = 8091
}

variable "couchbase_server_protocol" {
  description = "The protocol the Load Balancer should use to talk to your Couchbase Servers. Must be one of: HTTP, HTTPS. Only used if var.include_couchbase_server_target_group is true."
  default     = "HTTP"
}

variable "couchbase_server_deregistration_delay" {
  description = "The amount time for the Load Balancer to wait before changing the state of a deregistering Couchbase Server from draining to unused. The range is 0-3600 seconds. Only used if var.include_couchbase_server_target_group is true."
  default     = 300
}

variable "couchbase_server_health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of Couchbase Servers. Minimum value 5 seconds, Maximum value 300 seconds. Only used if var.include_couchbase_server_target_group is true."
  default     = 30
}

variable "couchbase_server_health_check_path" {
  description = "The path to use for Couchbase Server health check requests. Only used if var.include_couchbase_server_target_group is true."
  default     = "/ui/index.html"
}

variable "couchbase_server_health_check_timeout" {
  description = "The amount of time, in seconds, during which no response from a Couchbase Server means a failed health check. Must be between 2 and 60 seconds. Only used if var.include_couchbase_server_target_group is true."
  default     = 5
}

variable "couchbase_server_health_check_healthy_threshold" {
  description = "The number of times the health check must pass before a Couchbase Server is considered healthy. Only used if var.include_couchbase_server_target_group is true."
  default     = 2
}

variable "couchbase_server_health_check_unhealthy_threshold" {
  description = "The number of times the health check must fail before a Couchbase Server is considered unhealthy. Only used if var.include_couchbase_server_target_group is true."
  default     = 2
}

variable "couchbase_server_health_check_matcher" {
  description = "The HTTP codes to use when checking for a successful response from a Couchbase Server. You can specify multiple comma-separated values (for example, \"200,202\") or a range of values (for example, \"200-299\"). Only used if var.include_couchbase_server_target_group is true."
  default     = "200"
}

variable "couchbase_server_listener_rule_priority_http" {
  description = "The priority for the Couchbase Server ALB HTTP listener rule. Only used if var.include_couchbase_server_target_group and var.include_http_listener is true."
  default     = 100
}

variable "couchbase_server_listener_rule_priority_https" {
  description = "The priority for the Couchbase Server ALB HTTPS listener rule. Only used if var.include_couchbase_server_target_group and var.include_https_listener is true."
  default     = 100
}

variable "couchbase_server_listener_rule_condition" {
  description = "The condition block for the Couchbase Server listener rules. This can be used to configure which paths and domain names on the Load Balancer are routed to the Couchbase Server. We ONLY recommend accessing the Couchbase Server Web Console (/ui) via a Load Balancer! Must contain an object with keys field and values. See the Condition Block documentation for details: https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html. Only used if var.include_couchbase_server_target_group is true."
  type        = "list"

  default = [
    {
      field  = "path-pattern"
      values = ["/ui/*"]
    },
  ]
}

variable "include_sync_gateway_target_group" {
  description = "Set to true to include a target group, health checks, and listener rules for Sync Gateway."
  default     = true
}

variable "sync_gateway_port" {
  description = "The port your Sync Gateway is listening on. Only used if var.include_sync_gateway_target_group is true."
  default     = 4984
}

variable "sync_gateway_protocol" {
  description = "The protocol the Load Balancer should use to talk to your Sync Gateway. Must be one of: HTTP, HTTPS. Only used if var.include_sync_gateway_target_group is true."
  default     = "HTTP"
}

variable "sync_gateway_deregistration_delay" {
  description = "The amount time for the Load Balancer to wait before changing the state of a deregistering Sync Gateway server from draining to unused. The range is 0-3600 seconds. Only used if var.include_sync_gateway_target_group is true."
  default     = 300
}

variable "sync_gateway_health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of Sync Gateway servers. Minimum value 5 seconds, Maximum value 300 seconds. Only used if var.include_sync_gateway_target_group is true."
  default     = 30
}

variable "sync_gateway_health_check_path" {
  description = "The path to use for Sync Gateway health check requests. Only used if var.include_sync_gateway_target_group is true."
  default     = "/"
}

variable "sync_gateway_health_check_timeout" {
  description = "The amount of time, in seconds, during which no response from a Sync Gateway means a failed health check. Must be between 2 and 60 seconds. Only used if var.include_sync_gateway_target_group is true."
  default     = 5
}

variable "sync_gateway_health_check_healthy_threshold" {
  description = "The number of times the health check must pass before a Sync Gateway is considered healthy. Only used if var.include_sync_gateway_target_group is true."
  default     = 2
}

variable "sync_gateway_health_check_unhealthy_threshold" {
  description = "The number of times the health check must fail before a Sync Gateway is considered unhealthy. Only used if var.include_sync_gateway_target_group is true."
  default     = 2
}

variable "sync_gateway_health_check_matcher" {
  description = "The HTTP codes to use when checking for a successful response from a Sync Gateway. You can specify multiple comma-separated values (for example, \"200,202\") or a range of values (for example, \"200-299\"). Only used if var.include_sync_gateway_target_group is true."
  default     = "200"
}

variable "sync_gateway_listener_rule_priority_http" {
  description = "The priority for the Sync Gateway ALB HTTP listener rule. Only used if var.include_sync_gateway_target_group and var.include_http_listener is true."
  default     = 110
}

variable "sync_gateway_listener_rule_priority_https" {
  description = "The priority for the Sync Gateway ALB HTTPS listener rule. Only used if var.include_sync_gateway_target_group and var.include_https_listener is true."
  default     = 110
}

variable "sync_gateway_listener_rule_condition" {
  description = "The condition block for the Sync Gateway listener rule. This can be used to configure which paths and domain names on the Load Balancer are routed to the Sync Gateway. Must contain an object with keys field and values. See the Condition Block documentation for details: https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html. Only used if var.include_sync_gateway_target_group is true."
  type        = "list"

  default = [
    {
      field  = "path-pattern"
      values = ["*"]
    },
  ]
}

variable "create_route53_entry" {
  description = "If set to true, create a DNS A record in Route 53 for var.domain_name."
  default     = false
}

variable "route53_hosted_zone_id" {
  description = "The ID of the Route 53 Hosted Zone in which to create a DNS A record that points to this Load Balancer. Only used if var.create_route53_entry is true."
  default     = "replace-me"
}

variable "domain_name" {
  description = "The domain name to use in the DNS A record in Route 53 that points to this Load Balancer. Only used if var.create_route53_entry is true."
  default     = "replace-me"
}
