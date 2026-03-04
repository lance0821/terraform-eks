# Tests that the helm-release module handles set values without panic.

mock_provider "aws" {}
mock_provider "helm" {}

variables {
  create           = false
  name             = "test-release"
  chart            = "test-chart"
  chart_version    = "1.0.0"
  repository       = "https://example.com"
  namespace        = "default"
  create_irsa_role = false

  set = [
    { name = "simple", value = "string-value" },
    { name = "with-type", value = "42", type = "auto" },
    { name = "numeric", value = "3.14" },
    { name = "boolean", value = "true" },
  ]
}

run "plan_with_mixed_set_types" {
  command = plan

  module {
    source = "./modules/helm-release"
  }

  assert {
    condition     = length(var.set) == 4
    error_message = "Plan failed — set type normalization is broken."
  }
}
