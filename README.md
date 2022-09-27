# Jeeb.uk

## Resources:

* Logo font: 
  * Previous: .SF NS Display Condensed
  * Attempted:
    * Katy Berry
    * Comfortaa
    * [Photograph Signature](https://www.dafont.com/photograph-signature.font?fpp=200&text=jeeb.uk)
    * [Radicals](https://fontbundles.net/free-fonts/script-fonts/radicals?ref=XBlDfU)
  * Current: [Mango](https://pixelsurplus.com/collections/free-fonts/products/mango-free-font#erid5990178)
* [Website logos](https://iconmonstr.com)
* [Favicon generator](https://realfavicongenerator.net/)

## Github flows

* [Azure Actions Documentation](https://github.com/marketplace/actions/azure-cli-action)

## Certificates

The apex domain (jeeb.uk) needs a certificate from Let's Encrypt because Azure CDN won't generate a cert for the apex domain...

The cert is created in `.cloud/certificate.tf`, but it is only valid for 90 days. Therefore the terraform needs to be re-applied to create a new cert (run .`cloud/run.sh`).

## Terraform Setup

Help from: https://gmusumeci.medium.com/getting-started-with-terraform-and-microsoft-azure-a2fcb690eb67

```shell
az login
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<SUB-ID>" --name "Azure-DevOps"
```

## Github actions
https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-static-site-github-actions
```shell
az ad sp create-for-rbac --name github-static-builder --role contributor --scopes /subscriptions/c0f8603c-4a9c-495a-90cf-91033e31205f/resourceGroups/james-cx --sdk-auth
```

## Links

- https://www.eiden.ca/azure-static-blog/
- https://wrightfully.com/azure-static-website-custom-domain-https
- https://the.aamodt.family/rune/2020/01/08/tutorial-azure-website.html#step-5-enforce-https