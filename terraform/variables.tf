variable "aws_region" {
  description = "AWS Region containing the account's default VPC."
  type        = string
  default     = "eu-west-2"
}

variable "cluster_name" {
  description = "Name of the Amazon EKS cluster."
  type        = string
  default     = "semiloore-capstone-eks"
}

variable "kubernetes_version" {
  description = "Amazon EKS Kubernetes version."
  type        = string
  default     = "1.33"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_capacity" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2

  validation {
    condition     = var.node_desired_capacity >= 1 && var.node_desired_capacity <= 3
    error_message = "For this capstone, node_desired_capacity must be between 1 and 3."
  }
}

variable "node_min_capacity" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_capacity" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "endpoint_public_access" {
  description = "Expose the EKS API endpoint publicly so Jeff can use kubectl from home. Restrict its CIDRs in a production cluster."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. The default is deliberately explicit; replace it with Jeff's public IP /32 when known."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
