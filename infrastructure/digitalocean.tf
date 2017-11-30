# Set the variable value in *.tfvars file or using -var="do_token=..." CLI option
variable "do_token" {}
variable "do_key_id" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}

# Create a web server
resource "digitalocean_droplet" "adm" {
  # ssh_keys   = ["867702"]
  ssh_keys   = ["${var.do_key_id}"]
  image  = "ubuntu-16-04-x64"
  name   = "adm"
  region = "lon1"
  size   = "1gb"
}

# Create volumes
resource "digitalocean_volume" "volume" {
  count       = 3
  region      = "lon1"
  name        = "vol${count.index + 1}"
  size        = 20
  description = "volume participating to the Ceph cluster"
}

resource "digitalocean_droplet" "node" {
  ssh_keys   = ["867702"]
  count      = 3
  name       = "node${count.index + 1}"
  image      = "ubuntu-16-04-x64"
  size       = "1gb"
  region     = "lon1"
  volume_ids = ["${element(digitalocean_volume.volume.*.id, count.index + 1)}"]
}

output "adm_ip_addresses" {
  value = "adm: ${digitalocean_droplet.adm.ipv4_address}"
}

output "nodes_name" {
  value = ["${digitalocean_droplet.node.*.name}"]
}
output "nodes_ip_addresses" {
  value = ["${digitalocean_droplet.node.*.ipv4_address}"]
}
