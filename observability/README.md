# DemoDeck Observability Stack

This directory contains Helm values files for deploying the observability stack to collect, store, and visualize logs from both Linux and Windows nodes in AKS.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AKS Cluster                                     │
│  ┌─────────────────────────────┐     ┌─────────────────────────────┐        │
│  │       Linux Nodes           │     │      Windows Nodes          │        │
│  │                             │     │                             │        │
│  │  ┌───────────────────────┐  │     │  ┌───────────────────────┐  │        │
│  │  │ Fluent Bit (DaemonSet)│  │     │  │  Alloy (DaemonSet)    │  │        │
│  │  │  - CNCF Graduated     │  │     │  │  - Grafana Native     │  │        │
│  │  │  - 15B+ downloads     │  │     │  │  - Windows Support    │  │        │
│  │  └───────────┬───────────┘  │     │  └───────────┬───────────┘  │        │
│  └──────────────┼──────────────┘     └──────────────┼──────────────┘        │
│                 │                                    │                       │
│                 │   ┌────────────────────────────┐   │                       │
│                 └───┤   Same Label Format:       ├───┘                       │
│                     │   cluster, environment,    │                           │
│                     │   namespace, pod, container│                           │
│                     └─────────────┬──────────────┘                           │
│                                   │                                          │
│                                   ▼                                          │
│                     ┌─────────────────────────┐                              │
│                     │      Loki Gateway       │                              │
│                     │   (Log Aggregation)     │                              │
│                     └─────────────┬───────────┘                              │
│                                   │                                          │
│            ┌──────────────────────┼──────────────────────┐                   │
│            │                      │                      │                   │
│            ▼                      ▼                      ▼                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐           │
│  │   Azure Storage  │  │     Grafana      │  │   Prometheus     │           │
│  │  (demodeckstorage│  │  (Visualization) │  │    (Metrics)     │           │
│  │   /pod-logs)     │  │                  │  │                  │           │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘           │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Why Two Log Collectors?

| Aspect | Fluent Bit (Linux) | Alloy (Windows) |
|--------|-------------------|-----------------|
| **Platform** | Linux nodes | Windows nodes |
| **Status** | CNCF Graduated | Grafana Native |
| **Issue** | Works perfectly | Fluent Bit has known issues on AKS Windows ([#10511](https://github.com/fluent/fluent-bit/issues/10511)) |
| **Labels** | Same format | Same format |

**Key Insight**: By keeping the label format identical between both collectors, you can:
- Query logs from both platforms with the same Grafana dashboard
- Migrate to Alloy-only in the future with zero downstream changes
- Loki doesn't care which tool sent the logs

## Prerequisites

1. **AKS Cluster** with both Linux and Windows node pools
2. **Azure Storage Account**: `demodeckstorage` with container `pod-logs`
3. **Helm 3.x** installed locally
4. **kubectl** configured for your cluster

## Step 1: Create Namespace and Secrets

```bash
# Create observability namespace
kubectl create namespace observability

# Create Loki Azure Storage credentials
kubectl create secret generic loki-azure-credentials \
  --namespace observability \
  --from-literal=AZURE_STORAGE_KEY='<your-storage-account-key>'

# Create Grafana admin password
kubectl create secret generic grafana-admin \
  --namespace observability \
  --from-literal=admin-user='admin' \
  --from-literal=admin-password='<your-secure-password>'
```

## Step 2: Add Helm Repositories

```bash
# Add required Helm repos
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add fluent https://fluent.github.io/helm-charts

# Update repos
helm repo update
```

## Step 3: Install Components

### 3.1 Install Loki (Log Storage & Aggregation)

```bash
helm upgrade --install loki grafana/loki \
  --namespace observability \
  --values loki-values.yaml \
  --wait --timeout 10m
```

### 3.2 Install Fluent Bit (Linux Log Collection)

```bash
helm upgrade --install fluent-bit fluent/fluent-bit \
  --namespace observability \
  --values fluent-bit-values.yaml \
  --wait
```

### 3.3 Install Grafana Alloy (Windows Log Collection)

```bash
helm upgrade --install alloy grafana/alloy \
  --namespace observability \
  --values alloy-values.yaml \
  --wait
```

### 3.4 Install Prometheus + Grafana Stack

```bash
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace observability \
  --values prometheus-grafana-values.yaml \
  --wait --timeout 10m
```

## Upgrade Commands

```bash
# Upgrade Loki
helm upgrade loki grafana/loki \
  --namespace observability \
  --values loki-values.yaml

# Upgrade Fluent Bit
helm upgrade fluent-bit fluent/fluent-bit \
  --namespace observability \
  --values fluent-bit-values.yaml

# Upgrade Alloy
helm upgrade alloy grafana/alloy \
  --namespace observability \
  --values alloy-values.yaml

# Upgrade Prometheus Stack
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace observability \
  --values prometheus-grafana-values.yaml
```

## Verification

### Check All Pods Are Running

```bash
# View all observability pods
kubectl get pods -n observability

# Expected output:
# NAME                                  READY   STATUS    RESTARTS   AGE
# loki-0                                1/1     Running   0          5m
# loki-gateway-xxx                      1/1     Running   0          5m
# fluent-bit-xxxxx (on Linux nodes)     1/1     Running   0          3m
# alloy-xxxxx (on Windows nodes)        1/1     Running   0          3m
# prometheus-grafana-xxx                1/1     Running   0          5m
# prometheus-prometheus-xxx             1/1     Running   0          5m
```

### Verify DaemonSet Distribution

```bash
# Check Fluent Bit is running on Linux nodes
kubectl get pods -n observability -l app.kubernetes.io/name=fluent-bit -o wide

# Check Alloy is running on Windows nodes
kubectl get pods -n observability -l app.kubernetes.io/name=alloy -o wide
```

### Test Log Flow

```bash
# Check Fluent Bit logs
kubectl logs -n observability -l app.kubernetes.io/name=fluent-bit --tail=50

# Check Alloy logs
kubectl logs -n observability -l app.kubernetes.io/name=alloy --tail=50

# Check Loki is receiving logs
kubectl logs -n observability -l app.kubernetes.io/name=loki --tail=50
```

## Access Grafana

### Option 1: Port Forward (Local Access)

```bash
kubectl port-forward -n observability svc/prometheus-grafana 3000:80
# Open http://localhost:3000
```

### Option 2: Ingress (If Configured)

Access: https://grafana.k8s.demodeck.xyz

### Credentials

- **Username**: admin
- **Password**: Retrieved from grafana-admin secret

```bash
# Get Grafana password
kubectl get secret grafana-admin -n observability -o jsonpath="{.data.admin-password}" | base64 -d
```

## Sample Loki Queries

### All Logs from Cluster

```logql
{cluster="demodeck-aks"}
```

### Logs from Specific Namespace

```logql
{cluster="demodeck-aks", namespace="shared-services"}
```

### Logs from Windows Pods Only

```logql
{cluster="demodeck-aks", os="windows"}
```

### Logs from Linux Pods Only

```logql
{cluster="demodeck-aks", os="linux"}
```

### Logs from Legacy API

```logql
{cluster="demodeck-aks", pod=~"legacy-api.*"}
```

### Error Logs Only

```logql
{cluster="demodeck-aks"} |= "error" or |= "Error" or |= "ERROR"
```

## Troubleshooting

### Fluent Bit Not Collecting Logs

```bash
# Check Fluent Bit pod status
kubectl describe pod -n observability -l app.kubernetes.io/name=fluent-bit

# View Fluent Bit logs for errors
kubectl logs -n observability -l app.kubernetes.io/name=fluent-bit -f
```

### Alloy Not Collecting Windows Logs

```bash
# Check Alloy pod status
kubectl describe pod -n observability -l app.kubernetes.io/name=alloy

# View Alloy logs
kubectl logs -n observability -l app.kubernetes.io/name=alloy -f
```

### Loki Not Receiving Logs

```bash
# Check Loki gateway
kubectl logs -n observability -l app.kubernetes.io/component=gateway -f

# Query Loki API directly
kubectl exec -it -n observability deploy/loki -- \
  wget -qO- 'http://localhost:3100/loki/api/v1/labels'
```

### Azure Storage Connectivity Issues

```bash
# Verify secret exists
kubectl get secret loki-azure-credentials -n observability -o yaml

# Check Loki logs for Azure errors
kubectl logs -n observability loki-0 --tail=100 | grep -i azure
```

## Uninstall

```bash
# Remove all observability components
helm uninstall prometheus -n observability
helm uninstall alloy -n observability
helm uninstall fluent-bit -n observability
helm uninstall loki -n observability

# Delete namespace (removes all resources)
kubectl delete namespace observability
```

## Key Configuration Decision

The most important configuration decision is keeping **the same label format** between Fluent Bit and Alloy:

```yaml
# Both collectors add these labels:
cluster: demodeck-aks
environment: demo
namespace: <from kubernetes>
pod: <from kubernetes>
container: <from kubernetes>
```

This means:
1. **Unified queries** - Same dashboard works for both Linux and Windows logs
2. **Future-proof** - Can migrate to Alloy-only later with zero changes to Grafana
3. **Consistent experience** - Users don't need to know which collector is running where
