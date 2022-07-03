terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

data "digitalocean_ssh_key" "terraform" {
  name = "terraform"
}

resource "digitalocean_droplet" "turbo-umbrella" {
  image    = "ubuntu-20-04-x64"
  name     = "turbo-umbrella"
  region   = "blr1"
  size     = "s-1vcpu-1gb"
  ssh_keys = [data.digitalocean_ssh_key.terraform.id]
}

output "turbo-umbrella-ip-address" {
  value       = digitalocean_droplet.turbo-umbrella.ipv4_address
  description = "ipv4_address"
}

