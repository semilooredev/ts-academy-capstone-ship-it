variable "cluster_name" {
  description = "Name of the kind cluster. The kubectl context is always kind-<cluster_name>."
  type        = string
  default     = "semiloore-capstone"
}

variable "node_image" {
  description = "Pinned kind node image (Kubernetes version of every node). No :latest."
  type        = string
  default     = "kindest/node:v1.33.1"
}

variable "worker_count" {
  description = "Number of worker nodes (plus one control-plane node). 2 mirrors the EKS module's node group."
  type        = number
  default     = 2

  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 3
    error_message = "Keep the laptop cluster small: 1-3 workers."
  }
}

variable "kubeconfig_path" {
  description = "Where the provider writes the cluster kubeconfig. Empty means <module>/kubeconfig."
  type        = string
  default     = ""
}
