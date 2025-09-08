# 🌐 DNS Configuration Requirements

## Option 1: Azure DNS Zone (Recommended for Production)

### Create DNS zone for demodeck.xyz
```bash
az network dns zone create --resource-group myResourceGroup --name demodeck.xyz
```
### Get your Application Gateway's public IP
```bash
kubectl get ingress -n default
```

### Create A records for all 7 subdomains pointing to Application Gateway IP
```bash
az network dns record-set a add-record --resource-group myResourceGroup --zone-name demodeck.xyz --record-set-name tenant-api --ipv4-address YOUR_GATEWAY_IP
az network dns record-set a add-record --resource-group myResourceGroup --zone-name demodeck.xyz --record-set-name auth-api --ipv4-address YOUR_GATEWAY_IP
az network dns record-set a add-record --resource-group myResourceGroup --zone-name demodeck.xyz --record-set-name product-api --ipv4-address YOUR_GATEWAY_IP
az network dns record-set a add-record --resource-group myResourceGroup --zone-name demodeck.xyz --record-set-name tenantregistry --ipv4-address YOUR_GATEWAY_IP
az network dns record-set a add-record --resource-group myResourceGroup --zone-name demodeck.xyz --record-set-name acme --ipv4-address YOUR_GATEWAY_IP
az network dns record-set a add-record --resource-group myResourceGroup --zone-name demodeck.xyz --record-set-name globalx --ipv4-address YOUR_GATEWAY_IP
az network dns record-set a add-record --resource-group myResourceGroup --zone-name demodeck.xyz --record-set-name initech --ipv4-address YOUR_GATEWAY_IP
```
## Option 2: Local Testing with /etc/hosts

### Add to /etc/hosts (or C:\Windows\System32\drivers\etc\hosts on Windows)
YOUR_GATEWAY_IP tenant-api.demodeck.xyz
YOUR_GATEWAY_IP auth-api.demodeck.xyz
YOUR_GATEWAY_IP product-api.demodeck.xyz
YOUR_GATEWAY_IP tenantregistry.demodeck.xyz
YOUR_GATEWAY_IP acme.demodeck.xyz
YOUR_GATEWAY_IP globalx.demodeck.xyz
YOUR_GATEWAY_IP initech.demodeck.xyz

🚀 Deployment Commands

Basic Deployment

### Yes! This will deploy ALL 7 services
```bash
helm install demodeck ./demodeck-helm-chart
```
Production Deployment with Custom Values

### Create a production values file
```bash
helm install demodeck ./demodeck-helm-chart \
  --set global.registry=yourregistry.azurecr.io \
  --set global.imageTag=v1.0.0 \
  --namespace demodeck \
  --create-namespace
```
Essential Helm Commands

### Check deployment status
```bash
helm status demodeck
```
### List all releases
```bash
helm list
```

### Upgrade deployment
```bash
helm upgrade demodeck ./demodeck-helm-chart
```
### Rollback to previous version
```bash
helm rollback demodeck 1
```
### Uninstall (cleanup)
```bash
helm uninstall demodeck
```
### Dry run to validate templates
```bash
helm install demodeck ./demodeck-helm-chart --dry-run --debug
```
🔍 Verification Commands

### Check all pods
```bash
kubectl get pods
```
### Check services
```bash
kubectl get services
```
### Check ingress
```bash
kubectl get ingress
```
### Get Application Gateway IP
```bash
kubectl get ingress demodeck-single-version-demodeck-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
### Check specific service logs
```bash
kubectl logs -l app=tenant-api
```
⚡ What Gets Deployed

When you run helm install demodeck ./demodeck-helm-chart, it will deploy:

✅ 7 Deployments:
- tenant-api (2 replicas)
- auth-api (2 replicas)
- product-api (3 replicas)
- tenant-registry-ui (2 replicas)
- acme-ui (1 replica)
- globalx-ui (1 replica)
- initech-ui (1 replica)

✅ 7 Services:
- All corresponding ClusterIP services

✅ 1 Ingress:
- AGIC ingress with all 7 domain routes

✅ 1 ServiceAccount:
- Default service account for security

The deployment will create approximately 12 pods total across all services!


------------------------------------------
Build a docker image
```bash
#legacy
docker build -t demodeck-tenant-api:v1.0.0 .

#buildx
docker buildx build -t demodeck-tenant-registry-ui:v1.0.0 .
```

Pull Existing docker image
```bash
#Pull
docker pull ghcr.io/jitangupta/demodeck.tenant.api/demodeck-tenant-api:v1.0.0
#Tag with simple name
docker tag ghcr.io/jitangupta/demodeck.tenant.api/demodeck-tenant-api:v1.0.0 demodeck-tenant-api:v1.0.0
# (Optional) Remove the original long-name image to keep things clean
docker rmi ghcr.io/jitangupta/demodeck.tenant.api/demodeck-tenant-api:v1.0.0
```

Adding Docker image for microk8s
```bash
# Export images from host Docker and import to microk8s
docker save demodeck-auth-api:v1.0.0 | microk8s ctr image import -
```

Check if images are avilable in mcirok8s
```bash
microk8s ctr image list | grep demodeck
```

Debug helm on local using microk8s
```bash
 helm install demodeck-helm-chart demodeck-helm-chart --debug --dry-run
```


Push Docker Image from ghcr to ACR
```bash
az acr import \
  --name demodeck \
  --source ghcr.io/jitangupta/demodeck.auth.api/demodeck-auth-api:0.1-preview \
  --image demodeck-auth-api:0.1-preview

# Private Image
az acr import \
  --name demodeck \
  --source ghcr.io/jitangupta/demodeck.auth.api/demodeck-auth-api:0.1-preview \
  --image demodeck-auth-api:0.1-preview \
  --username <github-username> \
  --password <GHCR_PAT>
```