# Tests that prod environment enforces security constraints.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
    }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:root"
      user_id    = "AIDAJDPLRKLG7EXAMPLE"
    }
  }
}

mock_provider "null" {}
mock_provider "helm" {}
mock_provider "kubernetes" {}

run "prod_rejects_creator_admin" {
  command = plan

  module {
    source = "./infra"
  }

  override_module {
    target = module.vpc
  }

  override_module {
    target = module.eks
  }

  override_module {
    target = module.eks_addons
  }

  override_module {
    target = module.ebs_csi_irsa
  }

  override_module {
    target = module.efs
  }

  override_resource {
    target = null_resource.eks_node_readiness
  }

  variables {
    project_name = "test"
    region       = "us-east-1"
    environment  = "prod"
    vpc_cidr     = "10.0.0.0/16"

    enable_cluster_creator_admin_permissions = true
    one_nat_gateway_per_az                   = true
    single_nat_gateway                       = false
  }

  expect_failures = [
    var.enable_cluster_creator_admin_permissions,
  ]
}

run "prod_rejects_single_nat" {
  command = plan

  module {
    source = "./infra"
  }

  override_module {
    target = module.vpc
  }

  override_module {
    target = module.eks
  }

  override_module {
    target = module.eks_addons
  }

  override_module {
    target = module.ebs_csi_irsa
  }

  override_module {
    target = module.efs
  }

  override_resource {
    target = null_resource.eks_node_readiness
  }

  variables {
    project_name = "test"
    region       = "us-east-1"
    environment  = "prod"
    vpc_cidr     = "10.0.0.0/16"

    enable_cluster_creator_admin_permissions = false
    one_nat_gateway_per_az                   = false
    single_nat_gateway                       = true
  }

  expect_failures = [
    terraform_data.prod_guardrails,
  ]
}
