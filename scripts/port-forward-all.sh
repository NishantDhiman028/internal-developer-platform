#!/bin/bash
echo "Starting all port-forwards in background..."
kubectl port-forward svc/argocd-server 8080:443 -n argocd &
kubectl port-forward svc/kube-prometheus-grafana 3000:80 -n monitoring &
echo ""
echo "Services available at:"
echo "  ArgoCD:   https://localhost:8080"
echo "  Grafana:  http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop all port-forwards"
wait
