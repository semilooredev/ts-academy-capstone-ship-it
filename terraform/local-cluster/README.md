# Local cluster module — kind, provisioned by Terraform

**This is the cluster Jeff actually applies.** It creates a real, multi-node
Kubernetes cluster on the laptop with [kind](https://kind.sigs.k8s.io/)
(Kubernetes IN Docker) using the `tehcyx/kind` Terraform provider — the same
Terraform lifecycle the brief asks for (apply → destroy → recreate from
code), at $0, with no cloud account.

Why local? No usable payment method was available for AWS billing, so the
cluster leg runs here. The brief-literal EKS module in `../` (default VPC)
is still delivered and `terraform validate`-clean — see `../README.md` in
this folder's parent (`terraform/README.md`). Every workload in both
capstones (Helm charts, Robot Shop, observability) targets this cluster,
because to Kubernetes workloads the API is identical.

## Prerequisites

- Docker Engine **running** — on Jeff's Dell that means WSL2 Ubuntu with
  Docker Engine inside it (Docker Desktop cannot be used: it requires
  Windows 11 23H2; the Dell is on 21H2). Full setup: `JEFF-ACTIONS.md`.
- Terraform ≥ 1.6, kubectl, helm.

Verify Docker is up before applying — kind nodes are Docker containers:

```bash
docker version
docker ps
```

## Lifecycle

```bash
cd terraform/local-cluster
terraform init
terraform plan
terraform apply        # type yes
```

Expected output at the end of `apply` (abridged):

```text
kind_cluster.this: Creating...
kind_cluster.this: Still creating... [00m30s elapsed]
kind_cluster.this: Creation complete after 1m12s

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

api_endpoint       = "https://127.0.0.1:<host-port>"
cluster_name       = "semiloore-capstone"
connect            = "export KUBECONFIG=\".../terraform/local-cluster/kubeconfig\" && kubectl get nodes"
kubeconfig_path    = ".../terraform/local-cluster/kubeconfig"
kubernetes_context = "kind-semiloore-capstone"
```

(The exact port and timings vary; the apply time depends on whether the
pinned node image `kindest/node:v1.33.1` is already pulled.)

Connect and verify:

```bash
export KUBECONFIG="$(terraform output -raw kubeconfig_path)"
kubectl config current-context        # kind-semiloore-capstone
kubectl get nodes
```

Expected `kubectl get nodes` — three nodes, all `Ready`:

```text
NAME                             STATUS   ROLES           AGE   VERSION
semiloore-capstone-control-plane Ready    control-plane   2m    v1.33.1
semiloore-capstone-worker        Ready    <none>          2m    v1.33.1
semiloore-capstone-worker2       Ready    <none>          2m    v1.33.1
```

### Destroy + recreate from code (the brief's reproducibility step)

```bash
helm uninstall voting-app -n voting-app   # if the apps are installed -
                                          # remove workloads first, as with any cluster
terraform destroy                         # type yes; the node containers are deleted
terraform apply                           # the same code rebuilds the same cluster
export KUBECONFIG="$(terraform output -raw kubeconfig_path)"
kubectl get nodes                         # three Ready nodes again
```

**Evidence to capture:** `terraform apply` completing, `kubectl get nodes`,
then after destroy+recreate, the same two outputs again.

## What you get

- Cluster name `semiloore-capstone`, context **`kind-semiloore-capstone`**
  (this exact context name is used in every doc and command in both repos).
- 1 control-plane + 2 worker nodes (variable `worker_count`, 1–3),
  Kubernetes **v1.33.1** from the pinned image `kindest/node:v1.33.1`.
- kind's bundled local-path provisioner gives the cluster a default
  StorageClass named **`standard`** — that is why Capstone 2's
  `values-kind.yaml` overrides Robot Shop Redis from `gp3` to `standard`.
  The voting app's Postgres PVC and Loki's PVC use the default class.
- LoadBalancer Services get no cloud provider here: their `EXTERNAL-IP`
  stays `<pending>`, which is expected. The demos reach web UIs with
  `kubectl port-forward` instead (see `JEFF-ACTIONS.md`).
