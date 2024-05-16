---
title: "Using Azure as a Dynamic DNS provider for your home server"
permalink: azure-ddns/
layout: post
tags:
  - programming
  - azure
  - terraform
  - cloud
  - DNS
  - DDNS
  - docker
---

When hosting services from your home, you will want to use a Dynamic DNS (DDNS) entry in order to map your ever-changing IP address to a hostname you can use to access those services. For instance, `home-server.mydomain.com` will point to your IPv4 (or IPv6) address. There are providers [noip](https://www.noip.com/) and [Duck DNS](https://www.duckdns.org/), but below is a method to use an Azure DNS zone and a script to update the IP on a regular basis. We will do this using Terraform and Docker containers.

---

## Terraform

I have [previously explained](2021-06-22-azure-cdn.md) how to get setup and running with Terraform, Github Workflows and Azure. We will be building on top of that post and ideas.

The first thing you will need is an Azure zone and A Record entry:

```hcl
resource "azurerm_dns_zone" "mydomain" {
  name                = "mydomain.com"
  resource_group_name = azurerm_resource_group.resource-group.name
}

resource "azurerm_dns_a_record" "home-server" {
  name                = "home-server"
  zone_name           = azurerm_dns_zone.mydomain.name
  resource_group_name = azurerm_resource_group.resource-group.name
  ttl                 = 300
  records             = ["1.2.3.4"]         # Updated by script
}
```

The IPv4 address will be updated in a script below. If you want to use IPv6, you will need an [`aaaa`](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_aaaa_record) record as well.

## Script

We now need a script which will run on a host within our home network to get our IP address and update the `a` record above. We will be using the [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) to update the record.

```shell
#!/bin/bash
set -ex

az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}

newIp="$(dig +short myip.opendns.com @resolver1.opendns.com)"
oldIp="$(az network dns record-set a show --resource-group ${AZURE_RESOURCE_GROUP} --zone-name ${AZURE_ZONE_NAME} --name ${AZURE_RECORD_NAME} -o tsv --query "aRecords[0].ipv4Address")"

if [[ "$newIp" == "$oldIp" ]]; then
    echo "IP has not been updated"
else
    echo "Updating IP to ${newIp}"
    az network dns record-set a remove-record --resource-group ${AZURE_RESOURCE_GROUP} --zone-name ${AZURE_ZONE_NAME} --record-set-name ${AZURE_RECORD_NAME} --ipv4-address ${oldIp} --keep-empty-record-set
    az network dns record-set a add-record --resource-group ${AZURE_RESOURCE_GROUP} --zone-name ${AZURE_ZONE_NAME} --record-set-name ${AZURE_RECORD_NAME} --ipv4-address ${newIp}
fi
```

There are some environment variables above which we will be injecting to the docker container below.

## Docker

First we will want a Dockerfile which wraps up the shell script:

```dockerfile
FROM mcr.microsoft.com/azure-cli

# To get the `dig` unix command
RUN apk add --no-cache bind-tools

ADD azddns.sh /

ENTRYPOINT /azddns.sh
```

We can then build and run this dockerfile:

```shell
docker build -t azddns .
docker run --rm \
    -e AZURE_CLIENT_ID=<insert client id> \
    -e AZURE_CLIENT_SECRET=<insert client secret> \
    -e AZURE_TENANT_ID=<insert tenant id> \
    -e AZURE_RESOURCE_GROUP=resource-group \
    -e AZURE_ZONE_NAME=mydomain.com \
    -e AZURE_RECORD_NAME=home-server \
    azddns
```

Running this docker run command should be done on a regular basis. This could be done with a cron job, or by using [ofelia](https://github.com/mcuadros/ofelia).

Here is the docker-compose entry:

```yaml
  azddns:
    build: azddns
    container_name: azddns
    environment:
      AZURE_CLIENT_ID: ${AZURE_CLIENT_ID}
      AZURE_CLIENT_SECRET: ${AZURE_CLIENT_SECRET}
      AZURE_TENANT_ID: ${AZURE_TENANT_ID}
      AZURE_RESOURCE_GROUP: "resource-group"
      AZURE_ZONE_NAME: "mydomain.com"
      AZURE_RECORD_NAME: "home-server"
```

And the entry in the ofelia config:

```ini
[job-exec "az ddns"]
schedule = @hourly
container = azddns
command = /azddns.sh
```

## Conclusion

And that's it! You could obviously alter this to use other cloud providers as well, but you now control one more aspect of your tech stack.
