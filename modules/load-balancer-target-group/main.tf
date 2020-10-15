# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  # This module is now only being tested with Terraform 0.13.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.13.x code.
  required_version = ">= 0.12.26"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TARGET GROUP
# This will perform health checks on the servers and receive requests from the Listerers that match Listener Rules.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_target_group" "tg" {
  name                 = var.target_group_name
  port                 = var.port
  protocol             = var.protocol
  vpc_id               = var.vpc_id
  deregistration_delay = var.deregistration_delay

  health_check {
    port                = "traffic-port"
    protocol            = var.protocol
    interval            = var.health_check_interval
    path                = var.health_check_path
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = var.stickiness_cookie_duration
    enabled         = var.enable_stickiness
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE LISTENER RULES
# These rules determine which requests get routed to the Target Group
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_listener_rule" "http_path" {
  count = var.num_listener_arns

  listener_arn = element(var.listener_arns, count.index)
  priority     = var.listener_rule_starting_priority + count.index

  action {
    target_group_arn = aws_alb_target_group.tg.arn
    type             = "forward"
  }

  dynamic "condition" {
    for_each = [for condition in var.routing_condition : condition.values if condition.field == "path-pattern"]
    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in var.routing_condition : condition.values if condition.field == "host-header"]
    content {
      host_header {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in var.routing_condition : condition.values if condition.field == "http-request-method"]
    content {
      http_request_method {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = [for condition in var.routing_condition : condition.values if condition.field == "source-ip"]
    content {
      source_ip {
        values = condition.value
      }
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH THE AUTO SCALING GROUP (ASG) TO THE LOAD BALANCER
# As a result, each EC2 Instance in the ASG will register with the Load Balancer, go through health checks, and be
# replaced automatically if it starts failing health checks.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_attachment" "attach" {
  autoscaling_group_name = var.asg_name
  alb_target_group_arn   = aws_alb_target_group.tg.arn
}

