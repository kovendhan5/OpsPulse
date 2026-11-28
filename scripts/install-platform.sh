#!/usr/bin/env bash
# Run ON the k3s node (via SSM session) after `terraform apply`.
set -euo pipefail
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# BUG FIX: Wait for the k3s API to be ready before running helm.
echo "Waiting for k3s node to become Ready..."
until kubectl get nodes 2>/dev/null | grep -q ' Ready'; do sleep 5; done
echo "k3s is ready."

command -v helm >/dev/null || curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# FEATURE: Added --wait so the script blocks until each release's pods are
# running, which prevents "CRD not found" errors when applying the Argo CD
# application too early.
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --wait --timeout 5m
helm upgrade --install argo-rollouts argo/argo-rollouts -n argo-rollouts --create-namespace --wait --timeout 3m
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace --wait --timeout 5m \
  -f monitoring/values-kube-prometheus-stack.yaml

# FEATURE: Create the opspulse namespace if it doesn't exist yet.
kubectl create namespace opspulse --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "=== Platform installed ==="
echo ""
echo "Next steps:"
echo "  kubectl apply -f gitops/argocd/application.yaml"
echo ""
echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo ""


