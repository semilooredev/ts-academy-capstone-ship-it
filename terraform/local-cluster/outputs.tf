output "cluster_name" {
  description = "kind cluster name."
  value       = kind_cluster.this.name
}

output "kubernetes_context" {
  description = "kubectl context name created for this cluster (kind-<cluster_name>)."
  value       = kind_cluster.this.context_name
}

output "kubeconfig_path" {
  description = "Path of the generated kubeconfig. Point KUBECONFIG at it."
  value       = local.kubeconfig_path
}

output "api_endpoint" {
  description = "Kubernetes API endpoint of the local cluster."
  value       = kind_cluster.this.endpoint
}

output "connect" {
  description = "Commands to talk to the cluster after terraform apply."
  value       = "export KUBECONFIG=\"${local.kubeconfig_path}\" && kubectl get nodes"
}
