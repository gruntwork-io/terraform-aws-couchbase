output "couchbase_web_console_url" {
  value = "http://${module.load_balancer.fully_qualified_domain_name}"
}

output "sync_gateway_url" {
  value = "http://${module.load_balancer.fully_qualified_domain_name}/${var.cluster_name}"
}

output "load_balancer_domain_name" {
  value = "${module.load_balancer.fully_qualified_domain_name}"
}

output "couchbase_cluster_asg_name" {
  value = "${module.couchbase.asg_name}"
}
