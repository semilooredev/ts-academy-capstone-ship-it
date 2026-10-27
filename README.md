# Capstone 1 — "Ship It"

**TS Academy DevOps Capstone (Beginner Edition) · Semiloore Adegoke (`semilooredev`)**
Repository: <https://github.com/semilooredev/ts-academy-capstone-ship-it>

This repository takes the Docker Samples **Example Voting App** from a local
Docker Compose run to a hardened, CI-built, Helm-deployed application on a
Terraform-provisioned Kubernetes cluster — including the brief's deliberate
bad release and `helm rollback`.

> **Cluster deviation, stated plainly:** the brief asks for a cluster in a
> cloud **default VPC**. The cluster actually applied is a **local kind
> cluster** provisioned by Terraform (`terraform/local-cluster/`), because
> no cloud billing method was available. The brief-literal **EKS /
> default-VPC module is delivered alongside it** (`terraform/`), validated
> with `terraform validate`, and labelled "not applied". Same Terraform
> lifecycle either way — apply → destroy → recreate from code — and every
> workload runs identically, because both clusters serve the same
> Kubernetes API. See Step 3.

Pipeline at a glance:

```text
vote ──► Redis ──► worker ──► Postgres ◄── result
(Flask)  (queue)    (.NET)     (storage)     (Node.js)
```

| # | Brief step | Where it lives |
|---|------------|----------------|
| 1 | Run locally with Docker Compose | `docker-compose.yml` |
| 2 | Containerize safely (pinned, non-root, `.dockerignore`) | `vote/`, `result/`, `worker/` Dockerfiles |
| 3 | Terraform a Kubernetes cluster (brief: in the **default VPC**), destroy + recreate | `terraform/` (EKS module, code delivered) + `terraform/local-cluster/` (kind module, applied) |
| 4 | GitHub Actions: checks, Trivy scan, build + push tagged with the commit SHA | `.github/workflows/ci-cd.yml` |
| 5 | Helm: one chart + one values file, bad release, `helm rollback` | `helm/voting-app/` |

Grading map: working system 50% · automation + documentation 30% · demo + Q&A 20%.
The full click-by-click run order (accounts, evidence, submission) is in
[`../JEFF-ACTIONS.md`](../JEFF-ACTIONS.md); the spoken walkthrough is in
[`../DEMO-SCRIPT.md`](../DEMO-SCRIPT.md).

---

## Step 1 — Run locally with Docker Compose

Prerequisites: Docker with the Compose plugin.

```bash
docker compose up --build -d
docker compose ps
```

- Vote: <http://localhost:8080> (Cats vs Dogs)
- Results: <http://localhost:8081>

Cast a vote, watch the result page update, then prove the whole chain worked —
the vote must have travelled vote → Redis → worker → Postgres:

```bash
docker compose exec db psql -U postgres -d postgres -c "SELECT * FROM votes;"
```

Stop (keeps the database volume) / stop and wipe:

```bash
docker compose down       # keep data
docker compose down -v    # delete data
```

**Evidence:** screenshot of both browser tabs + the `psql` output.

## Step 2 — Containerize safely

What changed versus upstream, and why:

| Control | Implementation |
|---|---|
| Pinned images, no `:latest` | `python:3.11.10-slim-bookworm`, `node:20.18.0-bookworm-slim`, `dotnet/sdk:7.0.410` + `dotnet/runtime:7.0.20`, `redis:7.4.1-alpine`, `postgres:16.4-alpine`; Python deps pinned in `vote/requirements.txt`; Node deps locked by `package-lock.json` + `npm ci` |
| Non-root users | vote runs as UID 10001, worker as UID 10002, result as the image's built-in `node` user (1000), Redis as `999` in Compose; the same UIDs are enforced again in the Helm chart's security contexts |
| `.dockerignore` | Present at the repo root and in `vote/`, `result/`, `worker/`, `seed-data/` — keeps `.git`, `node_modules`, `bin/obj`, caches and Terraform state out of build contexts |
| Production entrypoints | vote serves via Gunicorn on port 8080 (the dev/watchdog stage is kept but never deployed); result runs `node server.js` under `tini` with `PORT=8080` |
| Healthchecks | Compose healthchecks for vote, result, Redis (`redis-cli ping`) and Postgres (`pg_isready`) using the scripts in `healthchecks/` |

Internal ports are consistent everywhere: vote **8080**, result **8080**,
Redis **6379**, Postgres **5432**. In Kubernetes the Service names are exactly
`vote`, `result`, `redis`, `db` because the upstream code resolves those
hostnames.

> Demo credentials: Postgres user/password/database are `postgres`/`postgres`/
> `postgres`. They are hardcoded by the upstream sample code, are used only
> inside this disposable coursework cluster, and are called out here rather
> than hidden.

## Step 3 — Terraform: a Kubernetes cluster, applied locally

`terraform/` contains **two modules with the same lifecycle** (see
`terraform/README.md` for the full labelling):

| Module | Provisions | Status |
|---|---|---|
| `terraform/` | **EKS in the default VPC** — `data "aws_vpc" "default"` + one default subnet per AZ, managed node group (2 × `t3.medium`), IAM, core add-ons + EBS CSI via IRSA, outputs with the `aws eks update-kubeconfig` command | **Brief-literal code — delivered and validated, NOT applied** (no cloud billing method available) |
| `terraform/local-cluster/` | **kind cluster on the laptop** — 1 control-plane + 2 workers, Kubernetes v1.33.1, context `kind-semiloore-capstone`, via the `tehcyx/kind` provider | **Applied** — this is the cluster everything else in both capstones deploys to |

State in both modules is **local and sensitive** — `terraform.tfstate` and
the generated kubeconfig are gitignored; never commit or share them.

### Apply the local cluster

Prerequisite: Docker Engine running (on the Dell: WSL2 Ubuntu + Docker
Engine — see `../JEFF-ACTIONS.md`; kind nodes are Docker containers).

```bash
cd terraform/local-cluster
terraform init
terraform plan
terraform apply
export KUBECONFIG="$(terraform output -raw kubeconfig_path)"
kubectl config current-context     # kind-semiloore-capstone
kubectl get nodes                  # 3 nodes, all Ready
```

### Destroy + recreate from code (reproducibility evidence)

```bash
helm uninstall voting-app -n voting-app   # remove workloads first (and any
                                          # Capstone 2 releases, if installed)
terraform destroy                         # type yes
terraform apply                           # same code, same cluster
export KUBECONFIG="$(terraform output -raw kubeconfig_path)"
kubectl get nodes
```

**Evidence:** screenshots of the first `terraform apply` + `kubectl get
nodes`, `terraform destroy` completing, and the second apply + nodes on the
recreated cluster. (The identical flow on the EKS module — apply, destroy,
re-apply — is written out in the module's outputs and `terraform/README.md`;
it differs only in where the nodes run.)

Storage note: kind's default StorageClass is `standard` (local-path), which
is what the Postgres PVC below uses. On EKS, the module's EBS CSI add-on +
`terraform/gp3-storageclass.yaml` cover the same need.

## Step 4 — GitHub Actions: test, scan, build, push

`.github/workflows/ci-cd.yml` runs on every push and pull request to `main`:

1. **checks** — Node/Python syntax checks, `npm test`, `docker compose config`,
   `terraform fmt -check` + `init -backend=false` + `validate`,
   `helm lint` + `helm template`.
2. **smoke-test** — builds and starts all five services, waits for HTTP 200 on
   vote and result, POSTs a real vote, and asserts the row exists in Postgres.
3. **scan-and-push** (pushes to `main` only) — for each of vote/result/worker:
   build → **Trivy scan** (`aquasec/trivy:0.57.1`, fails the job on HIGH or
   CRITICAL fixable findings) → push **only if the scan passes**.

Registry choice: **GitHub Container Registry (GHCR)** — it is built into the
same GitHub account, authenticates with the workflow's `GITHUB_TOKEN` (no
extra secrets to manage), and the workflow's owner is pinned explicitly:

```text
ghcr.io/semilooredev/capstone-vote:<full commit SHA>
ghcr.io/semilooredev/capstone-result:<full commit SHA>
ghcr.io/semilooredev/capstone-worker:<full commit SHA>
```

Tags are always the **full commit SHA** — immutable, traceable to one commit,
and exactly what Helm is told to deploy. After the first successful run, set
the three packages to **Public** (package → Package settings → Change
visibility) so the cluster can pull them without a secret; the images contain
no secrets. (Private alternative: create an image-pull Secret and list it in
`image.pullSecrets` in the chart values.)

**Evidence:** screenshot of a green Actions run showing all three jobs, and of
one GHCR package page showing a SHA tag.

## Step 5 — Helm: deploy, bad release, rollback

One chart, one values file: `helm/voting-app/` (`Chart.yaml`, `values.yaml`,
templates for all five workloads). It enforces the same hardening as Compose —
`runAsNonRoot`, fixed UIDs, `allowPrivilegeEscalation: false`, all Linux
capabilities dropped, RuntimeDefault seccomp, probes on every service — and
stores Postgres in a PVC and its credentials in a Secret.

Deploy the exact images CI just published. On the kind cluster the two web
Services are set to ClusterIP (kind has no cloud load balancer), and the
pages are reached with port-forward:

```bash
SHA=$(git rev-parse HEAD)
helm upgrade --install voting-app helm/voting-app \
  --namespace voting-app --create-namespace \
  --set image.tag="$SHA" \
  --set vote.service.type=ClusterIP \
  --set result.service.type=ClusterIP
kubectl get pods,svc -n voting-app

kubectl -n voting-app port-forward svc/vote 8080:80     # terminal 1
kubectl -n voting-app port-forward svc/result 8081:80   # terminal 2
```

Open <http://localhost:8080> and <http://localhost:8081> and cast a vote.
(On EKS the same chart deploys unchanged with its default LoadBalancer
Services — no port-forward needed.)

### Ship a bad release — on purpose

```bash
helm upgrade voting-app helm/voting-app -n voting-app \
  --reuse-values --set image.tag=bad-release-demo
kubectl get pods -n voting-app        # vote/result/worker: ImagePullBackOff
helm history voting-app -n voting-app # the bad revision is recorded
```

The tag `bad-release-demo` does not exist in GHCR, so the three custom images
cannot pull. Redis and Postgres keep running — their pinned upstream tags are
real — which isolates the failure to the release, exactly what a rollback is
for.

### Roll back

```bash
helm rollback voting-app -n voting-app
kubectl rollout status deployment/vote -n voting-app
kubectl rollout status deployment/result -n voting-app
kubectl get pods -n voting-app        # everything Running again
helm history voting-app -n voting-app # rollback appears as a new revision
```

**Evidence:** screenshots of (1) the pods in `ImagePullBackOff`, (2)
`helm history` showing the bad revision, (3) the rollback command and the
recovered pods.

---

## Attribution

The application code is vendored from
[dockersamples/example-voting-app](https://github.com/dockersamples/example-voting-app)
(Docker Samples, Apache License 2.0 — see `LICENSE` and `MAINTAINERS` in this
repository). All Dockerfiles were hardened, the Compose file rewritten, and
the Terraform, GitHub Actions workflow and Helm chart in this repository were
written for this capstone. The legacy upstream deployment files that conflict
with the supported path (Swarm stack, images-only Compose, plain Kubernetes
specs, the old result test Compose) were removed deliberately.
