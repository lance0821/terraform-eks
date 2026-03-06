# Tests that the EKS module defaults are security-hardened.
# These assertions check variable defaults only — no real plan is needed.

mock_provider "aws" {}

mock_provider "aws" {}
mock_provider "cloudinit" {}
mock_provider "null" {}
mock_provider "time" {}
mock_provider "tls" {}

variables {
  create             = false
  name               = "test-cluster"
  kubernetes_version = "1.31"
  vpc_id             = "vpc-fake123"
  subnet_ids         = ["subnet-a", "subnet-b"]
}

run "verify_secure_defaults" {
  command = plan

  module {
    source = "./modules/eks"
  }

  override_module {
    target = module.this
  }

  # Public endpoint off by default
  assert {
    condition     = !var.endpoint_public_access
    error_message = "endpoint_public_access should default to false."
  }

  # Private endpoint on by default
  assert {
    condition     = var.endpoint_private_access
    error_message = "endpoint_private_access should default to true."
  }

  # All 5 log types enabled by default
  assert {
    condition     = length(var.cluster_enabled_log_types) == 5
    error_message = "All 5 control plane log types should be enabled by default."
  }

  # KMS encryption on by default
  assert {
    condition     = var.create_kms_key
    error_message = "create_kms_key should default to true."
  }

  # Cluster creator admin OFF by default
  assert {
    condition     = !var.enable_cluster_creator_admin_permissions
    error_message = "enable_cluster_creator_admin_permissions should default to false."
  }
}
