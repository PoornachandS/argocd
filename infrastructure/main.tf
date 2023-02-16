terraform {
  required_providers {
	google = {
	  source = "hashicorp/google"
	  version = "3.51.0"
	}
  google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.main_zone
}

provider "google-beta" {
}

resource "google_project_service" "project_service" {
    for_each = toset([
        "iap.googleapis.com"
    ])
  project = var.project_id
  service = each.value
}

module "google_networks" {
  source = "./networks"

  project_id = var.project_id
  region     = var.region
}

module "google_kubernetes_cluster" {
  source = "./kubernetes_cluster"

  project_id                 = var.project_id
  region                     = var.region
  node_zones                 = var.cluster_node_zones
  service_account            = var.service_account
  network_name               = module.google_networks.network.name
  subnet_name                = module.google_networks.subnet.name
  master_ipv4_cidr_block     = module.google_networks.cluster_master_ip_cidr_range
  pods_ipv4_cidr_block       = module.google_networks.cluster_pods_ip_cidr_range
  services_ipv4_cidr_block   = module.google_networks.cluster_services_ip_cidr_range
  authorized_ipv4_cidr_block = "${module.bastion.ip}/32"
}

module "bastion" {
  source = "./bastion"

  project_id   = var.project_id
  region       = var.region
  zone         = var.main_zone
  bastion_name = "app-cluster"
  network_name = module.google_networks.network.name
  subnet_name  = module.google_networks.subnet.name
}

module "application" {
  source = "./application"

  project_id   = var.project_id  
}
