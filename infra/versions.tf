terraform {
  required_version = ">= 1.12.0, < 2.0.0"

  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 6.34.0" }
    random     = { source = "hashicorp/random", version = "~> 3.6" }
    local      = { source = "hashicorp/local", version = "~> 2.5" }
    tls        = { source = "hashicorp/tls", version = "~> 4.0" }
    helm       = { source = "hashicorp/helm", version = "~>3.1" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~>3.0.1" }
  }
}
