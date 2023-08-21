---
title:  "Using `for_each` in Terraform's `dynamic` blocks"
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

As an example of this, I need to create 5 `restriction` blocks in the [PagerDuty Schedule resource](https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/schedule) type:

```hcl
resource "pagerduty_schedule" "in_hours_schedule" {
  name = "In Hours"

  layer {    
    dynamic "restriction" {
      for_each = toset(range(1, 6))

      content {
        type              = "weekly_restriction"
        start_day_of_week = restriction.value
        ...
      }
    }
  }
}
```

There are a couple of things to call out here:

- `for_each = toset(range(1, 6))` - This iterates from 1 to 5 creating an array of `number` type
- `restriction.value` - When `for_each` is used in a resource, we would generally refer to the iterator with `each.value` (or `each.key`). However, within a `dynamic` block, the syntax changes and we have to use the name of the `dynamic` block. Hence in this case `restriction.value` refers to the number that the iterator is currently selecting (in this case the numbers 1 to 5).
