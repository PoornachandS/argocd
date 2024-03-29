locals {
  network_name                   = "poornachand-sounderrajan-kubernetes-cluster"
  subnet_name                    = "${google_compute_network.vpc.name}--subnet"
  cluster_master_ip_cidr_range   = "10.100.100.0/28"
  cluster_pods_ip_cidr_range     = "cluster-pods-ip"
  cluster_services_ip_cidr_range = "cluster-services-ip"
}

resource "google_compute_network" "vpc" {
  name                            = local.network_name
  auto_create_subnetworks         = false
  routing_mode                    = "GLOBAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "subnet" {
  name                     = local.subnet_name
  ip_cidr_range            = "10.10.0.0/16"
  region                   = var.region
  network                  = google_compute_network.vpc.name
  private_ip_google_access = true
  dynamic "secondary_ip_range" {
    for_each = var.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value
    }
  }
}

resource "google_compute_route" "egress_internet" {
  name             = "poornachand-sounderrajan-egress-internet"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc.name
  next_hop_gateway = "default-internet-gateway"
}

resource "google_compute_router" "router" {
  name    = "${local.network_name}-router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.vpc.name
}

resource "google_compute_router_nat" "nat_router" {
  name                               = "${google_compute_subnetwork.subnet.name}-nat-router"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnet.name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_global_address" "ingress_ip" {
  name = "poornachand-sounderrajan-flask"
}

resource "google_compute_global_address" "argo_ip" {
  name = "poornachand-sounderrajan-argo"
}
