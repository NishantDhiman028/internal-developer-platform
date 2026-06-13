#!/bin/bash
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[IDP]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

log "Starting Internal Developer Platform local setup..."

# Check prerequisites
for cmd in kubectl helm minikube; do
  command -v $cmd >/dev/null 2>&1 || err "$cmd not found. Install it first."
done

# Minikube check
if ! minikube status 2>/dev/null | grep -q "Running"; then
  warn "Minikube not running. Starting with 4 CPUs and 8GB RAM..."
  minikube start --cpus=4 --memory=8192 --driver=docker
  minikube addons enable ingress
  minikube addons enable metrics-server
fi

log "Step 1/6: Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
log "ArgoCD ready"

log "Step 2/6: Installing Crossplane..."
kubectl create namespace crossplane-system --dry-run=client -o yaml | kubectl apply -f -
helm repo add crossplane-stable https://charts.crossplane.io/stable --force-update 2>/dev/null
helm upgrade --install crossplane crossplane-stable/crossplane \
  --namespace crossplane-system --wait --timeout=5m
log "Crossplane ready"

log "Step 3/6: Setting up namespaces, RBAC, and resource quotas..."
kubectl apply -f kubernetes/namespaces/
kubectl apply -f kubernetes/rbac/
kubectl apply -f kubernetes/resourcequotas/
log "Namespaces ready"

log "Step 4/6: Installing Prometheus + Grafana..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update 2>/dev/null
helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123 \
  --set grafana.sidecar.dashboards.enabled=true \
  --wait --timeout=8m
kubectl apply -f monitoring/dashboards/
log "Monitoring ready"

log "Step 5/6: Installing Kyverno policies..."
helm repo add kyverno https://kyverno.github.io/kyverno/ --force-update 2>/dev/null
kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install kyverno kyverno/kyverno --namespace kyverno --wait --timeout=5m
sleep 15
kubectl apply -f policies/
log "Kyverno policies applied"

log "Step 6/6: Applying Crossplane compositions and ArgoCD apps..."
kubectl apply -f crossplane/providers/
sleep 20
kubectl apply -f crossplane/compositions/
kubectl apply -f argocd/projects/
kubectl apply -f argocd/apps/
kubectl apply -f argocd/applicationsets/
log "GitOps configured"

ARGOCD_PASS=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "check-kubectl-secret")

echo ""
echo "=================================================="
log "IDP Setup Complete!"
echo "=================================================="
info "Run these in separate terminals to access:"
echo ""
info "Backstage Portal:"
echo "  kubectl port-forward svc/backstage 7007:7007 -n backstage"
echo "  Open: http://localhost:7007"
echo ""
info "ArgoCD Dashboard:"
echo "  kubectl port-forward svc/argocd-server 8080:443 -n argocd"
echo "  Open: https://localhost:8080"
echo "  Login: admin / $ARGOCD_PASS"
echo ""
info "Grafana (DORA Metrics):"
echo "  kubectl port-forward svc/kube-prometheus-grafana 3000:80 -n monitoring"
echo "  Open: http://localhost:3000"
echo "  Login: admin / admin123"
echo "=================================================="
