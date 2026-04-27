#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-argocd}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
KIND_CONFIG="${KIND_CONFIG:-cluster/kind-config.yaml}"
ARGOCD_MANIFEST_URL="${ARGOCD_MANIFEST_URL:-https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml}"
NODEPORT_HTTP="${NODEPORT_HTTP:-30080}"
NODEPORT_HTTPS="${NODEPORT_HTTPS:-30443}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-300s}"

KCTX="kind-${CLUSTER_NAME}"

log() { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[install]\033[0m %s\n' "$*" >&2; }
err() { printf '\033[1;31m[install]\033[0m %s\n' "$*" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "required command not found on PATH: $1"
    exit 1
  fi
}

log "preflight: checking required tools"
require_cmd kind
require_cmd kubectl

if [[ ! -f "$KIND_CONFIG" ]]; then
  err "kind config not found at: $KIND_CONFIG"
  exit 1
fi

log "config:"
log "  CLUSTER_NAME=${CLUSTER_NAME}"
log "  ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE}"
log "  KIND_CONFIG=${KIND_CONFIG}"
log "  ARGOCD_MANIFEST_URL=${ARGOCD_MANIFEST_URL}"
log "  NODEPORT_HTTP=${NODEPORT_HTTP}"
log "  NODEPORT_HTTPS=${NODEPORT_HTTPS}"
log "  WAIT_TIMEOUT=${WAIT_TIMEOUT}"

if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  log "kind cluster '${CLUSTER_NAME}' already exists; skipping creation"
else
  log "creating kind cluster '${CLUSTER_NAME}'"
  kind create cluster --name "${CLUSTER_NAME}" --config "${KIND_CONFIG}"
fi

log "verifying cluster"
kubectl --context "${KCTX}" cluster-info
kubectl --context "${KCTX}" get nodes

log "ensuring namespace '${ARGOCD_NAMESPACE}' exists"
kubectl --context "${KCTX}" create namespace "${ARGOCD_NAMESPACE}" \
  --dry-run=client -o yaml | kubectl --context "${KCTX}" apply -f -

log "installing ArgoCD from ${ARGOCD_MANIFEST_URL}"
kubectl --context "${KCTX}" apply \
  -n "${ARGOCD_NAMESPACE}" \
  --server-side --force-conflicts \
  -f "${ARGOCD_MANIFEST_URL}"

log "waiting for ArgoCD workloads to roll out (timeout=${WAIT_TIMEOUT})"
kubectl --context "${KCTX}" -n "${ARGOCD_NAMESPACE}" rollout status \
  deploy/argocd-server --timeout="${WAIT_TIMEOUT}"
kubectl --context "${KCTX}" -n "${ARGOCD_NAMESPACE}" rollout status \
  deploy/argocd-repo-server --timeout="${WAIT_TIMEOUT}"
kubectl --context "${KCTX}" -n "${ARGOCD_NAMESPACE}" rollout status \
  statefulset/argocd-application-controller --timeout="${WAIT_TIMEOUT}"

log "patching argocd-server Service to NodePort (http=${NODEPORT_HTTP}, https=${NODEPORT_HTTPS})"
kubectl --context "${KCTX}" patch svc argocd-server -n "${ARGOCD_NAMESPACE}" -p \
  "{\"spec\": {\"type\": \"NodePort\", \"ports\": [{\"name\": \"http\", \"nodePort\": ${NODEPORT_HTTP}, \"port\": 80, \"protocol\": \"TCP\", \"targetPort\": 8080}, {\"name\": \"https\", \"nodePort\": ${NODEPORT_HTTPS}, \"port\": 443, \"protocol\": \"TCP\", \"targetPort\": 8080}]}}"

log "done"
echo
echo "  ArgoCD UI:  https://localhost:8080"
echo "  Username:   admin"
echo "  Password:   run 'make password'"
echo
