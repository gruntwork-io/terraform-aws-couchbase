output "alb_arn" {
  value = "${aws_alb.couchbase.arn}"
}

output "alb_name" {
  value = "${aws_alb.couchbase.name}"
}

output "alb_dns_name" {
  value = "${aws_alb.couchbase.dns_name}"
}

output "fully_qualified_domain_name" {
  value = "${var.create_route53_entry ? element(concat(aws_route53_record.load_balancer.*.fqdn, list("")), 0) : aws_alb.couchbase.dns_name}"
}

output "http_listener_arn" {
  value = "${element(concat(aws_alb_listener.http.*.arn, list("")), 0)}"
}

output "https_listener_arn" {
  value = "${element(concat(aws_alb_listener.https.*.arn, list("")), 0)}"
}

output "couchbase_server_target_group_arn" {
  value = "${element(concat(aws_alb_target_group.couchbase_server.*.arn, list("")), 0)}"
}

output "sync_gateway_target_group_arn" {
  value = "${element(concat(aws_alb_target_group.sync_gateway.*.arn, list("")), 0)}"
}

output "security_group_id" {
  value = "${aws_security_group.couchbase.id}"
}
