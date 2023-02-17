variable "project_id" {
  type = string
  description = "The project ID to host the network in"
}

variable "region" {
  type = string
  description = "The region to use"
}

variable "secondary_ip_ranges" {
  description = "secondary ip ranges to apply"
  type        = map(string)
  default     = {
    "cluster-pods-ip" = "10.101.0.0/16",
    "cluster-services-ip" = "10.102.0.0/16"
  }
}