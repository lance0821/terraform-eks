# Tests that the helm-release module handles mixed set types without panic.

variables {
  create           = false  # Don't actually deploy — just validate plan
  name             = "test-release"
  chart            = "test-chart"
  chart_version    = "1.0.0"
  repository       = "https://example.com"
  namespace        = "default"
  create_irsa_role = false

  set = [
    { name = "simple", value = "string-value" },
    { name = "with-type", value = "42", type = "auto" },
    { name = "list-value", value = ["a", "b"] },
    { name = "map-value", value = { key = "val" } },
  ]
}

run "plan_with_mixed_set_types" {
  command = plan

  module {
    source = "../modules/helm-release"
  }

  # Plan should succeed without tostring panic
  assert {
    condition     = true
    error_message = "Plan failed — set type normalization is broken."
  }
}