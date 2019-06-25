output "couchbase_web_console_url" {
  value = "${module.load_balancer.domain_names[0]}:${var.couchbase_load_balancer_port}"
}

output "sync_gateway_url" {
  value = "${module.load_balancer.domain_names[0]}:${var.sync_gateway_load_balancer_port}"
}

output "couchbase_cluster_asg_name" {
  value = module.couchbase.asg_name
}

