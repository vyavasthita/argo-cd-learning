#!/usr/bin/env bash
set -euo pipefail

ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
CLUSTER_NAME="${CLUSTER_NAME:-argocd}"
KCTX="kind-${CLUSTER_NAME}"

err() { printf '\033[1;31m[password]\033[0m %s\n' "$*" >&2; }

if ! command -v kubectl >/dev/null 2>&1; then
  err "required command not found on PATH: kubectl"
  exit 1
fi

if ! kubectl --context "${KCTX}" get secret -n "${ARGOCD_NAMESPACE}" argocd-initial-admin-secret >/dev/null 2>&1; then
  err "secret 'argocd-initial-admin-secret' not found in namespace '${ARGOCD_NAMESPACE}' (context '${KCTX}')."
  err "has 'make install' completed successfully? note: this secret is removed after the admin password is changed."
  exit 1
fi

kubectl --context "${KCTX}" get secret \
  -n "${ARGOCD_NAMESPACE}" \
  argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo
