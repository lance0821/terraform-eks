plugin "aws" {
  enabled = true
  version = "0.45.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  call_module_type = "all"
}

rule "terraform_required_providers" { enabled = true }
# Scaffold mode: keep these disabled until resources/modules consume locals/providers.
# Re-enable as implementation matures to enforce stricter hygiene.
rule "terraform_unused_declarations" { enabled = false }
rule "terraform_unused_required_providers" { enabled = false }
