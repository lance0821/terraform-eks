# Tests that prod environment enforces security constraints.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  }
}

variables {
  project_name = "test"
  region       = "us-east-1"
  environment  = "prod"
  vpc_cidr     = "10.0.0.0/16"
  az_count     = 2

  # Keep test focused on creator-admin prod guardrail.
  enable_ebs_csi_irsa = false

  enable_cluster_creator_admin_permissions = true
}

run "prod_rejects_creator_admin" {
  command = plan

  module {
    source = "../infra"
  }

  # Prod must not allow creator-admin bootstrap access.
  expect_failures = [
    var.enable_cluster_creator_admin_permissions,
  ]
}