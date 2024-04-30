---
title:  "Using GCP free tier VM for uptime and health checks"
permalink: gcp-free-tier-watcher/
layout: post
tags:
  - programming
  - web
  - cloud
  - GCP
  - terraform
  - docker
  - self host
---

![Uptime Kuma](/content/posts/assets/pluto-uptime.png)

I [host a bunch of services](<../Self Hosting/What I Self Host.md>) on a server in my house, which I call Jupiter ([Why "Jupiter"?](<../Self Hosting/Device Naming.md>)). I also have cron jobs on the server which run important things like [backups of my documents and photos/videos](<../Self Hosting/Backups.md>). I need to know (immediately) if:
- Jupiter goes down
- One of the services on Jupiter is not running
- One of the cron jobs on Jupiter has not run on time or successfully

Running health checks or down-detectors on Jupiter would not be wise as they might not notify me if the whole server was to go down. So I need a 3rd party, outside of my home network, to keep an eye on everything. The watcher would be very compute un-intensive, only hosting a couple of small docker images which don't generally do much, and so I went on the hunt for the cheapest, tiniest VMs/VPSs I could find:
- **Azure** - B1ls (1vCPU, 512MB memory, 4GB storage) = ~£3.50pm
- **GCP** - e2-micro (2vCPU, 1GB memory, 10GB storage) = ~£6pm
- **AWS** - t4g.nano (2vCPU, 512MB memory, 10GB storage) = ~£2pm
- **Hetzner** - CX11 (1vCPU, 2GB memory, 20GB storage) = ~£3.50pm
- **OVH** - Starter (1vCPU, 2GB memory, 20GB storage) = ~£3pm

These costs are all rough estimates, and don't take into account things like paying for reserved capacity up-front, additional costs for public IPs & egress traffic costs. But they give a good indicator that at the very least, it would be a cost of around £3pm. 

But then I remembered that some of the bigger cloud providers offer "always free" tiers. And they have compute resources as part of that offering:
- **[Azure Free Tier]()** - Azure App Service (10 apps with 1GB free)
- **[AWS Free Tier](https://aws.amazon.com/free)** - AWS Lambda (1 Million requests per month)
- **[Oracle Cloud Free Tier](https://www.oracle.com/uk/cloud/free/)** - VM (1/8 OCPU, 1GB memory)
- **[GCP Free Tier](https://cloud.google.com/free)** - VM (e2-micro, 30GB storage + free external IP)

I attempted to use Azure's offering at first (as I already use Azure to host my backups, DNS, website etc.) and the terraform for this attempt can be [found here](https://github.com/jmc265/personal-cloud/blob/6e3c8450ec31cc8fdcd3eec84b0ba02d9823b724/.cloud/app_service.tf). The service did boot up, but I ran into a number of issues with web sockets and what I believe to be CPU resource constraints on the host which meant that even this simple app took ages to load. Of the other cloud providers, GCP looked the best to me, especially because of the mention in their docs of a free external IP. So I believe I can host everything I need to in GCP, absolutely free.

## Terraform
As with my other cloud usage, everything is controlled by Terraform, making reproducing the build simple. I won't detail the steps for getting setup with GCP and Terraform cloud, as that is detailed elsewhere (e.g. [here](https://cloud.google.com/docs/terraform)).

Once we have setup the authorisation and provider in Terraform, we need to define our compute instance. I decided to name the VM instance "pluto" due to its tiny size:

```hcl
resource "google_compute_instance" "pluto" {
	name = "pluto"
	machine_type = "e2-micro"
	can_ip_forward = "true"
	allow_stopping_for_update = "true"

	boot_disk {
		initialize_params {
			type = "pd-standard"
			image = data.google_compute_image.cos.self_link
		}
	}

	# This allows for an external IP address
	network_interface {
		network = "default"
		access_config {
		}
	}

	scheduling {
		automatic_restart = true
	}
}

# https://cloud.google.com/compute/docs/images/os-details
data "google_compute_image" "cos" {
	project = "cos-cloud"
	family = "cos-97-lts"
}
```

I've elected to use GCP's Container-Optimized OS (COS) which (amongst other things) comes with docker already installed.

As the boot disk only takes up 10GB, and GCP offers 30GB per month for free, I also create a 20GB attached disk to store the Docker volumes:

```hcl
resource "google_compute_instance" "pluto" {
	...
	lifecycle {
		ignore_changes = [attached_disk]
	}
}

resource "google_compute_disk" "default" {
	name = "disk-app-server"
	type = "pd-standard"
	zone = "${var.gcp_region}-b"
	size = 20
}

resource "google_compute_attached_disk" "default" {
	disk = google_compute_disk.default.id
	instance = google_compute_instance.pluto.id
}
```

Finally, there need to be some firewall settings to allow HTTP(S) traffic through to the instance:

```hcl
resource "google_compute_instance" "pluto" {
	...
	tags = ["ssh", "http-server", "https-server"]
	...
}

resource "google_compute_firewall" "http-server" {
	name = "default-allow-http"
	network = "default"
	allow {
		protocol = "tcp"
		ports = ["80"]
	}
	source_ranges = ["0.0.0.0/0"]
	target_tags = ["http-server"]
}

resource "google_compute_firewall" "https-server" {
	name = "default-allow-https"
	network = "default"
	allow {
		protocol = "tcp"
		ports = ["443"]
	}
	source_ranges = ["0.0.0.0/0"]
	target_tags = ["https-server"]
}
```

This Terraform gets us our very own (free!) e2-micro instance with attached disk. But we don't yet have any apps running on it.

## Docker (compose)
I was going to go down the route of using [cloud-init](https://cloudinit.readthedocs.io/en/latest/) to get the e2-micro up and running with my docker containers, but it turns out someone has already wrapped up all of that into a handy Terraform module called [container-server](https://registry.terraform.io/modules/christippett/container-server/cloudinit/latest). It also handily includes Traefik with Let's Encrypt certificate generation. Everything I need!

First I wrote my docker-compose to include the 2 services I wanted to host: [Uptime Kuma](https://github.com/louislam/uptime-kuma) and [Healthchecks](https://healthchecks.io/):

```yaml
version: "3"

services:
	uptime-kuma:
		image: louislam/uptime-kuma
		container_name: uptime-kuma
		restart: unless-stopped
		volumes:
			- ${DOCKER_APP_DATA}/uptime-kuma:/app/data
		labels:
			- traefik.enable=true
			- traefik.http.routers.uptime.rule=Host(`uptime.${INET_DOMAIN}`)
			- traefik.http.routers.uptime.entrypoints=websecure
			- traefik.http.routers.uptime.tls=true
			- traefik.http.routers.uptime.tls.certresolver=letsencrypt
			- traefik.http.services.uptime.loadBalancer.server.port=3001

	healthchecks:
		image: linuxserver/healthchecks
		container_name: healthchecks
		environment:
			- TZ=Europe/London
			- SITE_ROOT=https://healthchecks.${INET_DOMAIN}
			- SITE_NAME=Health Checks
			- SUPERUSER_EMAIL=${ADMIN_EMAIL}
			- SUPERUSER_PASSWORD=${ADMIN_PASSWORD}
			- APPRISE_ENABLED=True
			- PING_BODY_LIMIT=100000
			- DEBUG=False
		volumes:
			- ${DOCKER_APP_DATA}/healthchecks:/config
		restart: unless-stopped
		labels:
			- traefik.enable=true
			- traefik.http.routers.healthchecks.rule=Host(`healthchecks.${INET_DOMAIN}`)
			- traefik.http.routers.healthchecks.entrypoints=websecure
			- traefik.http.routers.healthchecks.tls=true
			- traefik.http.routers.healthchecks.tls.certresolver=letsencrypt

networks:
	default:
		external:
			name: web
```

And finally, using the container-server module in Terraform:

```hcl
module "container-server" {
	source = "christippett/container-server/cloudinit"
	version = "~> 1.2"
	domain = "pluto.${var.root_domain}"
	email = var.email_address
	
	files = [
		{
			filename = "docker-compose.yaml"
			content = filebase64("${path.module}/../pluto/docker-compose.yaml")
		}
	]

	env = {
		TRAEFIK_API_DASHBOARD = false
		DOCKER_APP_DATA = "/run/app"
		ADMIN_EMAIL = var.email_address
		ADMIN_PASSWORD = var.admin_password
		INET_DOMAIN = "pluto.${var.root_domain}"
	}

	# extra cloud-init config provided to setup + format persistent disk
	cloudinit_part = [{
		content_type = "text/cloud-config"
		content = local.cloudinit_disk
	}]
}

# prepare persistent disk
locals {
	cloudinit_disk = <<EOT
#cloud-config
bootcmd:
- fsck.ext4 -tvy /dev/sdb || mkfs.ext4 /dev/sdb
- mkdir -p /run/app
- mount -o defaults -t ext4 /dev/sdb /run/app
EOT
}
```

All of this code can be found in my GitHub repo:
- [Terraform](https://github.com/jmc265/personal-cloud/blob/main/.cloud/pluto-vm.tf)
- [Docker Compose](https://github.com/jmc265/personal-cloud/blob/main/pluto/docker-compose.yaml)

## Configuration
### Uptime Kuma
I now host 2 instances of Uptime Kuma:
- On Pluto (VM) which pings:
	- Jupiter's DNS entry
	- Jupiter's exposed HTTP(S) services
	- My domains (jeeb\[.co\].uk, james.cx)
- On Jupiter (home service) which pings:
	- Pluto's DNS entry
	- Pluto's exposed HTTP(S) services

As they are watching each other, I will now get a notification if one of the severs/services goes down.
### Healthchecks
My cron jobs running on Jupiter now all ping the Healthchecks service running on Pluto. You can see an example of this [here](https://github.com/jmc265/personal-cloud/blob/main/jupiter/jeeb-uk/crontab). Healthchecks acts in a dead-man-switch way and will notify me if anything doesn't report in correctly.