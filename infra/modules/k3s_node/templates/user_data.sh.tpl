#!/bin/bash
set -euo pipefail
apt-get update -y
apt-get install -y curl unzip cron
snap install aws-cli --classic

# Install k3s (single-node Kubernetes with Traefik ingress built in)
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=stable sh -s - --write-kubeconfig-mode 644
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
until kubectl get nodes >/dev/null 2>&1; do sleep 5; done

# ECR login tokens expire after 12 hours, so refresh the image pull secret every 6 hours.
cat > /usr/local/bin/refresh-ecr-secret.sh <<'SCRIPT'
#!/bin/bash
set -euo pipefail
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
export PATH=$PATH:/snap/bin:/usr/local/bin
kubectl create namespace opspulse --dry-run=client -o yaml | kubectl apply -f -
TOKEN=$(aws ecr get-login-password --region ${region})
kubectl -n opspulse create secret docker-registry ecr-pull \
  --docker-server=${registry} --docker-username=AWS --docker-password="$TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f -
SCRIPT
chmod +x /usr/local/bin/refresh-ecr-secret.sh
echo "0 */6 * * * root /usr/local/bin/refresh-ecr-secret.sh" > /etc/cron.d/ecr-refresh
/usr/local/bin/refresh-ecr-secret.sh || true
