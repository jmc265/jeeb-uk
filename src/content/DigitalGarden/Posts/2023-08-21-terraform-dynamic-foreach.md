---
title:  ""
permalink: dynamic-foreach-terraform/
layout: post
tags: 
  - posts
  - programming
  - terraform
  - dynamic
  - loop
  - foreach
---

The `for_each` instruction in Terraform allows you to loop a resource or module over a set to create multiple instances. For instance, if you were to do:

```hcl
variable "vm_instances" {
  type = map(object({
    location  = string
  }))
  default = {
    instance1 = {
      location       = "East US"
    },
    instance2 = {
      location       = "West US"
    }
  }
}

resource "azurerm_virtual_machine" "vm_instances" {
  for_each = var.vm_instances

  name                  = each.key
  location              = each.value.location
  ...
}
```

You would create 2 VMs, one in East US, the other in West US.

However, it is also possible to use the `for_each` function to loop `dynamic` blocks within a resource.





```hcl
dynamic "restriction" {
      for_each = toset(range(1, 6))

      content {
        type              = "weekly_restriction"
        start_time_of_day = "09:00:00"
        start_day_of_week = restriction.value
        duration_seconds  = local.eight_hours_in_seconds
      }
    }
```