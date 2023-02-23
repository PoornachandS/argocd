variable "project_id" {
  type = string
  description = "The ID of the project to create resources in"
}

variable "region" {
  type = string
  description = "The region to use"
}

variable "main_zone" {
  type = string
  description = "The zone to use as primary"
}

variable "cluster_node_zones" {
  type = list(string)
  description = "The zones where Kubernetes cluster worker nodes should be located"
}


variable "service_account" {
  type = string
  description = "The GCP service account"
}

variable "workload_manager_iam_roles" {
  type = any
  description = "workload manager sa roles"
  default = ["roles/datastore.owner", "roles/pubsub.publisher", "roles/artifactregistry.writer", "roles/pubsub.subscriber"]
}