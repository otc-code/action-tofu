terraform {
  required_version = ">= 1.5"
  backend "local" {}
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.6.1"
    }
  }

}

module "common" {
  source       = "git::ssh://git@github.com/otc-code/res-common.git?ref=main"
  cloud_region = "eu-central-1"
  config = {
    prefix      = "otc"
    environment = "DEV"
    application = "10-simple"
  }
}

resource "random_string" "random" {
  length = 10
  #number      = true
  min_numeric = 5
}