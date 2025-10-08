
# Install argo-cd with helm
helm repo add argo-cd https://argoproj.github.io/argo-helm

helm dep update charts/argo-cd/

helm install argo-cd charts/argo-cd/

# wait until all pods are ready
kubectl get pods


# Port forward the web-ui 
kubectl port-forward svc/argo-cd-argocd-server 8080:443

# Get the admin password
kubectl get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Get the admin password (Windows)
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }


# Install the root-app
helm template charts/root-app/ | kubectl apply -f -