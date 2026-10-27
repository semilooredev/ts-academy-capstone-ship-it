terraform {
  required_version = ">= 1.6.0"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.13.0"
    }
  }

  # Local state, same as the EKS module. State and the generated kubeconfig
  # are gitignored in this directory.
}
