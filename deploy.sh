#!/bin/bash -e
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SRC_DIR="${SCRIPT_DIR}/k8s"

kubectl get deployment traefik --namespace kube-system -o yaml > "$SRC_DIR/deployment.secret.yml"
SRC_DIR="$SRC_DIR" "$SCRIPT_DIR/bin/patch.py"
kubectl apply -k "$SRC_DIR"

# Generate certificate
kubectl create job "certbot-ovh-manual-$(date +%s)" --namespace kube-system --from cronjob/certbot-ovh

# WARNING
echo "Run \`sudo chown -R 65532:65532 /mnt/nas/cluster/k3s/storage/persistentvolumes/kube-system/ssl\` on the kubernetes node to fix a permission issue."
