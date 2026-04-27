#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-argocd}"

log() { printf '\033[1;34m[uninstall]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[uninstall]\033[0m %s\n' "$*" >&2; }

if ! command -v kind >/dev/null 2>&1; then
  err "required command not found on PATH: kind"
  exit 1
fi

log "config:"
log "  CLUSTER_NAME=${CLUSTER_NAME}"

if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  log "deleting kind cluster '${CLUSTER_NAME}' (this removes all namespaces and resources)"
  kind delete cluster --name "${CLUSTER_NAME}"
  log "cluster '${CLUSTER_NAME}' deleted"
else
  log "kind cluster '${CLUSTER_NAME}' not found; nothing to do"
fi
