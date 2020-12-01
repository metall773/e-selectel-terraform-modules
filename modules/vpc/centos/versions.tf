terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
    random = {
      source = "hashicorp/random"
    }
    selectel = {
      source = "selectel/selectel"
    }
  }
  required_version = ">= 0.13"
}