output "couchbase_data_nodes_web_console_url" {
  value = "${module.load_balancer.alb_dns_name}:${var.data_nodes_load_balancer_port}"
}

output "couchbase_index_query_search_nodes_web_console_url" {
  value = "${module.load_balancer.alb_dns_name}:${var.index_query_search_nodes_load_balancer_port}"
}

output "sync_gateway_url" {
  value = "${module.load_balancer.alb_dns_name}:${var.sync_gateway_load_balancer_port}"
}

output "couchbase_data_nodes_cluster_asg_name" {
  value = module.couchbase_data_nodes.asg_name
}

output "couchbase_index_query_search_nodes_cluster_asg_name" {
  value = module.couchbase_index_query_search_nodes.asg_name
}

output "sync_gateway_cluster_asg_name" {
  value = module.sync_gateway.asg_name
}

