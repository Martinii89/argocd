
# k3s + Argo CD bootstrap

This repository bundles a thin GitOps bootstrap for a single-node (or small multi-node) `k3s` cluster with Argo CD. The workflow assumes you control a fresh VPS where Traefik is deployed in-cluster via Argo CD to terminate TLS/Let's Encrypt certificates, while the cluster-to-service communication remains on HTTP.

The process is opinionated towards Ubuntu/Debian hosts and Helm-driven Argo CD deployment. Adjust as needed for your target distribution or infrastructure provider.

## 🧱 Prerequisites

- A VPS (2 vCPU / 4 GB RAM minimum recommended) with Ubuntu 22.04+ or Debian 12.
- Root SSH access (or a sudo-enabled user) and an assigned static public IP.
- A domain or subdomain pointing at the VPS if you plan to expose Argo CD externally via Traefik + Lets Encrypt.
- A workstation with `kubectl` and `helm` installed for remote management. On Windows/WSL use PowerShell or Bash.
- Git access to clone this repository and push configuration updates later.

## 🚀 Bootstrap plan

1. **Prepare the server OS.** Harden SSH, disable swap, enable iptables bridging, and open the firewall for Kubernetes/HTTP traffic. Use `scripts/00-system-prepare.sh` on Ubuntu/Debian.
2. **Install k3s.** Use the official installer via `scripts/10-install-k3s.sh`. By default the script disables the bundled Traefik ingress controller and ServiceLB so that Traefik can be managed later by Argo CD. Customize `INSTALL_K3S_EXEC` only if you need to tweak other k3s features.
3. **Fetch kubeconfig.** Securely copy `/etc/rancher/k3s/k3s.yaml` to your workstation. Update `KUBECONFIG` environment variables as needed.
4. **Install CLI tooling (workstation).** Ensure `kubectl` and `helm` match the clusters Kubernetes minor version.
5. **Deploy Argo CD + root app.** From your workstation, run `scripts/20-bootstrap-argocd.sh` to install the bundled Argo CD chart and apply the GitOps root application from `charts/root-app`. This immediately hands Traefik and additional networking manifests over to Argo CD for ongoing management.
6. **Retrieve the admin password.** Use `scripts/30-get-argocd-password.sh` once the pods are ready.
7. **Expose Argo CD via Traefik.** Edit `charts/root-app/values.yaml` to set your Traefik hostname, ACME email address, and whether to use Let’s Encrypt staging. Once the `traefik` and `traefik-config` applications are healthy, traffic to your hostname will terminate TLS at Traefik and forward to the Argo CD service on port 80.
8. **Install Bitnami Sealed Secrets.** The root application deploys the Bitnami Sealed Secrets controller (`charts/root-app/templates/sealed-secrets.yaml`). Wait for the controller pods to reach `Ready` before applying any `SealedSecret` manifests so they can be decrypted in-cluster.

## 🛠️ Scripts

Run these scripts directly on the VPS (for system/k3s preparation) or from your workstation (for Argo CD bootstrap):

### 1. Prepare the host

```bash
sudo ./scripts/00-system-prepare.sh
```

What it does:
- Updates packages and installs baseline tools (`curl`, `git`, `jq`, `ufw`).
- Disables swap and comments the swap entry from `/etc/fstab` (required by Kubernetes).
- Sets sysctl networking knobs needed for container networking.
- Opens firewall ports 22, 80, 443, 6443, and 10250, then enables `ufw` if its inactive.

### 2. Install k3s

```bash
sudo ./scripts/10-install-k3s.sh
```

Notes:
- Adjust `INSTALL_K3S_EXEC` to suit your needs. By default, this repo disables the bundled Traefik and ServiceLB components because Traefik is managed later by Argo CD.
- After installation the script copies the kubeconfig into `/home/<user>/.kube/config` (or root) and locks it down to `600`.
- Copy the kubeconfig to your workstation and set `KUBECONFIG` before running workstation-side commands.

### 3. Bootstrap Argo CD + GitOps root app

Run this from your workstation (with access to the cluster):

```bash
./scripts/20-bootstrap-argocd.sh
```

What it does:
- Adds/updates the official Argo Helm repo.
- Runs `helm upgrade --install` against `charts/argo-cd` in namespace `argocd` (overrides via `ARGO_NAMESPACE`).
- Waits for the `argo-cd-argocd-server` deployment to become ready.
- Templates and applies the `charts/root-app` Helm chart, seeding Argo CD with your root application definitions (including Traefik and its ingress configuration).

Override environment variables if needed:

```bash
ARGO_NAMESPACE=gitops ROOT_APP_NAME=root-app ./scripts/20-bootstrap-argocd.sh
```

### 4. Retrieve the initial admin password

```bash
./scripts/30-get-argocd-password.sh
```

You can then port-forward locally for quick access during setup:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Log in with the username `admin` and the password from the script above. Once authenticated, rotate the password or configure SSO.

## 🌐 Traefik + Lets Encrypt integration

Traefik is deployed in-cluster as an Argo CD application so you can manage its configuration declaratively and review changes through GitOps.

1. Edit `charts/root-app/values.yaml` and set:
	- `traefik.host` to the FQDN that should resolve to your cluster.
	- `traefik.acme.enabled` to `true` (default) for Let’s Encrypt, or `false` if you plan to supply certificates manually.
	- `traefik.acme.email` to the email address Let’s Encrypt should use for expiry notices.
	- `traefik.acme.staging` to `false` once you are ready for production certificates (leave `true` while testing to avoid rate limits).
	- Optional: adjust `traefik.service` if you run a load balancer such as MetalLB or need a specific `loadBalancerClass`.
2. Point DNS for the chosen hostname at the node(s) that expose Traefik’s HTTP/HTTPS ports (NodePort, LoadBalancer, or another edge device that forwards traffic to the cluster).
3. Re-sync the `traefik` and `traefik-config` applications in Argo CD. Traefik will request certificates automatically via the ACME HTTP-01 challenge and persist them to a PVC.

If you prefer to bring your own certificates or use another automation tool, disable the cert resolver by leaving `traefik.ingress.certResolver` empty and supply a secret name in `networking/traefik/values.yaml` (set `tls.createSecret` to `true` if you want the chart to manage the Kubernetes secret).

## 🧪 Dummy deployment pipeline

- The `dummy-app` chart ships a two-replica `hello-app` deployment with a Traefik `IngressRoute` on `dummytest.martinn.no` so you can exercise zero-downtime rollouts.
- Bump `image.tag` inside `charts/dummy-app/values.yaml` (or automate it) and Argo CD will run a rolling update where at least one replica stays live thanks to `maxUnavailable: 0`.
- Override replicas, host name, or image via Helm values in a forked environment if you need additional test scenarios.

## � Managing sensitive values with Sealed Secrets

Once the Sealed Secrets controller is healthy, you can commit encrypted secrets alongside the rest of your manifests without exposing plaintext data.

1. Install the Sealed Secrets CLI (`kubeseal`) on your workstation.
2. Fetch the controller’s public key (optional but recommended for offline sealing):

	 ```bash
	 kubeseal --fetch-cert --controller-name sealed-secrets --controller-namespace kube-system > sealed-secrets.pub
	 ```

3. Craft a Kubernetes `Secret` manifest locally, then pipe it through `kubeseal`:

	 ```bash
	 kubectl create secret generic traefik-acme \
		 --namespace traefik \
		 --from-literal=email="admin@example.com" \
		 --dry-run=client -o yaml \
	 | kubeseal --cert sealed-secrets.pub > charts/traefik/templates/traefik-acme.sealedsecret.yaml
	 ```

	 ```powershell
	 	Get-Content demo-creds.secret.yaml |
		kubeseal --cert sealed-secrets.pub --namespace traefik --format yaml |
		Set-Content demo-creds.sealedsecret.yaml
	 ```

4. Commit the resulting `SealedSecret`. Argo CD will apply it and the controller will materialize the backing `Secret` automatically.

Rotate credentials by resealing them whenever a value changes. Only the controller’s private key (stored securely in-cluster) can decrypt the ciphertext, so the Git history remains safe to share.

## �🔁 Day-2 operations

- Use Argo CDs Application definitions under `charts/root-app/templates` to manage ongoing workloads.
- Store sensitive values (e.g., Argo CD admin password overrides, repo credentials) in a secrets manager such as HashiCorp Vault, SOPS + age, or Kubernetes `SealedSecret`s.
- Keep the VPS patched (`unattended-upgrades`, `canonical-livepatch`, etc.) and monitor disk usage (`/var/lib/rancher/k3s`).
- Schedule etcd snapshots (k3s does this by default) and test restores in a staging environment.

## 📚 References

- [k3s Documentation](https://docs.k3s.io/)
- [Argo CD Helm Chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [Traefik Kubernetes Guide](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)


# Set current kubectl context
`$env:KUBECONFIG = "C:\Projects\k3s-argo\k3s.yaml