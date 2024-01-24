terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.34.1"
    }
  }
}

variable "do_token" {
  description = "Digital Ocean API token"
  sensitive = true
}

variable "private_key_path" {
  description = "Private key for SSH access"
  sensitive = true
  default = "~/.ssh/unturned"
}

variable "public_key_path" {
  description = "Public key for SSH access"
  sensitive = true
  default = "~/.ssh/unturned.pub"
}

provider "digitalocean" {
  token = var.do_token

  spaces_access_id = var.do_spaces_access_id
  spaces_secret_key = var.do_spaces_secret_key
}

resource "digitalocean_ssh_key" "unturned_pub_key" {
  name = "unturned"
  public_key = file(var.public_key_path)
}

resource "digitalocean_droplet" "game_server" {
  image  = "debian-12-x64"
  size = "s-2vcpu-4gb"
  resize_disk = false
  name =  "game-server"
  region = "nyc1"
  monitoring = true
  ssh_keys = [
    digitalocean_ssh_key.unturned_pub_key.id
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.private_key_path)
    timeout = "2m"
  }
}

resource "digitalocean_firewall" "game_server" {
  name = "unturned-firewall"

  droplet_ids = [
    digitalocean_droplet.game_server.id
  ]

  inbound_rule {
    protocol = "tcp"
    port_range = "27015-27016"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol = "udp"
    port_range = "27015-27016"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol = "tcp"
    port_range = "8766"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol = "udp"
    port_range = "8766"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol = "tcp"
    port_range = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "tcp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol = "udp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

variable "do_spaces_access_id" {
  description = "Digital Ocean Spaces access ID"
  sensitive = true
  type = string
}

variable "do_spaces_secret_key" {
  description = "Digital Ocean Spaces secret key"
  sensitive = true
  type = string
}

resource "digitalocean_spaces_bucket" "unturned-backups" {
  name = "unturned-backups"
  region = "nyc3"
  acl = "private"
}

resource "digitalocean_spaces_bucket" "unturned-backups-hashes" {
  name = "${digitalocean_spaces_bucket.unturned-backups.name}-hashes"
  region = "nyc3"
  acl = "private"
}

resource "digitalocean_droplet_snapshot" "game_server" {
  name = "golden-image"
  droplet_id = digitalocean_droplet.game_server.id
}

resource "digitalocean_project" "unturned" {
  name = "Unturned"
  description = "A project to run an Unturned server in the cloud"
  purpose = "Service or API"
  environment = "Production"

  resources = [
    digitalocean_droplet.game_server.urn,
    digitalocean_spaces_bucket.unturned-backups.urn
  ]
}

output "backup_bucket_domain" {
  value = digitalocean_spaces_bucket.unturned-backups.bucket_domain_name
}

output "backup_hash_bucket_domain" {
  value = digitalocean_spaces_bucket.unturned-backups-hashes.bucket_domain_name
}

output "droplet_ip" {
  value = digitalocean_droplet.game_server.ipv4_address
}