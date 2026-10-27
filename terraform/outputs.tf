output "aws_region" {
  description = "Region in which the cluster was created."
  value       = var.aws_region
}

output "cluster_name" {
  description = "Amazon EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Amazon EKS API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "default_vpc_id" {
  description = "The default VPC discovered by Terraform."
  value       = data.aws_vpc.default.id
}

output "cluster_subnet_ids" {
  description = "Default VPC subnet IDs selected for EKS (one per AZ)."
  value       = local.cluster_subnet_ids
}

output "configure_kubectl" {
  description = "Run this command after terraform apply to connect kubectl."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.this.name}"
}
