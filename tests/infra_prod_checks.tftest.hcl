# Tests that prod environment enforces security constraints.

mock_provider "aws" {}

variables {
  project_name = "test"
  region       = "us-east-1"
  environment  = "prod"
  vpc_cidr     = "10.0.0.0/16"

  enable_cluster_creator_admin_permissions = true
  one_nat_gateway_per_az                   = false
  single_nat_gateway                       = true
}

run "prod_rejects_creator_admin" {
  command = plan

  module {
    source = "../infra"
  }

  # The check block should produce a warning/error
  expect_failures = [
    check.prod_must_not_use_creator_admin,
    check.prod_must_use_ha_nat,
  ]
}
