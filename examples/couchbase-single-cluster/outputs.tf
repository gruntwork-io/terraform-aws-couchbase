output "couchbase_web_console_url" {
  value = "http://${module.couchbase_load_balancer.alb_dns_name}"
}

output "sync_gateway_url" {
  value = "http://${module.sync_gateway_load_balancer.alb_dns_name}/${var.cluster_name}"
}

output "couchbase_cluster_asg_name" {
  value = "${module.couchbase.asg_name}"
}
