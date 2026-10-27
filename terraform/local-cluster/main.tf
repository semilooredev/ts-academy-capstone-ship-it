locals {
  kubeconfig_path = var.kubeconfig_path != "" ? var.kubeconfig_path : "${path.module}/kubeconfig"
}

# A real Kubernetes cluster, provisioned by Terraform - it just runs on the
# laptop instead of in a cloud account. kind runs each node as a Docker
# container, so the Docker Engine (WSL2, on Jeff's Dell) must be running
# before `terraform apply`. The lifecycle the brief asks for - apply,
# destroy, recreate from the same code - is identical to the EKS module.
resource "kind_cluster" "this" {
  name            = var.cluster_name
  node_image      = var.node_image
  wait_for_ready  = true
  kubeconfig_path = local.kubeconfig_path

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    dynamic "node" {
      for_each = range(var.worker_count)
      content {
        role = "worker"
      }
    }
  }
}
