

# Copy kubeconfig
scp root@217.76.57.54:/etc/rancher/k3s/k3s.yaml c:/tmp/k3s.yaml


# Copy scripts
scp -r C:\Projects\k3s-argo\scripts root@217.76.57.54:/root/scripts

# Set kubeconfig
```
$env:KUBECONFIG = "C:\Projects\k3s-argo\k3s.yaml"
```

# Install root app 
helm template charts/root-app | kubectl apply -f -

password: EypcOt7QrCOmL54f

# create secret

```
	 kubectl create secret generic traefik-acme `
		 --namespace secret-name `
		 --from-literal=dopplerToken="foo" `
		 --dry-run=client -o yaml `
```