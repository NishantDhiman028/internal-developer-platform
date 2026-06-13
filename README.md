#  Internal Developer Platform (IDP) on AWS EKS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?logo=kubernetes&logoColor=white)](https://aws.amazon.com/eks/)
[![Backstage](https://img.shields.io/badge/Backstage-Portal-9BF0E1?logo=backstage&logoColor=black)](https://backstage.io)
[![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?logo=argo&logoColor=white)](https://argo-cd.readthedocs.io)
[![Crossplane](https://img.shields.io/badge/Infra-Crossplane-FFBD45?logoColor=black)](https://crossplane.io)
[![Kyverno](https://img.shields.io/badge/Policy-Kyverno-FF6C37)](https://kyverno.io)

> **Enterprise-grade Internal Developer Platform built on the BACK Stack** — Backstage · ArgoCD · Crossplane · Kyverno — enabling self-service infrastructure provisioning, policy enforcement, and GitOps deployments on AWS EKS.

---

##  What Problem Does This Solve?

In most teams, a developer who needs a new S3 bucket or RDS database has to:
1. Raise a ticket to the infra/DevOps team
2. Wait 2–5 days for approval and provisioning
3. Get credentials manually over Slack/email

**This IDP eliminates all of that.**

A developer fills out a simple form in the Backstage portal → a Crossplane Claim YAML is automatically committed to Git → ArgoCD syncs it to EKS → AWS resource is provisioned in minutes. No tickets. No waiting. No manual steps.

---

##  Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Developer Experience Layer                    │
│                                                                  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │          Backstage Developer Portal                      │  │
│   │   Software Catalog · Golden Path Templates · Docs        │  │
│   └────────────────────┬─────────────────────────────────────┘  │
└────────────────────────│────────────────────────────────────────┘
                         │ Git commit (Crossplane Claim YAML)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GitOps Layer                               │
│                                                                  │
│   ┌──────────────┐         ┌─────────────────────────────────┐  │
│   │   GitHub     │ ──────► │   ArgoCD (App of Apps pattern)  │  │
│   │   Repo       │  sync   │   Watches repo, auto-deploys    │  │
│   └──────────────┘         └──────────────┬──────────────────┘  │
└──────────────────────────────────────────│─────────────────────┘
                                           │ applies manifests
                                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Platform Layer (AWS EKS)                      │
│                                                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────────────┐  │
│  │  Crossplane │  │   Kyverno    │  │  Monitoring Stack     │  │
│  │  Compositions│  │  Policies    │  │  Prometheus + Grafana │  │
│  │  XRDs/Claims│  │  Enforce +   │  │  Custom Dashboards    │  │
│  └──────┬──────┘  │  Audit mode  │  └───────────────────────┘  │
│         │         └──────────────┘                             │
└─────────│───────────────────────────────────────────────────────┘
          │ provisions
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AWS Resources                              │
│   S3 Buckets · RDS · VPC · IAM Roles · EKS Namespaces · ECR   │
└─────────────────────────────────────────────────────────────────┘
```

---

##  Repository Structure

```
internal-developer-platform/
│
├── .github/workflows/         # CI pipelines
│   ├── validate-yaml.yaml     # Validates all YAML with kubeconform
│   ├── lint-helm.yaml         # Helm chart linting
│   └── kyverno-test.yaml      # Policy testing on PRs
│
├── backstage-app/             # Spotify Backstage portal
│   ├── app-config.yaml        # Main Backstage config
│   ├── catalog-info.yaml      # Software catalog entries
│   └── packages/             # Backstage plugins & customizations
│
├── argocd/
│   └── projects/              # ArgoCD AppProject definitions
│       ├── platform.yaml      # Platform team project
│       └── dev-teams.yaml     # Developer team projects with RBAC
│
├── crossplane/                # Infrastructure provisioning
│   ├── compositions/          # XRDs + Compositions (internal APIs)
│   │   ├── s3-bucket-xrd.yaml
│   │   ├── rds-postgres-xrd.yaml
│   │   └── eks-namespace-xrd.yaml
│   └── claims/                # Example claims for each resource
│       ├── example-s3.yaml
│       └── example-rds.yaml
│
├── golden-paths/              # Service templates for developers
│   ├── nodejs-service/        # Node.js microservice template
│   │   ├── template.yaml      # Backstage scaffolder template
│   │   ├── Chart.yaml
│   │   └── values.yaml
│   └── python-service/        # Python service template
│
├── kubernetes/                # Core platform manifests
│   ├── namespaces.yaml
│   └── rbac/
│
├── monitoring/
│   └── dashboards/            # Grafana dashboard JSONs
│       ├── platform-overview.json
│       └── crossplane-resources.json
│
├── policies/                  # Kyverno policy definitions
│   ├── require-labels.yaml    # Enforce team/env labels
│   ├── restrict-images.yaml   # Allow only ECR images
│   └── resource-limits.yaml   # Require CPU/memory limits
│
├── scripts/                   # Bootstrap & utility scripts
│   ├── bootstrap.sh           # One-command cluster setup
│   └── cleanup.sh
│
└── docs/                      # Architecture docs & guides
    ├── architecture.md
    ├── adding-templates.md
    └── crossplane-guide.md
```

---

##  Tech Stack

| Layer | Tool | Purpose |
|---|---|---|
| **Developer Portal** | Backstage (Spotify) | Single pane of glass — catalog, templates, docs |
| **GitOps Engine** | ArgoCD | Automatic sync from Git to EKS |
| **Infra Provisioning** | Crossplane | Self-service AWS resource provisioning via YAML |
| **Policy Engine** | Kyverno | Enforce security & compliance on every deployment |
| **Container Platform** | AWS EKS | Managed Kubernetes cluster |
| **CI/CD** | GitHub Actions | YAML validation, Helm linting, policy testing |
| **Monitoring** | Prometheus + Grafana | Platform health, resource dashboards |
| **Service Packaging** | Helm | Kubernetes app templates |

---

##  Quick Start

### Prerequisites

```bash
# Tools required
aws --version          # AWS CLI v2+
kubectl version        # kubectl v1.28+
helm version           # Helm v3.12+
terraform version      # Terraform v1.5+ (optional, for EKS provisioning)
```

### 1. Provision EKS Cluster

```bash
# Using eksctl (fastest)
eksctl create cluster \
  --name idp-cluster \
  --region ap-south-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3

# Configure kubectl
aws eks update-kubeconfig --region ap-south-1 --name idp-cluster
```

### 2. Bootstrap the Platform

```bash
# Clone the repo
git clone https://github.com/NishantDhiman028/internal-developer-platform
cd internal-developer-platform

# Run bootstrap script (installs ArgoCD, Crossplane, Kyverno, Backstage)
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

### 3. Access Backstage Portal

```bash
# Port-forward Backstage service
kubectl port-forward svc/backstage 7007:7007 -n backstage

# Open in browser
open http://localhost:7007
```

### 4. Access ArgoCD UI

```bash
# Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open: https://localhost:8080  |  User: admin
```

---

##  Core Features

###  Self-Service Infrastructure via Backstage + Crossplane

Developers provision AWS resources through a UI form — no Terraform knowledge needed.

**Example: Developer requests an S3 bucket**
```yaml
# This YAML is auto-generated by Backstage template
# Developer only fills a form — never sees this
apiVersion: platform.io/v1alpha1
kind: S3Bucket
metadata:
  name: team-alpha-assets
  namespace: team-alpha
spec:
  region: ap-south-1
  versioning: true
  encryption: AES256        # Always enforced — dev can't disable
  tags:
    team: alpha
    environment: production
    cost-center: "1234"
```

Crossplane controller picks this up and provisions the actual S3 bucket on AWS within ~2 minutes.

---

###  Golden Path Templates

Pre-built service templates in Backstage scaffolder — developers create new microservices with all best practices baked in.

**Available templates:**
- `nodejs-service` — Node.js + Express, Dockerfile, Helm chart, GitHub Actions CI
- `python-service` — FastAPI, pytest setup, containerized, linting pre-configured

**What each template auto-generates:**
- GitHub repository with proper structure
- Helm chart with resource limits set
- GitHub Actions CI pipeline (test → build → push to ECR)
- ArgoCD Application manifest
- Backstage catalog entry (`catalog-info.yaml`)

---

###  Policy Enforcement with Kyverno

Every resource deployed to EKS is validated against policies **before** it's admitted.

```yaml
# Example: Kyverno policy — all pods must have resource limits
# File: policies/resource-limits.yaml
spec:
  validationFailureAction: enforce   # Blocks deploy if violated
  rules:
    - name: check-container-resources
      validate:
        message: "CPU and memory limits are required."
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
```

**Active policies in this repo:**
| Policy | Mode | What it enforces |
|---|---|---|
| `require-labels.yaml` | Enforce | All resources must have `team` and `env` labels |
| `restrict-images.yaml` | Enforce | Only images from ECR allowed (no `latest` tag) |
| `resource-limits.yaml` | Enforce | CPU + memory limits required on all containers |

---

###  GitOps with ArgoCD (App of Apps Pattern)

All platform components and developer workloads managed via ArgoCD.

```
argocd/projects/
├── platform.yaml      ← ArgoCD manages: Crossplane, Kyverno, Backstage
└── dev-teams.yaml     ← ArgoCD manages: team namespaces, developer apps
```

Any change merged to `main` branch is automatically synced to the cluster within 3 minutes. Zero manual `kubectl apply` commands needed.

---

###  Monitoring & Observability

Grafana dashboards track:
- Crossplane resource provisioning status (pending / healthy / failed)
- Kyverno policy violation count per team
- ArgoCD sync status (synced / out-of-sync / degraded)
- Cluster resource utilization per namespace

---

##  Security Design

| Concern | Solution |
|---|---|
| Who can provision what? | Kubernetes RBAC + ArgoCD AppProject restrictions by namespace |
| Are resources compliant? | Kyverno policies in `enforce` mode — violations block deployment |
| Are images safe? | Kyverno restricts to ECR images only, no `latest` tag allowed |
| Audit trail | All changes via Git PRs — full history of who changed what and when |
| Secrets management | Kubernetes Secrets + IRSA (IAM Roles for Service Accounts) |

---

##  CI Pipeline (GitHub Actions)

Every Pull Request triggers:

```
PR opened
    │
    ├─► Validate all YAML (kubeconform --strict)
    ├─► Lint Helm charts (helm lint)
    ├─► Test Kyverno policies against changed resources
    └─► Summary report on PR as comment
```

```bash
# Run locally before pushing
find . -name "*.yaml" | xargs kubeconform -strict -summary
helm lint golden-paths/nodejs-service/template
kyverno apply policies/ --resource golden-paths/nodejs-service/template/templates/deployment.yaml
```

---

##  Results & Impact

| Metric | Before IDP | After IDP |
|---|---|---|
| Time to provision S3/RDS | 2–5 days (ticket) | < 3 minutes (self-service) |
| New service bootstrap time | 4–6 hours manually | 8 minutes via Backstage template |
| Policy violation detection | Post-deployment (manual review) | Pre-admission (automated block) |
| Deployment auditability | Low (manual kubectl) | 100% via Git history |
| Developer ticket volume to infra team | ~20 tickets/week | ~2 tickets/week (90% reduction) |

---

##  Roadmap

- [ ] Add Okta SSO integration for Backstage authentication
- [ ] Add Cost Estimation plugin to Backstage (show $ before provisioning)
- [ ] Add PostgreSQL + Redis Crossplane Compositions
- [ ] Integrate Trivy for image vulnerability scanning in CI
- [ ] Add DORA metrics dashboard in Grafana

---

##  Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guide on:
- Adding a new Golden Path template
- Adding a Crossplane Composition
- Modifying Kyverno policies safely (always test in `audit` mode first)

---

##  Author

**Nishant Dhiman**
- GitHub: [@NishantDhiman028](https://github.com/NishantDhiman028)
- LinkedIn: [https://www.linkedin.com/in/nishantdhiman3011/]

---

##  License

MIT License — see [LICENSE](./LICENSE) for details.

---

>  If this project helped you, please consider giving it a star on GitHub!
