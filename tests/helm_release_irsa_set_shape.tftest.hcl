# Tests that IRSA-enabled releases produce homogeneous set objects.

mock_provider "aws" {}
mock_provider "helm" {}

variables {
  create                    = false
  name                      = "test-irsa"
  chart                     = "test-chart"
  chart_version             = "1.0.0"
  repository                = "https://example.com"
  namespace                 = "default"
  create_irsa_role          = true
  irsa_role_name_prefix     = "test"
  irsa_service_account_name = "test-sa"
  irsa_annotation_key       = "serviceAccount"
  oidc_provider_arn         = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/FAKE"

  set = [
    { name = "extra.key", value = "extra-value" },
  ]
}

run "plan_irsa_with_custom_set" {
  command = plan

  module {
    source = "./modules/helm-release"
  }

  assert {
    condition     = var.create_irsa_role == true
    error_message = "Plan failed — create_irsa_role should be true."
  }

  assert {
    condition     = length(var.set) == 1
    error_message = "Plan failed — irsa_set and normalized_set have incompatible object shapes."
  }
}
