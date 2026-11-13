#!/usr/bin/env bash
# Run ON the k3s node (via SSM session) after `terraform apply`.
set -euo pipefail
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

command -v helm >/dev/null || curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace
helm upgrade --install argo-rollouts argo/argo-rollouts -n argo-rollouts --create-namespace
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f monitoring/values-kube-prometheus-stack.yaml

echo "Platform installed. Now apply the Argo CD application:"
echo "  kubectl apply -f gitops/argocd/application.yaml"
echo "Argo CD admin password:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"


#verify