
output "ingress_ip" {
  value       = module.google_networks.ingress_lb_ip
  description = "Ingress ip."
}
