# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TARGET GROUP
# This will perform health checks on the servers and receive requests from the Listerers that match Listener Rules.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_target_group" "tg" {
  name                 = "${var.target_group_name}"
  port                 = "${var.port}"
  protocol             = "${var.protocol}"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check {
    port                = "traffic-port"
    protocol            = "${var.protocol}"
    interval            = "${var.health_check_interval}"
    path                = "${var.health_check_path}"
    timeout             = "${var.health_check_timeout}"
    healthy_threshold   = "${var.health_check_healthy_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
    matcher             = "${var.health_check_matcher}"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = "${var.stickiness_cookie_duration}"
    enabled         = "${var.enable_stickiness}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE LISTENER RULES
# These rules determine which requests get routed to the Target Group
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_listener_rule" "http_path" {
  count = "${var.create_http_listener_rule}"

  listener_arn = "${var.http_listener_arn}"
  priority     = "${var.http_listener_rule_priority}"

  action {
    target_group_arn = "${aws_alb_target_group.tg.arn}"
    type             = "forward"
  }

  condition = "${var.routing_condition}"
}

resource "aws_alb_listener_rule" "https_path" {
  count = "${var.create_https_listener_rule}"

  listener_arn = "${var.https_listener_arn}"
  priority     = "${var.https_listener_rule_priority}"

  action {
    target_group_arn = "${aws_alb_target_group.tg.arn}"
    type             = "forward"
  }

  condition = "${var.routing_condition}"
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH THE AUTO SCALING GROUP (ASG) TO THE LOAD BALANCER
# As a result, each EC2 Instance in the ASG will register with the Load Balancer, go through health checks, and be
# replaced automatically if it starts failing health checks.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_attachment" "attach" {
  autoscaling_group_name = "${var.asg_name}"
  alb_target_group_arn   = "${aws_alb_target_group.tg.arn}"
}
