## Azure Container Registry (ACR)

## Prerequitis 
If you have microk8s installed or have more than one context on local machine do the following
```bash
az login

az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"

az aks get-credentials --resource-group rg-aks-resource --name aks-poc-new
#Copy Config into WSL
mkdir -p ~/.kube
cp /mnt/c/Users/JITAN/.kube/config ~/.kube/config

#Verify Contexts in WSL
kubectl config get-contexts

#Switch to Your AKS Context
kubectl config use-context aks-poc-new

#Verify:
kubectl config current-context

#(Optional) Keep MicroK8s + AKS Together
KUBECONFIG=~/.kube/config:/mnt/c/Users/JITAN/.kube/config kubectl config view --merge --flatten > /tmp/config
mv /tmp/config ~/.kube/config
```

### 1. Create ACR through Azure Portal
Create ACR through portal, once resource is created, you can move ahead with pushing dockerized images to ACR.
Once created, go and create an admin user, it will be useful when you try to install helm charts through local machine
You will have to create a secret 

### 2. Push Images to ACR
```bash
docker pull ghcr.io/jitangupta/demodeck.tenant.api/demodeck-tenant-api:v1.0.1
#Tag with simple name
docker tag ghcr.io/jitangupta/demodeck.tenant.api/demodeck-tenant-api:v1.0.1 demodeck-tenant-api:v1.0.1

# if you are logged in, then login to ACR
# Get access token
az acr login -n demodeckacr --resource-group rg-aks-resource --expose-token
# Login to ACR
echo <ACCESS_TOKEN> | docker login demodeckacr.azurecr.io -u 00000000-0000-0000-0000-000000000000 --password-stdin

# Tag and push to ACR
docker tag demodeck-product-api:v1.0.0 demodeckacr.azurecr.io/demodeck-product-api:v1.0.0

docker push demodeckacr.azurecr.io/demodeck-tenant-registry-ui:v1.0.1
```

### 3. Create AKS through Azure Portal
Once the resource is created, login to AKS 
```bash
az aks get-credentials --resource-group rg-aks-resource --name aks-poc-new
# Create Secret for AKS with ACR details, required to pull the image, when you install through helm form local machine
kubectl create secret docker-registry acr-secret \
  --docker-server=demodeckacr.azurecr.io \
  --docker-username=demodeckacr \
  --docker-password=kTYgPXxC04DfXoKsacwsYy809Sli02chcJAKGGafJv+ACRCabW8C
```
```yaml
spec:
  containers:
  - name: auth-api
    image: demodeckacr.azurecr.io/demodeck-auth-api:v1.0.0
  imagePullSecrets: #<--add to auth-api.yaml file
  - name: acr-secret #<--add to auth-api.yaml file
```

### 4. Enable NGINX Ingress Controller
```bash
helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx --create-namespacey
```

### 5. Enable NGINX Ingress Controller

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

Run a docker image
```bash
  docker buildx build \
    --build-arg VUE_APP_TENANT_NAME=acme \
    --build-arg VUE_APP_AUTH_API_URL="http://auth-api.demodeck.local" \
    --build-arg VUE_APP_API_BASE_URL="http://product-api.demodeck.local" \
    --build-arg VUE_APP_TENANT_API_URL="http://tenant-api.demodeck.local" \
    --build-arg VUE_APP_TITLE="Acme Corporation Portal" \
    --build-arg VUE_APP_ENVIRONMENT="production" \
    -t demodeck-tenant-ui:acme-v4 .
```

Pull Existing docker image
```bash
#Pull
docker pull ghcr.io/jitangupta/demodeck.tenant.api/demodeck-tenant-api:v1.0.1
#Tag with simple name
docker tag ghcr.io/jitangupta/demodeck.tenant.api/demodeck-tenant-api:v1.0.1 demodeck-tenant-api:v1.0.1
# (Optional) Remove the original long-name image to keep things clean
docker rmi ghcr.io/jitangupta/demodeck.tenant.api/demodeck-tenant-api:v1.0.1
```

Adding Docker image for microk8s
```bash
# Export images from host Docker and import to microk8s
docker save demodeck-tenant-ui:acme | microk8s ctr image import -
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
### Find App Gateway Public IP
```bash
az network public-ip show --resource-group <rg> --name <agw-ip-name>
```

### Apply Cert-manager
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

kubectl apply -f - <<EOF
  apiVersion: cert-manager.io/v1
  kind: ClusterIssuer
  metadata:
    name: letsencrypt-prod
  spec:
    acme: # ← This is Let's Encrypt's ACME protocol
      server: https://acme-v02.api.letsencrypt.org/directory
      email: your-email@example.com  # ← Your email here
      privateKeySecretRef:
        name: letsencrypt-prod
      solvers:
      - http01:
          ingress:
            class: azure/application-gateway
  EOF
  ```

## Push docker image to ACR using WSL:
```bash
# if you are logged in, then login to ACR
# Get access token
az acr login -n demodeckacr --resource-group rg-aks-resource --expose-token
# Login to ACR
echo <ACCESS_TOKEN> | docker login demodeckacr.azurecr.io -u 00000000-0000-0000-0000-000000000000 --password-stdin

# Tag and push to ACR
docker tag demodeck-product-api:v1.0.0 demodeckacr.azurecr.io/demodeck-product-api:v1.0.0

docker push demodeckacr.azurecr.io/demodeck-tenant-registry-ui:v1.0.1
```
## Enable NGINX Ingress Controller
```bash
helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx --create-namespace
```

## Enable AGIC ingress
```bash
az aks enable-addons -n aks-poc -g rg-aks-resource -a ingress-appgw --appgw-name demodeck-appgw

```

  1. Install NGINX Ingress Controller:
  helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx --create-namespace
  2. DNS Setup: Point your domains to NGINX LoadBalancer IP (not Application Gateway)
  3. cert-manager + ClusterIssuer: Same as before for SSL certificates