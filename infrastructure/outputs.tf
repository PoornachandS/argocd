
output "ingress_ip" {
  value       = module.google_networks.ingress_lb_ip
  description = "Ingress ip."
}

output "argo_ip" {
  value       = module.google_networks.argo_cd_ip
  description = "Ingress ip."
}
