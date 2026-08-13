output "aws_lb_controller_role_arn" {
  value = module.addons.aws_lb_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  value = module.addons.cluster_autoscaler_role_arn  
}


output "alb_controller_release" {
  value = helm_release.aws_load_balancer_controller.name
}

output "metrics_server_release" {
  value = helm_release.metrics_server.name
}

output "cluster_autoscaler_release" {
  value = helm_release.cluster_autoscaler.name
}

output "external_dns_role_arn" {
  value = module.addons.external_dns_role_arn
}

output "external_dns_release" {
  value = helm_release.external_dns.name
}