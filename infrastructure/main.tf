terraform {
  required_providers {
	google = {
	  source = "hashicorp/google"
	}
    google-beta = {
      source = "hashicorp/google-beta"
    }
    /*
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.12.1"
    }
    */
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

/*
data "google_client_config" "default" {}


provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  client_certificate     = base64decode(module.gke.client_certificate)
  client_key             = base64decode(module.gke.client_key)
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}
*/

resource "google_project_service" "project_service" {
    for_each = toset([
        "iap.googleapis.com",
        "firestore.googleapis.com",
        "compute.googleapis.com",
        "pubsub.googleapis.com",
        "container.googleapis.com",
        "certificatemanager.googleapis.com",
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

// service account for iac
resource "google_service_account" "iac_sa" {
  account_id   = "iac-196"
  display_name = "GKE Bastion Service Account"
}

resource "google_project_iam_member" "iac-sa-bindng" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/iam.workloadIdentityUser",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.iac_sa.email}"
}

// Dedicated service account for the Bastion instance.
resource "google_service_account" "gke_sa" {
  account_id   = "ps-gke-sa"
  display_name = "GKE Bastion Service Account"
}

resource "google_project_iam_member" "gke-sa-bindng" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  project_id                 = var.project_id
  name                       = "poornachand-sounderrajan-app-cluster"
  region                     = var.region
  zones                      = var.cluster_node_zones
  network                    = module.google_networks.network.name
  subnetwork                 = module.google_networks.subnet.name
  ip_range_pods              = module.google_networks.cluster_pods_ip_cidr_range
  ip_range_services          = module.google_networks.cluster_services_ip_cidr_range
  service_account            = google_service_account.gke_sa.email
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

/*
module "my-app-workload-identity" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "flask-pub-sub-svc"
  namespace  = "flask-pub-sub"
  project_id = var.project_id
  roles      = ["roles/datastore.owner", "roles/pubsub.publisher"]
}
*/

resource "google_service_account" "workload_manager_sa" {
  project = var.project_id
  account_id   = "ps-flask-pub-sub"
  display_name = "Manager Service Account (GKE Workload Identity)."
}

resource "google_project_iam_member" "workload_manager_sa" {
  for_each = toset(var.workload_manager_iam_roles)
  project  = var.project_id
  role   = each.value
  member = "serviceAccount:${google_service_account.workload_manager_sa.email}"
}

# Allow Qpod manager [GKE Workload Identity] to use workload manager SA
resource "google_service_account_iam_member" "workload-manager-iam" {
  service_account_id = google_service_account.workload_manager_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[ps-flask-pub-sub/flask-pub-sub-svc]"
}

/*
resource "kubectl_manifest" "workload_manager_sa" {
  yaml_body = <<-EOF
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    annotations:
        iam.gke.io/gcp-service-account: ${google_service_account.workload_manager_sa.email}
    name: flask-pub-sub-svc
    namespace: flask-pub-sub
  EOF
}
*/

module "bastion" {
  source = "./bastion"

  project_id   = var.project_id
  region       = var.region
  zone         = var.main_zone
  bastion_name = "poornachand-sounderrajan"
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
