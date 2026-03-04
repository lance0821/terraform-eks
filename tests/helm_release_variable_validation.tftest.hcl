# Negative tests for helm-release module variable validation rules.

mock_provider "aws" {}
mock_provider "helm" {}

run "empty_chart_version" {
  command = plan

  module {
    source = "./modules/helm-release"
  }

  variables {
    create        = false
    name          = "test-release"
    chart         = "test-chart"
    chart_version = "  "
  }

  expect_failures = [var.chart_version]
}

run "irsa_missing_prefix" {
  command = plan

  module {
    source = "./modules/helm-release"
  }

  variables {
    create                    = false
    name                      = "test-release"
    chart                     = "test-chart"
    chart_version             = "1.0.0"
    create_irsa_role          = true
    irsa_role_name_prefix     = ""
    irsa_service_account_name = "test-sa"
    oidc_provider_arn         = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/FAKE"
  }

  expect_failures = [var.irsa_role_name_prefix]
}

run "irsa_missing_sa_name" {
  command = plan

  module {
    source = "./modules/helm-release"
  }

  variables {
    create                    = false
    name                      = "test-release"
    chart                     = "test-chart"
    chart_version             = "1.0.0"
    create_irsa_role          = true
    irsa_role_name_prefix     = "test"
    irsa_service_account_name = ""
    oidc_provider_arn         = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/FAKE"
  }

  expect_failures = [var.irsa_service_account_name]
}

run "irsa_missing_oidc" {
  command = plan

  module {
    source = "./modules/helm-release"
  }

  variables {
    create                    = false
    name                      = "test-release"
    chart                     = "test-chart"
    chart_version             = "1.0.0"
    create_irsa_role          = true
    irsa_role_name_prefix     = "test"
    irsa_service_account_name = "test-sa"
    oidc_provider_arn         = ""
  }

  expect_failures = [var.oidc_provider_arn]
}
