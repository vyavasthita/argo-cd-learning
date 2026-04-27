# argo-cd-learning

A small learning repo for installing ArgoCD into a local [kind](https://kind.sigs.k8s.io/) cluster and experimenting with the App-of-Apps pattern.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (kind runs nodes as containers)
- [`kind`](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/)
- `make`, `bash` (already present on macOS / most Linux distros)

## Quick start

```bash
make install     # create kind cluster + install ArgoCD core + patch NodePort
make start       # apply application.yaml (App-of-Apps) onto the cluster
make password    # print the initial admin password
make info        # print URL, username, and password together
make uninstall   # delete the kind cluster (removes everything)
make help        # list targets and current config values
```

After `make install` finishes, open the UI at <https://localhost:8080> and log in as `admin` with the password printed by `make password`.

## Configuration

All scripts and Makefile targets share the same configurable knobs. Override any of them on the CLI, e.g. `make install CLUSTER_NAME=demo NODEPORT_HTTPS=31443`, or export them as env vars before running `scripts/*.sh` directly.

| Variable              | Default                                                                              | Description                                          |
| --------------------- | ------------------------------------------------------------------------------------ | ---------------------------------------------------- |
| `CLUSTER_NAME`        | `argocd`                                                                             | kind cluster name (kube-context becomes `kind-<name>`) |
| `ARGOCD_NAMESPACE`    | `argocd`                                                                             | Namespace ArgoCD is installed into                   |
| `KIND_CONFIG`         | `cluster/kind-config.yaml`                                                           | Path to kind cluster config                          |
| `ARGOCD_MANIFEST_URL` | `https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`   | ArgoCD install manifest                              |
| `NODEPORT_HTTP`       | `30080`                                                                              | NodePort for the HTTP listener on `argocd-server`    |
| `NODEPORT_HTTPS`      | `30443`                                                                              | NodePort for the HTTPS listener on `argocd-server`   |
| `WAIT_TIMEOUT`        | `300s`                                                                               | Timeout for `kubectl rollout status` waits           |
| `APP_OF_APPS`         | `application.yaml`                                                                   | Path to the App-of-Apps manifest applied by `make start` |

> Note: the kind container's host-port mapping (`hostPort: 8080` -> `containerPort: 30443`) lives in [`cluster/kind-config.yaml`](cluster/kind-config.yaml). If you change `NODEPORT_HTTPS`, update that file too — otherwise the port forward from your host won't line up with the new NodePort.

## What `make install` does

1. Verifies `kind` and `kubectl` are on `PATH`.
2. Creates the kind cluster from `KIND_CONFIG` (skipped if it already exists).
3. Creates the `ARGOCD_NAMESPACE` namespace (idempotent via `apply`).
4. Applies the upstream ArgoCD install manifest with `--server-side --force-conflicts`.
5. Waits for `argocd-server`, `argocd-repo-server`, and the `argocd-application-controller` StatefulSet to roll out.
6. Patches the `argocd-server` Service to type `NodePort` using `NODEPORT_HTTP` / `NODEPORT_HTTPS`.

`make uninstall` simply runs `kind delete cluster --name "$CLUSTER_NAME"`, which tears down every namespace and resource in one shot.

---

## Adding test apps

`make install` intentionally stops after ArgoCD core. To layer apps on top, use either of:

### Option 1 — App-of-Apps (manifests in this repo)

Apply the root [application.yaml](application.yaml) once ArgoCD is up. It points at the [applications/](applications) directory and will create the [`guestbook`](applications/argo-cd-guest-app.yaml) and [`helm-guestbook`](applications/argo-cd-helm-guest-app.yaml) Applications:

```bash
make start
# or, equivalently:
kubectl apply -f application.yaml
```

### Option 2 — Argo CD UI

1. Fork <https://github.com/argoproj/argocd-example-apps>.
2. In the UI, create a new Application:
   - Application Name: `argo-cd-guest-app`
   - Project: `default`
   - Sync Policy: Automatic
   - Repository URL: your fork's URL
   - Path: `guestbook`
   - Cluster URL: in-cluster default
   - Namespace: `guestbook`
3. Click Create. Check status with:
   ```bash
   kubectl get deploy -n guestbook
   ```
4. Edit the replica count in your fork's `guestbook/guestbook-ui-deployment.yaml` and watch ArgoCD pick up the change.
5. Repeat for the `helm-guestbook` path to try a Helm-sourced Application.

## References

- ArgoCD example apps: <https://github.com/argoproj/argocd-example-apps>
- Guestbook starting point: <https://github.com/argoproj/argocd-example-apps/tree/master/guestbook>
