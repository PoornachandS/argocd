terraform {
  required_providers {
	google = {
	  source = "hashicorp/google"
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
        "iap.googleapis.com",
        "firestore.googleapis.com"
    ])
  project = var.project_id
  service = each.value
}

module "google_networks" {
  source = "./networks"

  project_id = var.project_id
  region     = var.region
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  project_id                 = var.project_id
  name                       = "app-cluster"
  region                     = var.region
  zones                      = var.cluster_node_zones
  network                    = module.google_networks.network.name
  subnetwork                 = module.google_networks.subnet.name
  horizontal_pod_autoscaling = true
  enable_private_endpoint    = true
  enable_private_nodes       = true
  master_ipv4_cidr_block     = module.google_networks.cluster_master_ip_cidr_range
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
