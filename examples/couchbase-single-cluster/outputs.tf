output "load_balancer_domain_name" {
  value = "${module.load_balancer.fully_qualified_domain_name}"
}

output "couchbase_cluster_asg_name" {
  value = "${module.couchbase.asg_name}"
}
