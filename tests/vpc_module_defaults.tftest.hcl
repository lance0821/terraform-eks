# Tests that VPC module defaults are sensible.

mock_provider "aws" {}

variables {
  name            = "test-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.0.0/20", "10.0.16.0/20"]
  public_subnets  = ["10.0.128.0/20", "10.0.144.0/20"]
}

run "verify_vpc_defaults" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  assert {
    condition     = var.enable_nat_gateway == true
    error_message = "enable_nat_gateway should default to true."
  }

  assert {
    condition     = var.single_nat_gateway == true
    error_message = "single_nat_gateway should default to true."
  }

  assert {
    condition     = var.one_nat_gateway_per_az == false
    error_message = "one_nat_gateway_per_az should default to false."
  }
}
