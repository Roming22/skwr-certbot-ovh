#!/bin/bash -e
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
SRC_DIR="${SCRIPT_DIR}/k8s"

kubectl get deployment traefik --namespace kube-system -o yaml > "$SRC_DIR/deployment.secret.yml"
SRC_DIR="$SRC_DIR" "$SCRIPT_DIR/bin/patch.py"
kubectl apply -k "$SRC_DIR"

# Generate certificate
kubectl create job "certbot-ovh-manual-$(date +%s)" --namespace kube-system --from cronjob/certbot-ovh
