terraform {
  required_providers {
	google = {
	  source = "hashicorp/google"
	}
    google-beta = {
      source = "hashicorp/google-beta"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11.0"
    }
  }
  required_version = ">= 0.13"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.main_zone
}

provider "google-beta" {
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

resource "google_project_service" "project_service" {
    for_each = toset([
        "iap.googleapis.com",
        "firestore.googleapis.com",
        "compute.googleapis.com",
        "pubsub.googleapis.com",
        "container.googleapis.com",
    ])
  project = var.project_id
  service = each.value
}

module "google_networks" {
  source = "./networks"

  project_id = var.project_id
  region     = var.region
  depends_on = [
    google_project_service.project_service
  ]
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  project_id                 = var.project_id
  name                       = "app-cluster"
  region                     = var.region
  zones                      = var.cluster_node_zones
  network                    = module.google_networks.network.name
  subnetwork                 = module.google_networks.subnet.name
  ip_range_pods              = module.google_networks.cluster_pods_ip_cidr_range
  ip_range_services          = module.google_networks.cluster_services_ip_cidr_range
  enable_vertical_pod_autoscaling = true
  horizontal_pod_autoscaling = true
  enable_private_endpoint    = true
  enable_private_nodes       = true
  master_ipv4_cidr_block     = module.google_networks.cluster_master_ip_cidr_range
  master_authorized_networks = [
      {
            cidr_block   = "${module.bastion.ip}/32"
            display_name = "bastion-host"
      }
  ]
  depends_on = [
    google_project_service.project_service
  ]
}

module "my-app-workload-identity" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "flask-pub-sub-svc"
  namespace  = "flask-pub-sub"
  project_id = var.project_id
  roles      = ["roles/datastore.owner", "roles/pubsub.publisher"]
}

module "bastion" {
  source = "./bastion"

  project_id   = var.project_id
  region       = var.region
  zone         = var.main_zone
  bastion_name = "app-cluster"
  network_name = module.google_networks.network.name
  subnet_name  = module.google_networks.subnet.name
  depends_on = [
    google_project_service.project_service
  ]
}

module "application" {
  source = "./application"

  project_id   = var.project_id
  depends_on = [
    google_project_service.project_service
  ]  
}
