# Terraform — two modules, one lifecycle

The brief asks for a Kubernetes cluster provisioned with Terraform in the
**default VPC**, with the destroy + recreate-from-code lifecycle
demonstrated. This directory delivers that in two modules:

| Module | What it is | Status |
|---|---|---|
| **`.` (this directory)** | **Brief-literal EKS module** — Amazon EKS in the region's default VPC (`data "aws_vpc" "default"` + its subnets), managed node group, IRSA, EBS CSI add-on | **Code delivered; NOT applied.** Validated with `terraform fmt`, `terraform init -backend=false` and `terraform validate`. Not applied because no cloud billing method was available (AWS signup requires a payment card Jeff does not have). Kept as the brief-literal deliverable and so the capstone can be re-run on AWS unchanged later. |
| **`local-cluster/`** | **Local kind module** — a 3-node Kubernetes cluster on the laptop (`tehcyx/kind` provider), same variables/outputs style, same apply → destroy → recreate lifecycle | **This is the module Jeff applies.** Every Helm chart and document in both capstones targets its context, **`kind-semiloore-capstone`**. Full instructions: `local-cluster/README.md`. |

Nothing downstream depends on EKS specifically: the workloads only speak to
the Kubernetes API, so Helm deploys, the bad-release/rollback demo, Robot
Shop and the whole observability stack run identically on the kind cluster.

The one cloud-shaped difference is storage and load balancing, and both are
handled explicitly:

- The EKS module installs the EBS CSI driver (Kubernetes 1.33 has no in-tree
  EBS provisioner) and ships `gp3-storageclass.yaml` for clusters that lack a
  default CSI class.
- kind provides a default `standard` (local-path) StorageClass, so Capstone 2
  carries a `values-kind.yaml` override; LoadBalancer Services stay
  `<pending>` on kind and the demos use `kubectl port-forward`.
