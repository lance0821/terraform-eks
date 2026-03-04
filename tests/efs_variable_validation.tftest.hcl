# Negative tests for EFS module variable validation rules.

run "empty_name" {
  command = plan

  module {
    source = "./modules/efs"
  }

  variables {
    create                     = false
    name                       = ""
    vpc_id                     = "vpc-fake123"
    vpc_cidr                   = "10.0.0.0/16"
    subnet_ids                 = ["subnet-a"]
    allowed_security_group_ids = ["sg-fake123"]
  }

  expect_failures = [var.name]
}

run "empty_subnets" {
  command = plan

  module {
    source = "./modules/efs"
  }

  variables {
    create                     = false
    name                       = "test-efs"
    vpc_id                     = "vpc-fake123"
    vpc_cidr                   = "10.0.0.0/16"
    subnet_ids                 = []
    allowed_security_group_ids = ["sg-fake123"]
  }

  expect_failures = [var.subnet_ids]
}

run "empty_security_groups" {
  command = plan

  module {
    source = "./modules/efs"
  }

  variables {
    create                     = false
    name                       = "test-efs"
    vpc_id                     = "vpc-fake123"
    vpc_cidr                   = "10.0.0.0/16"
    subnet_ids                 = ["subnet-a"]
    allowed_security_group_ids = []
  }

  expect_failures = [var.allowed_security_group_ids]
}

run "invalid_performance_mode" {
  command = plan

  module {
    source = "./modules/efs"
  }

  variables {
    create                     = false
    name                       = "test-efs"
    vpc_id                     = "vpc-fake123"
    vpc_cidr                   = "10.0.0.0/16"
    subnet_ids                 = ["subnet-a"]
    allowed_security_group_ids = ["sg-fake123"]
    performance_mode           = "invalid"
  }

  expect_failures = [var.performance_mode]
}

run "invalid_throughput_mode" {
  command = plan

  module {
    source = "./modules/efs"
  }

  variables {
    create                     = false
    name                       = "test-efs"
    vpc_id                     = "vpc-fake123"
    vpc_cidr                   = "10.0.0.0/16"
    subnet_ids                 = ["subnet-a"]
    allowed_security_group_ids = ["sg-fake123"]
    throughput_mode            = "invalid"
  }

  expect_failures = [var.throughput_mode]
}

run "invalid_lifecycle" {
  command = plan

  module {
    source = "./modules/efs"
  }

  variables {
    create                     = false
    name                       = "test-efs"
    vpc_id                     = "vpc-fake123"
    vpc_cidr                   = "10.0.0.0/16"
    subnet_ids                 = ["subnet-a"]
    allowed_security_group_ids = ["sg-fake123"]
    lifecycle_policy           = { transition_to_ia = "INVALID" }
  }

  expect_failures = [var.lifecycle_policy]
}

run "zero_throughput" {
  command = plan

  module {
    source = "./modules/efs"
  }

  variables {
    create                          = false
    name                            = "test-efs"
    vpc_id                          = "vpc-fake123"
    vpc_cidr                        = "10.0.0.0/16"
    subnet_ids                      = ["subnet-a"]
    allowed_security_group_ids      = ["sg-fake123"]
    provisioned_throughput_in_mibps = 0
  }

  expect_failures = [var.provisioned_throughput_in_mibps]
}
