#!/bin/bash
echo "Removing IDP components..."
kubectl delete -f argocd/apps/ 2>/dev/null || true
kubectl delete -f crossplane/claims/ 2>/dev/null || true
helm uninstall kube-prometheus -n monitoring 2>/dev/null || true
helm uninstall kyverno -n kyverno 2>/dev/null || true
helm uninstall crossplane -n crossplane-system 2>/dev/null || true
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 2>/dev/null || true
kubectl delete namespace argocd crossplane-system monitoring kyverno backstage dev-team-a dev-team-b staging production 2>/dev/null || true
echo "Teardown complete"
