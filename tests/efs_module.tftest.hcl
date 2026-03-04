# Tests EFS module defaults and validation.

variables {
  create                     = false
  name                       = "test-efs"
  vpc_id                     = "vpc-fake123"
  vpc_cidr                   = "10.0.0.0/16"
  subnet_ids                 = ["subnet-a"]
  allowed_security_group_ids = ["sg-fake123"]
}

run "verify_efs_secure_defaults" {
  command = plan

  module {
    source = "./modules/efs"
  }

  assert {
    condition     = var.encrypted == true
    error_message = "EFS encryption should default to true."
  }

  assert {
    condition     = var.enable_backup_policy == true
    error_message = "EFS backup policy should default to enabled."
  }

  assert {
    condition     = var.lifecycle_policy.transition_to_ia == "AFTER_30_DAYS"
    error_message = "EFS lifecycle should default to IA transition after 30 days."
  }
}
