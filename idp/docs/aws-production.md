# AWS Production Deployment Guide

## Prerequisites
- AWS Account with admin access
- Terraform >= 1.5
- eksctl or Terraform EKS module

## Step 1: Create EKS Cluster

```bash
eksctl create cluster \
  --name idp-production \
  --region ap-south-1 \
  --nodegroup-name standard-workers \
  --node-type t3.large \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 10 \
  --managed \
  --with-oidc \
  --alb-ingress-access
```

## Step 2: Install Components

```bash
# Same setup script works - just target EKS instead of Minikube
kubectl config use-context <your-eks-context>
./scripts/setup-local.sh
```

## Step 3: Configure Secrets

```bash
# Store ArgoCD token in AWS Secrets Manager
aws secretsmanager create-secret \
  --name idp/argocd-token \
  --secret-string "your-argocd-token"

# Add GitHub secrets for CI
gh secret set ARGOCD_SERVER --body "https://your-argocd-domain.com"
gh secret set ARGOCD_TOKEN --body "$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d)"
```

## Step 4: Configure DNS + TLS

```bash
# Install cert-manager
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true

# Install AWS Load Balancer Controller
helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=idp-production
```

## Cost Estimate (ap-south-1 / Mumbai)

| Resource | Size | Monthly Cost (approx) |
|----------|------|----------------------|
| EKS Cluster | - | $72 |
| 3x t3.large nodes | On-demand | $150 |
| ALB | - | $20 |
| Total | | ~$242/month |

**With Spot instances for dev/staging nodes:** ~$120/month
