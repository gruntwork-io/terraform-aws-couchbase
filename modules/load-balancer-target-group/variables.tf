# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "target_group_name" {
  description = "The name to use for the Target Group"
  type        = string
}

variable "asg_name" {
  description = "The name of the ASG (ASG) in the servers are deployed"
  type        = string
}

variable "port" {
  description = "The port the servers are listening on for requests."
  type        = number
}

variable "listener_arns" {
  description = "The ARNs of ALB listeners to which Listener Rules that route to this Target Group should be added."
  type        = list(string)
}

variable "num_listener_arns" {
  description = "The number of ARNs in var.listener_arns. We should be able to compute this automatically, but due to a Terraform limitation, if there are any dynamic resources in var.listener_arns, then we won't be able to: https://github.com/hashicorp/terraform/pull/11482"
  type        = number
}

variable "listener_rule_starting_priority" {
  description = "The starting priority for the Listener Rules"
  type        = number
}

variable "health_check_path" {
  description = "The path to use for health check requests."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the Target Group"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "routing_condition" {
  description = "This variable defines the paths or domain names that will be routed to the servers. By default, we route all paths and domain names to the servers. To override this, you should pass in a list of maps, where each map has the keys field and values. See the Condition Blocks documentation for the syntax to use: https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html."
  type = list(object({
    field  = string
    values = list(string)
  }))

  default = [
    {
      field  = "path-pattern"
      values = ["*"]
    },
  ]
}

variable "protocol" {
  description = "The protocol to use to talk to the servers. Must be one of: HTTP, HTTPS."
  type        = string
  default     = "HTTP"
}

variable "deregistration_delay" {
  description = "The amount time for the Load Balancer to wait before changing the state of a deregistering server from draining to unused. The range is 0-3600 seconds."
  type        = number
  default     = 300
}

variable "health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of each server. Minimum value 5 seconds, Maximum value 300 seconds."
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "The amount of time, in seconds, during which no response from a server means a failed health check. Must be between 2 and 60 seconds."
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "The number of times the health check must pass before a server is considered healthy."
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "The number of times the health check must fail before a server is considered unhealthy."
  type        = number
  default     = 2
}

variable "health_check_matcher" {
  description = "The HTTP codes to use when checking for a successful response from a server. You can specify multiple comma-separated values (for example, \"200,202\") or a range of values (for example, \"200-299\")."
  type        = string
  default     = "200"
}

variable "enable_stickiness" {
  description = "Set to true to enable stickiness, so a given user always gets routed to the same server. We recommend enabling this for the Couchbase Web Console."
  type        = bool
  default     = false
}

variable "stickiness_cookie_duration" {
  description = "The time period, in seconds, during which requests from a client should be routed to the same target. After this time period expires, the load balancer-generated cookie is considered stale. The range is 1 second to 1 week (604800 seconds). Only used if var.enable_stickiness is true."
  type        = number
  default     = 86400 # 1 day
}

