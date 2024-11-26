variable "compartment_ocid" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "availability_domain" {}
variable "my_public_ip_cidr" {}
variable "cluster_name" {}
variable "certmanager_email_address" {}
variable "region" {}
variable "arm_os_image_id" {}
variable "amd_os_image_id" {}
# variable "k3s_server_pool_size" {}
# variable "k3s_worker_pool_size" {}
# variable "k3s_extra_worker_node" {}
variable "expose_kubeapi" {}
variable "public_key_path" {}
variable "environment" {}
variable "cluster_domain_name" {}

module "k3s_cluster" {
  # k3s_version               = "v1.23.8+k3s2" # Fix kubectl exec failure
  # k3s_version               = "v1.24.4+k3s1" # Kubernetes version compatible with longhorn
  region                    = var.region
  availability_domain       = var.availability_domain
  tenancy_ocid              = var.tenancy_ocid
  compartment_ocid          = var.compartment_ocid
  my_public_ip_cidr         = var.my_public_ip_cidr
  cluster_name              = var.cluster_name
  environment               = var.environment
  certmanager_email_address = var.certmanager_email_address
  # k3s_server_pool_size      = var.k3s_server_pool_size
  # k3s_worker_pool_size      = var.k3s_worker_pool_size
  # k3s_extra_worker_node = var.k3s_extra_worker_node
  expose_kubeapi  = var.expose_kubeapi
  amd_os_image_id = var.amd_os_image_id
  arm_os_image_id = var.arm_os_image_id
  # ingress_controller        = "nginx"
  public_key_path = var.public_key_path
  # cluster_domain_name = var.cluster_domain_name
  source = "../"
}

output "k3s_servers_ips" {
  value = [for ip in tolist(module.k3s_cluster.k3s_servers_ips) : tostring(ip)]
}

output "k3s_workers_ips" {
  value = [for ip in tolist(module.k3s_cluster.k3s_workers_ips) : tostring(ip)]
}

output "public_lb_ip" {
  value = module.k3s_cluster.public_lb_ip[0].ip_address
}

resource "local_file" "hosts_ini" {
  filename = "hosts.ini"
  content  = <<-EOT
[lb]
${module.k3s_cluster.public_lb_ip[0].ip_address}

[lbhostname]
${var.cluster_domain_name}

[node0]
${[for ip in tolist(module.k3s_cluster.k3s_servers_ips) : tostring(ip)][0]}

[all]
%{for i in [for ip in tolist(module.k3s_cluster.k3s_servers_ips) : tostring(ip)][*]~}
${i}
%{endfor~}
%{for i in [for ip in tolist(module.k3s_cluster.k3s_workers_ips) : tostring(ip)][*]~}
${i}
%{endfor~}

[servers]
%{for i in slice([for ip in tolist(module.k3s_cluster.k3s_servers_ips) : tostring(ip)], 1, length(tolist(module.k3s_cluster.k3s_servers_ips)))~}
${i}
%{endfor~}

[workers]
%{for i in [for ip in tolist(module.k3s_cluster.k3s_workers_ips) : tostring(ip)][*]~}
${i}
%{endfor~}

EOT
}
