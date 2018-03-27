output "couchbase_web_console_url" {
  value = "${module.couchbase_load_balancer.alb_dns_name}"
}

output "sync_gateway_url" {
  value = "${module.sync_gateway_load_balancer.alb_dns_name}"
}

output "couchbase_cluster_asg_name" {
  value = "${module.couchbase.asg_name}"
}
