# argo-cd-learning


kind create cluster \
  --name argocd \
  --config cluster/kind-config.yaml

kubectl cluster-info \
--context kind-argocd

### To further verify that the cluster is running, you can run the following command:
kubectl get nodes

#### Create a namespace for ArgoCD by running the following command:
kubectl create namespace argocd

#### Install ArgoCD by running the following command, this will install ArgoCD in the argocd namespace:
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

### Exporting ArgoCD Server NodePort
#### To allow access to the ArgoCD server from outside the Kubernetes cluster, you will need to expose it through a service such as NodePort or LoadBalancer. By default, the
ArgoCD server is only accessible within the cluster, so port mapping must be done
correctly to enable outside access. Since KinD is actually a Docker container, you
can access the ArgoCD UI server through localhost. To create a NodePort service
with ports 80 and 443, which will be mapped to ports 8080 on the ArgoCD server, use
the following command:

kubectl patch svc argocd-server -n argocd -p \
  '{"spec": {"type": "NodePort", "ports": [{"name": "http", "nodePort": 30080, "port": 80, "protocol": "TCP", "targetPort": 8080}, {"name": "https", "nodePort": 30443, "port": 443, "protocol": "TCP", "targetPort": 8080}]}}'


  ### Accessing ArgoCD UI

To access the ArgoCD UI, open a web browser and go to https://localhost:8080. 

### Getting ArgoCD Admin Password
To log in to the ArgoCD UI or CLI, you need the admin password. You can retrieve it by running the following command:

username: admin

kubectl get secret \
  -n argocd \
  argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" |
  base64 -d &&
  echo
----

ArgoCD Examples
https://github.com/argoproj/argocd-example-apps

Start with https://github.com/argoproj/argocd-example-apps/tree/master/guestbook

-----
Adding a test app
# Option 1 (Via Menifests)
    - Use applications/*.yaml

# Option 2 (Argo CD UI)
    1. Fork https://github.com/argoproj/argocd-example-apps

    2. #### Create a namespace for ArgoCD by running the following command:
    kubectl create namespace guestbook

    3. Create a new application in Argo CD UI
        Application Name: argo-cd-guest-app
        Project Name: Default
        Sync Policy: Automatic
        Repository URL: https://github.com/diliplakshya/argocd-example-apps
        Path: guestbook
        Cluster URL: default pop up
        namespace: 

        Click on crate button.

    Check status: kubectl get deploy -n guestbook

    Now, update replica count in https://github.com/diliplakshya/argocd-example-apps/blob/master/guestbook/guestbook-ui-deployment.yaml#L6
    This will trigger a deployment in ArgoCD.

    Similarly create new app for https://github.com/diliplakshya/argocd-example-apps/tree/master/helm-guestbook

