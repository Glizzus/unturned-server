terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.5.0"
    }
  }
}

variable "do_token" {
  description = "Digital Ocean API token"
  sensitive = true
}

variable "private_key" {
  description = "Private key for SSH access"
  sensitive = true
}

variable "public_key" {
  description = "Public key for SSH access"
  sensitive = true
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "unturned_pub_key" {
  name = "unturned"
  public_key = file(var.public_key)
}

resource "digitalocean_droplet" "game_server" {
  image  = "debian-12-x64"
  size = "s-2vcpu-4gb"
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
    private_key = file(var.private_key)
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
    digitalocean_droplet.game_server.urn
  ]
}
