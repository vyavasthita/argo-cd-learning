CLUSTER_NAME        ?= argocd
ARGOCD_NAMESPACE    ?= argocd
KIND_CONFIG         ?= cluster/kind-config.yaml
ARGOCD_MANIFEST_URL ?= https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
NODEPORT_HTTP       ?= 30080
NODEPORT_HTTPS      ?= 30443
WAIT_TIMEOUT        ?= 300s
APP_OF_APPS         ?= application.yaml

export CLUSTER_NAME ARGOCD_NAMESPACE KIND_CONFIG ARGOCD_MANIFEST_URL
export NODEPORT_HTTP NODEPORT_HTTPS WAIT_TIMEOUT APP_OF_APPS

SHELL := /usr/bin/env bash
KCTX  := kind-$(CLUSTER_NAME)

.DEFAULT_GOAL := help

.PHONY: help install uninstall password info start stop

help:
	@echo "Targets:"
	@echo "  install    Create kind cluster and install ArgoCD core"
	@echo "  start      Apply the App-of-Apps manifest ($(APP_OF_APPS))"
	@echo "  stop       Delete the App-of-Apps manifest ($(APP_OF_APPS))"
	@echo "  uninstall  Delete the kind cluster (removes all namespaces)"
	@echo "  password   Print the initial ArgoCD admin password"
	@echo "  info       Print UI URL, username, and the admin password"
	@echo "  help       Show this help (default)"
	@echo
	@echo "Configurable variables (override on the CLI, e.g. 'make install CLUSTER_NAME=demo'):"
	@echo "  CLUSTER_NAME        = $(CLUSTER_NAME)"
	@echo "  ARGOCD_NAMESPACE    = $(ARGOCD_NAMESPACE)"
	@echo "  KIND_CONFIG         = $(KIND_CONFIG)"
	@echo "  ARGOCD_MANIFEST_URL = $(ARGOCD_MANIFEST_URL)"
	@echo "  NODEPORT_HTTP       = $(NODEPORT_HTTP)"
	@echo "  NODEPORT_HTTPS      = $(NODEPORT_HTTPS)"
	@echo "  WAIT_TIMEOUT        = $(WAIT_TIMEOUT)"
	@echo "  APP_OF_APPS         = $(APP_OF_APPS)"

install:
	@bash scripts/install.sh

start:
	@if [ ! -f "$(APP_OF_APPS)" ]; then \
		echo "[start] manifest not found: $(APP_OF_APPS)" >&2; \
		exit 1; \
	fi
	@echo "[start] applying $(APP_OF_APPS) on context $(KCTX)"
	@kubectl --context $(KCTX) apply -f $(APP_OF_APPS)

stop:
	@if [ ! -f "$(APP_OF_APPS)" ]; then \
		echo "[stop] manifest not found: $(APP_OF_APPS)" >&2; \
		exit 1; \
	fi
	@echo "[stop] deleting $(APP_OF_APPS) on context $(KCTX)"
	@kubectl --context $(KCTX) delete -f $(APP_OF_APPS) --ignore-not-found

uninstall:
	@bash scripts/uninstall.sh

password:
	@bash scripts/password.sh

info:
	@echo "ArgoCD UI:  https://localhost:8080"
	@echo "Username:   admin"
	@printf 'Password:   '
	@bash scripts/password.sh
