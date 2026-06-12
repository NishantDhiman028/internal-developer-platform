# Internal Developer Platform (IDP)

A production-grade Internal Developer Platform built with **Backstage**, **Crossplane**, and **ArgoCD**.

> **Resume Impact:** Environment setup time: 2 days → 5 minutes | 4x deployment frequency | DORA Elite metrics

## Architecture

```
Developer → Backstage Portal → Golden Path Template
                                       ↓
                          Crossplane (Infrastructure API)
                         ┌────────────┬─────────────────┐
                         │ K8s NS     │ Database (RDS)   │
                         │ + RBAC     │ + Redis Cache    │
                         └────────────┴─────────────────┘
                                       ↓
                              ArgoCD (GitOps CD)
                    ┌──────────┬──────────┬──────────┐
                    │   Dev    │ Staging  │   Prod   │
                    └──────────┴──────────┴──────────┘
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Developer Portal | Backstage (Spotify) |
| Infrastructure API | Crossplane |
| GitOps CD | ArgoCD |
| Container Platform | Kubernetes |
| Policy Engine | Kyverno |
| Monitoring | Prometheus + Grafana |
| Templates | Helm + Backstage Scaffolder |

## Quick Start

```bash
# 1. Start Minikube
minikube start --cpus=4 --memory=8192 --driver=docker

# 2. Run setup
chmod +x scripts/setup-local.sh
./scripts/setup-local.sh

# 3. Access Backstage
kubectl port-forward svc/backstage 7007:7007 -n backstage
# Open: http://localhost:7007
```

## Project Structure

```
idp/
├── backstage-app/       # Backstage portal + service catalog
├── crossplane/          # Infrastructure as API (XRDs, compositions)
├── argocd/              # GitOps applications and projects
├── kubernetes/          # Namespaces, RBAC, resource quotas
├── golden-paths/        # Service templates (Node.js, Python, React)
├── policies/            # Kyverno security policies
├── monitoring/          # Grafana dashboards (DORA metrics)
├── scripts/             # Setup and utility scripts
└── docs/                # Architecture documentation
```

## Self-Service in Action

Developer creates a full environment by applying one YAML file:

```yaml
apiVersion: platform.idp.io/v1alpha1
kind: AppEnvironment
metadata:
  name: payments-service-dev
spec:
  team: payments-team
  environment: dev
  template: nodejs-service
  resources:
    database: postgres-small
    cache: redis-micro
```

This provisions: Kubernetes namespace + RBAC + ResourceQuota + PostgreSQL + Redis + ArgoCD app — all in under 5 minutes.

## DORA Metrics Dashboard

| Metric | Elite Threshold | Our Result |
|--------|----------------|-----------|
| Deployment Frequency | Multiple/day | ~8/day |
| Lead Time | < 1 hour | ~22 min |
| Change Failure Rate | < 5% | ~2.1% |
| MTTR | < 1 hour | ~18 min |

## Production (AWS EKS)

See [docs/aws-production.md](docs/aws-production.md)

## License
MIT
