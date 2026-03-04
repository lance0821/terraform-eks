terraform {
  required_version = ">= 1.12.0, < 2.0.0"

  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 6.34" }
    helm       = { source = "hashicorp/helm", version = "~> 3.1" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 3.0" }
    null       = { source = "hashicorp/null", version = "~> 3.2" }
  }
}
