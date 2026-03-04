# Negative tests for EKS module variable validation rules.

mock_provider "aws" {}

run "empty_name" {
  command = plan

  module {
    source = "./modules/eks"
  }

  override_module {
    target = module.this
  }

  variables {
    name               = "  "
    kubernetes_version = "1.31"
    vpc_id             = "vpc-fake123"
    subnet_ids         = ["subnet-a"]
  }

  expect_failures = [var.name]
}

run "empty_vpc_id" {
  command = plan

  module {
    source = "./modules/eks"
  }

  override_module {
    target = module.this
  }

  variables {
    name               = "test-cluster"
    kubernetes_version = "1.31"
    vpc_id             = ""
    subnet_ids         = ["subnet-a"]
  }

  expect_failures = [var.vpc_id]
}

run "empty_subnet_ids" {
  command = plan

  module {
    source = "./modules/eks"
  }

  override_module {
    target = module.this
  }

  variables {
    name               = "test-cluster"
    kubernetes_version = "1.31"
    vpc_id             = "vpc-fake123"
    subnet_ids         = []
  }

  expect_failures = [var.subnet_ids]
}

run "open_cidrs" {
  command = plan

  module {
    source = "./modules/eks"
  }

  override_module {
    target = module.this
  }

  variables {
    name                                 = "test-cluster"
    kubernetes_version                   = "1.31"
    vpc_id                               = "vpc-fake123"
    subnet_ids                           = ["subnet-a"]
    cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.cluster_endpoint_public_access_cidrs]
}
