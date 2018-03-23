# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN THE LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb" "couchbase" {
  name               = "${var.name}"
  load_balancer_type = "application"
  idle_timeout       = "${var.idle_timeout}"

  internal        = "${var.internal}"
  security_groups = ["${aws_security_group.couchbase.id}"]
  subnets         = ["${var.subnet_ids}"]

  enable_http2    = "${var.enable_http2}"
  ip_address_type = "${var.ip_address_type}"

  tags = "${var.tags}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE HTTP AND HTTPS LISTENERS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_listener" "http" {
  count = "${var.include_http_listener}"

  load_balancer_arn = "${aws_alb.couchbase.arn}"
  port              = "${var.http_port}"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${length(var.default_target_group_arn) > 0 ? var.default_target_group_arn : element(concat(aws_alb_target_group.black_hole.*.arn, list("")), 0)}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "https" {
  count = "${var.include_https_listener}"

  load_balancer_arn = "${aws_alb.couchbase.arn}"
  port              = "${var.https_port}"
  protocol          = "HTTPS"
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    target_group_arn = "${length(var.default_target_group_arn) > 0 ? var.default_target_group_arn : element(concat(aws_alb_target_group.black_hole.*.arn, list("")), 0)}"
    type             = "forward"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TARGET GROUP AND LOAD BALANCER RULES FOR COUCHBASE SERVER
# Note that we only recommend creating Load Balancer Rules for the Couchbase Web Console. Using a Load Balancer with
# any of the Couchbase APIs is NOT recommended: https://blog.couchbase.com/couchbase-101-q-and-a/
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_target_group" "couchbase_server" {
  count = "${var.include_couchbase_server_target_group}"

  name                 = "${var.name}-server"
  port                 = "${var.couchbase_server_port}"
  protocol             = "${var.couchbase_server_protocol}"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "${var.couchbase_server_deregistration_delay}"

  health_check {
    port                = "traffic-port"
    interval            = "${var.couchbase_server_health_check_interval}"
    path                = "${var.couchbase_server_health_check_path}"
    protocol            = "${var.couchbase_server_protocol}"
    timeout             = "${var.couchbase_server_health_check_timeout}"
    healthy_threshold   = "${var.couchbase_server_health_check_healthy_threshold}"
    unhealthy_threshold = "${var.couchbase_server_health_check_unhealthy_threshold}"
    matcher             = "${var.couchbase_server_health_check_matcher}"
  }
}

resource "aws_alb_listener_rule" "couchbase_server_http" {
  count = "${var.include_couchbase_server_target_group * var.include_http_listener}"

  listener_arn = "${element(concat(aws_alb_listener.http.*.arn, list("")), 0)}"
  priority     = "${var.couchbase_server_listener_rule_priority_http}"

  action {
    target_group_arn = "${element(concat(aws_alb_target_group.couchbase_server.*.arn, list("")), 0)}"
    type             = "forward"
  }

  condition = "${var.couchbase_server_listener_rule_condition}"
}

resource "aws_alb_listener_rule" "couchbase_server_https" {
  count = "${var.include_couchbase_server_target_group * var.include_https_listener}"

  listener_arn = "${element(concat(aws_alb_listener.https.*.arn, list("")), 0)}"
  priority     = "${var.couchbase_server_listener_rule_priority_https}"

  action {
    target_group_arn = "${element(concat(aws_alb_target_group.couchbase_server.*.arn, list("")), 0)}"
    type             = "forward"
  }

  condition = "${var.couchbase_server_listener_rule_condition}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A TARGET GROUP AND LOAD BALANCER RULES FOR SYNC GATEWAY
# This can be used to route traffic across all Sync Gateway servers. Note that we only expose the normal Sync Gateway
# interface port and NOT the admin port, as the admin port allows admin access to ALL Couchbase data, and should only
# be accessible from localhost.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_target_group" "sync_gateway" {
  count = "${var.include_sync_gateway_target_group}"

  name                 = "${var.name}-sync-gateway"
  port                 = "${var.sync_gateway_port}"
  protocol             = "${var.sync_gateway_protocol}"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "${var.sync_gateway_deregistration_delay}"

  health_check {
    port                = "traffic-port"
    interval            = "${var.sync_gateway_health_check_interval}"
    path                = "${var.sync_gateway_health_check_path}"
    protocol            = "${var.sync_gateway_protocol}"
    timeout             = "${var.sync_gateway_health_check_timeout}"
    healthy_threshold   = "${var.sync_gateway_health_check_healthy_threshold}"
    unhealthy_threshold = "${var.sync_gateway_health_check_unhealthy_threshold}"
    matcher             = "${var.sync_gateway_health_check_matcher}"
  }
}

resource "aws_alb_listener_rule" "sync_gateway_http" {
  count = "${var.include_sync_gateway_target_group * var.include_http_listener}"

  listener_arn = "${element(concat(aws_alb_listener.http.*.arn, list("")), 0)}"
  priority     = "${var.sync_gateway_listener_rule_priority_http}"

  action {
    target_group_arn = "${element(concat(aws_alb_target_group.sync_gateway.*.arn, list("")), 0)}"
    type             = "forward"
  }

  condition = "${var.sync_gateway_listener_rule_condition}"
}

resource "aws_alb_listener_rule" "sync_gateway_https" {
  count = "${var.include_sync_gateway_target_group * var.include_https_listener}"

  listener_arn = "${element(concat(aws_alb_listener.https.*.arn, list("")), 0)}"
  priority     = "${var.sync_gateway_listener_rule_priority_https}"

  action {
    target_group_arn = "${element(concat(aws_alb_target_group.sync_gateway.*.arn, list("")), 0)}"
    type             = "forward"
  }

  condition = "${var.sync_gateway_listener_rule_condition}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A "BLACK HOLE" TARGET GROUP
# The Load Balancer requires "default route" for requests that don't match any listener rules. We let the user the
# default target group for these routes via var.default_target_group_arn, but if the user doesn't specify one, we
# still need to send the requests somewhere. The solution is to optionally create this "black hole" target group that
# has no servers registered in it.
#
# Any requests that go to this target group will get a 503, so this is a poor user experience, and we recommend most
# users specify var.default_target_group_arn instead. Ideally, var.default_target_group_arn points to something that
# can serve up a reasonable 404 page.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb_target_group" "black_hole" {
  count = "${length(var.default_target_group_arn) == 0 ? 1 : 0}"

  name     = "${var.name}-black-hole"
  protocol = "HTTP"
  port     = 12345
  vpc_id   = "${var.vpc_id}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO CONTROL TRAFFIC THAT CAN GO IN AND OUT OF THE LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "couchbase" {
  name   = "${var.name}-lb"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.couchbase.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_http_inbound_from_cidr_blocks" {
  count             = "${var.include_http_listener && length(var.allow_http_inbound_from_cidr_blocks) > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = "${var.http_port}"
  to_port           = "${var.http_port}"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.couchbase.id}"
  cidr_blocks       = ["${var.allow_http_inbound_from_cidr_blocks}"]
}

resource "aws_security_group_rule" "allow_http_inbound_from_security_groups" {
  count                    = "${var.include_http_listener && length(var.allow_http_inbound_from_security_groups) > 0 ? length(var.allow_http_inbound_from_security_groups) : 0}"
  type                     = "ingress"
  from_port                = "${var.http_port}"
  to_port                  = "${var.http_port}"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.couchbase.id}"
  source_security_group_id = "${element(var.allow_http_inbound_from_security_groups, count.index)}"
}

resource "aws_security_group_rule" "allow_https_inbound_from_cidr_blocks" {
  count             = "${var.include_http_listener && length(var.allow_http_inbound_from_cidr_blocks) > 0 ? 1 : 0}"
  type              = "ingress"
  from_port         = "${var.https_port}"
  to_port           = "${var.https_port}"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.couchbase.id}"
  cidr_blocks       = ["${var.allow_http_inbound_from_cidr_blocks}"]
}

resource "aws_security_group_rule" "allow_https_inbound_from_security_groups" {
  count                    = "${var.include_http_listener && length(var.allow_http_inbound_from_security_groups) > 0 ? length(var.allow_http_inbound_from_security_groups) : 0}"
  type                     = "ingress"
  from_port                = "${var.https_port}"
  to_port                  = "${var.https_port}"
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.couchbase.id}"
  source_security_group_id = "${element(var.allow_http_inbound_from_security_groups, count.index)}"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN OPTIONAL DNS A RECORD IN ROUTE 53 POINTING AT THE LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_route53_record" "load_balancer" {
  count   = "${var.create_route53_entry}"
  name    = "${var.domain_name}"
  zone_id = "${var.route53_hosted_zone_id}"
  type    = "A"

  alias {
    name                   = "${aws_alb.couchbase.dns_name}"
    zone_id                = "${aws_alb.couchbase.zone_id}"
    evaluate_target_health = true
  }
}
