terraform {
	required_version = ">= 1.0.7"
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">= 2.0.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.1.0"
    }
  }
}

