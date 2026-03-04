# Negative tests for VPC module variable validation rules.

mock_provider "aws" {}

run "invalid_cidr" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    name            = "test-vpc"
    cidr            = "not-a-cidr"
    azs             = ["us-east-1a"]
    private_subnets = ["10.0.0.0/20"]
    public_subnets  = ["10.0.128.0/20"]
  }

  expect_failures = [var.cidr]
}

run "empty_azs" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    name            = "test-vpc"
    cidr            = "10.0.0.0/16"
    azs             = []
    private_subnets = []
    public_subnets  = []
  }

  expect_failures = [var.azs]
}

run "private_subnet_count_mismatch" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    name            = "test-vpc"
    cidr            = "10.0.0.0/16"
    azs             = ["us-east-1a", "us-east-1b"]
    private_subnets = ["10.0.0.0/20"]
    public_subnets  = ["10.0.128.0/20", "10.0.144.0/20"]
  }

  expect_failures = [var.private_subnets]
}

run "public_subnet_count_mismatch" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    name            = "test-vpc"
    cidr            = "10.0.0.0/16"
    azs             = ["us-east-1a", "us-east-1b"]
    private_subnets = ["10.0.0.0/20", "10.0.16.0/20"]
    public_subnets  = ["10.0.128.0/20"]
  }

  expect_failures = [var.public_subnets]
}

run "invalid_private_subnet_cidr" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    name            = "test-vpc"
    cidr            = "10.0.0.0/16"
    azs             = ["us-east-1a"]
    private_subnets = ["bad"]
    public_subnets  = ["10.0.128.0/20"]
  }

  expect_failures = [var.private_subnets]
}

run "both_nat_modes" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    name                   = "test-vpc"
    cidr                   = "10.0.0.0/16"
    azs                    = ["us-east-1a"]
    private_subnets        = ["10.0.0.0/20"]
    public_subnets         = ["10.0.128.0/20"]
    single_nat_gateway     = true
    one_nat_gateway_per_az = true
  }

  expect_failures = [var.one_nat_gateway_per_az]
}
