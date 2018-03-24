# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "target_group_name" {
  description = "The name to use for the Target Group"
}

variable "asg_name" {
  description = "The name of the ASG (ASG) in the servers are deployed"
}

variable "port" {
  description = "The port the servers are listening on for requests."
}

variable "health_check_path" {
  description = "The path to use for health check requests."
}

variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the Target Group"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "routing_condition" {
  description = "This variable defines the paths or domain names that will be routed to the servers. By default, we route all paths and domain names to the servers. To override this, you should pass in a list of maps, where each map has the keys field and values. See the Condition Blocks documentation for the syntax to use: https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html."
  type        = "list"

  default = [
    {
      field  = "path-pattern"
      values = ["*"]
    },
  ]
}

variable "protocol" {
  description = "The protocol to use to talk to the servers. Must be one of: HTTP, HTTPS."
  default     = "HTTP"
}

variable "deregistration_delay" {
  description = "The amount time for the Load Balancer to wait before changing the state of a deregistering server from draining to unused. The range is 0-3600 seconds."
  default     = 300
}

variable "health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of each server. Minimum value 5 seconds, Maximum value 300 seconds."
  default     = 30
}

variable "health_check_timeout" {
  description = "The amount of time, in seconds, during which no response from a server means a failed health check. Must be between 2 and 60 seconds."
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "The number of times the health check must pass before a server is considered healthy."
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "The number of times the health check must fail before a server is considered unhealthy."
  default     = 2
}

variable "health_check_matcher" {
  description = "The HTTP codes to use when checking for a successful response from a server. You can specify multiple comma-separated values (for example, \"200,202\") or a range of values (for example, \"200-299\")."
  default     = "200"
}

variable "create_http_listener_rule" {
  description = "Set to true to create a Listener Rule for the Load Balancer HTTP Listener. If this is set to true, you must also set var.http_listener_arn."
  default     = true
}

variable "http_listener_arn" {
  description = "The ARN of the HTTP Listener. Only used if var.create_http_listener_rule is true."
  default     = "replace-me"
}

variable "http_listener_rule_priority" {
  description = "The priority for the ALB HTTP listener rule. Only used if var.create_http_listener_rule is true."
  default     = 100
}

variable "create_https_listener_rule" {
  description = "Set to true to create a Listener Rule for the Load Balancer HTTPS Listener. If this is set to true, you must also set var.https_listener_arn."
  default     = false
}

variable "https_listener_arn" {
  description = "The ARN of the HTTPS Listener. Only used if var.create_https_listener_rule is true."
  default     = "replace-me"
}

variable "https_listener_rule_priority" {
  description = "The priority for the ALB HTTPS listener rule. Only used if var.create_https_listener_rule is true."
  default     = 100
}

variable "enable_stickiness" {
  description = "Set to true to enable stickiness, so a given user always gets routed to the same server. We recommend enabling this for the Couchbase Web Console."
  default     = false
}

variable "stickiness_cookie_duration" {
  description = "The time period, in seconds, during which requests from a client should be routed to the same target. After this time period expires, the load balancer-generated cookie is considered stale. The range is 1 second to 1 week (604800 seconds). Only used if var.enable_stickiness is true."
  default     = 86400                                                                                                                                                                                                                                                                                         # 1 day
}
