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
  value = local.http_listener_arns
}

data "template_file" "https_listener_ports" {
  count    = length(var.https_listener_ports_and_certs)
  template = var.https_listener_ports_and_certs[count.index]["port"]
}

output "https_listener_arns" {
  value = local.https_listener_arns
}

output "all_listener_arns" {
  value = merge(local.http_listener_arns, local.https_listener_arns)
}

output "security_group_id" {
  value = aws_security_group.sg.id
}

locals {
  http_listener_arns  = { for listener in aws_alb_listener.http[*] : listener.port => listener.arn }
  https_listener_arns = { for listener in aws_alb_listener.https[*] : listener.port => listener.arn }
}
