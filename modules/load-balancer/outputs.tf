output "alb_arn" {
  value = aws_alb.lb.arn
}

output "alb_name" {
  value = aws_alb.lb.name
}

output "alb_dns_name" {
  value = aws_alb.lb.dns_name
}

output "domain_names" {
  value = aws_route53_record.load_balancer.*.fqdn
}

output "http_listener_arns" {
  value = zipmap(var.http_listener_ports, aws_alb_listener.http.*.arn)
}

data "template_file" "https_listener_ports" {
  count    = length(var.https_listener_ports_and_certs)
  template = var.https_listener_ports_and_certs[count.index]["port"]
}

output "https_listener_arns" {
  value = zipmap(
    data.template_file.https_listener_ports.*.rendered,
    aws_alb_listener.https.*.arn
  )
}

output "all_listener_arns" {
  value = merge(
    zipmap(var.http_listener_ports, aws_alb_listener.http.*.arn),
    zipmap(
      data.template_file.https_listener_ports.*.rendered,
      aws_alb_listener.https.*.arn
    )
  )
}

output "security_group_id" {
  value = aws_security_group.sg.id
}

