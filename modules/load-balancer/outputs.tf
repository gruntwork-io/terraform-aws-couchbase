output "alb_arn" {
  value = "${aws_alb.lb.arn}"
}

output "alb_name" {
  value = "${aws_alb.lb.name}"
}

output "alb_dns_name" {
  value = "${aws_alb.lb.dns_name}"
}

output "domain_names" {
  value = "${aws_route53_record.load_balancer.*.fqdn}"
}

output "http_listener_arn" {
  value = "${element(concat(aws_alb_listener.http.*.arn, list("")), 0)}"
}

output "https_listener_arn" {
  value = "${element(concat(aws_alb_listener.https.*.arn, list("")), 0)}"
}

output "security_group_id" {
  value = "${aws_security_group.sg.id}"
}
