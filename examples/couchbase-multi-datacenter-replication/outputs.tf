output "couchbase_primary_web_console_url" {
  value = "${module.load_balancer_primary.alb_dns_name}:${var.couchbase_load_balancer_port}"
}

output "couchbase_primary_cluster_asg_name" {
  value = module.couchbase_primary.asg_name
}

output "couchbase_replica_web_console_url" {
  value = "${module.load_balancer_replica.alb_dns_name}:${var.couchbase_load_balancer_port}"
}

output "couchbase_replica_cluster_asg_name" {
  value = module.couchbase_replica.asg_name
}

