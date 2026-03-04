# Negative tests for infra composition variable validation rules.

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

run "invalid_region" {
  command = plan

  module {
    source = "./infra"
  }

  variables {
    project_name = "test"
    region       = "not-a-region"
    environment  = "dev"
    vpc_cidr     = "10.0.0.0/16"
  }

  expect_failures = [var.region]
}

run "empty_project_name" {
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
    project_name = ""
    region       = "us-east-1"
    environment  = "dev"
    vpc_cidr     = "10.0.0.0/16"
  }

  expect_failures = [var.project_name]
}

run "template_project_name" {
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
    project_name = "terraform-template"
    region       = "us-east-1"
    environment  = "dev"
    vpc_cidr     = "10.0.0.0/16"
  }

  expect_failures = [var.project_name]
}

run "invalid_environment" {
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
    environment  = "invalid"
    vpc_cidr     = "10.0.0.0/16"
  }

  expect_failures = [var.environment]
}

run "placeholder_extra_tags" {
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
    environment  = "dev"
    vpc_cidr     = "10.0.0.0/16"
    extra_tags   = { Owner = "owner" }
  }

  expect_failures = [var.extra_tags]
}

run "invalid_vpc_cidr" {
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
    environment  = "dev"
    vpc_cidr     = "bad"
  }

  expect_failures = [var.vpc_cidr]
}

run "az_count_too_low" {
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
    environment  = "dev"
    vpc_cidr     = "10.0.0.0/16"
    az_count     = 1
  }

  expect_failures = [var.az_count]
}

run "az_count_too_high" {
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
    environment  = "dev"
    vpc_cidr     = "10.0.0.0/16"
    az_count     = 5
  }

  expect_failures = [var.az_count]
}

run "invalid_k8s_version" {
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
    project_name       = "test"
    region             = "us-east-1"
    environment        = "dev"
    vpc_cidr           = "10.0.0.0/16"
    kubernetes_version = "v1.31.0"
  }

  expect_failures = [var.kubernetes_version]
}

run "invalid_efs_perf_mode" {
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
    project_name         = "test"
    region               = "us-east-1"
    environment          = "dev"
    vpc_cidr             = "10.0.0.0/16"
    efs_performance_mode = "bad"
  }

  expect_failures = [var.efs_performance_mode]
}

run "invalid_efs_throughput" {
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
    project_name        = "test"
    region              = "us-east-1"
    environment         = "dev"
    vpc_cidr            = "10.0.0.0/16"
    efs_throughput_mode = "bad"
  }

  expect_failures = [var.efs_throughput_mode]
}

run "negative_efs_throughput" {
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
    project_name                        = "test"
    region                              = "us-east-1"
    environment                         = "dev"
    vpc_cidr                            = "10.0.0.0/16"
    efs_provisioned_throughput_in_mibps = -1
  }

  expect_failures = [var.efs_provisioned_throughput_in_mibps]
}

run "prod_creator_admin" {
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
    project_name                             = "test"
    region                                   = "us-east-1"
    environment                              = "prod"
    vpc_cidr                                 = "10.0.0.0/16"
    enable_cluster_creator_admin_permissions = true
  }

  expect_failures = [var.enable_cluster_creator_admin_permissions]
}
