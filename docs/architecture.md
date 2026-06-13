# Architecture Documentation

## Why This Architecture?

### The Problem We Solved
Before the IDP:
- New environment setup: 2+ days (create ticket → wait → manual provisioning)
- No consistency between teams (every service deployed differently)
- No visibility into costs per team
- Security was an afterthought (applied at the end)

After the IDP:
- New environment setup: < 5 minutes (self-service via Backstage)
- Every service follows Golden Paths (consistent, secure by default)
- Real-time cost visibility per team in Grafana
- Security policies enforced automatically (Kyverno)

## Component Decisions

### Why Backstage (not a custom portal)?
- Industry standard used by Spotify, Google, Netflix, Zalando
- 200+ plugins available (PagerDuty, GitHub, Jira, etc.)
- Scaffolder enables codified Golden Paths
- Strong community and CNCF project

### Why Crossplane (not Terraform)?
| Feature | Crossplane | Terraform |
|---------|-----------|-----------|
| Drift detection | Built-in (K8s reconciliation) | Manual (terraform plan) |
| State management | Kubernetes etcd | S3 state file |
| API interface | Kubernetes CRDs | Custom CLI |
| Developer experience | Apply YAML (like any K8s resource) | Learn HCL |

### Why ArgoCD (not Flux)?
- Better UI for debugging sync issues
- ApplicationSets for dynamic app generation
- Strong RBAC model
- Pull-based (more secure than push)

## Data Flow

### Self-Service Flow (Developer Perspective)
1. Developer opens Backstage → Creates → Node.js Service
2. Backstage Scaffolder generates: service repo + catalog-info.yaml + Crossplane claim
3. Crossplane claim applied → Kubernetes resources created (NS, RBAC, RQ)
4. ArgoCD detects new app definition in Git → Syncs to cluster
5. Developer gets email/Slack: "Your environment is ready"

Total time: 3-5 minutes

### Deployment Flow (After Environment Created)
1. Developer pushes code to GitHub
2. GitHub Actions: lint → test → build → push image → update Helm values
3. ArgoCD detects Helm values changed → Syncs Deployment
4. Rolling update with zero downtime
5. Prometheus scrapes new pod metrics
6. Grafana shows updated DORA metrics

## Security Model

### Defense in Depth
```
Layer 1: Kyverno (admission controller) - blocks bad deployments at the gate
Layer 2: RBAC - teams can only access their own namespace
Layer 3: ResourceQuotas - prevent resource exhaustion
Layer 4: SecurityContext - non-root, read-only fs, no privilege escalation
Layer 5: Network Policies - namespace isolation
```

### Golden Path Security Defaults
Every service created via Golden Path gets:
- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- `allowPrivilegeEscalation: false`
- `capabilities.drop: ["ALL"]`
- Resource limits required (enforced by Kyverno)
- No `:latest` tag in staging/production

## DORA Metrics Calculation

| Metric | How We Measure |
|--------|---------------|
| Deployment Frequency | `argocd_app_sync_total{phase="Succeeded"}` per day |
| Lead Time | GitHub webhook: PR created timestamp → ArgoCD sync timestamp |
| Change Failure Rate | `argocd_app_sync_total{phase="Failed"}` / total syncs |
| MTTR | PagerDuty: incident opened → incident resolved |
