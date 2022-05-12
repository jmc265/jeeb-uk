# Jeeb.uk

## Resources:

* Logo font: .SF NS Display Condensed
* [Website logos](https://iconmonstr.com)

## Github flows

* [Azure Actions Documentation](https://github.com/marketplace/actions/azure-cli-action)

## Certificates

The apex domain (jeeb.uk) needs a certification from Let's Encrypt because Azure CDN won't generate a cert for the apex domain...

The cert is created in `.cloud/certificate.tf`, but it is only valid for 90 days. Therefore the terraform needs to be re-applied to create a new cert (run .`cloud/run.sh`).