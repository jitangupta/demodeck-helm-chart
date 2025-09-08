# Tenant UI Build Configuration

This document explains how to build tenant-specific UI images with build-time configuration for the multi-tenant deployment.

## Overview

The tenant UIs use build-time environment variables instead of runtime environment variables. This ensures each tenant gets a customized image with their specific branding, API endpoints, and configuration baked in.

## Build Configuration

Each tenant's build configuration is defined in `values.yaml` under `tenantUis.<tenant-name>.buildConfig`:

```yaml
tenantUis:
  acme:
    name: acme-ui
    image: demodeck-tenant-ui
    tag: "v1.0.0"  # Tenant-specific tag
    buildConfig:
      VUE_APP_TENANT_NAME: "acme"
      VUE_APP_TITLE: "ACME Corporation Portal"
      VUE_APP_PRIMARY_COLOR: "#dc2626"
      VUE_APP_LOGO_URL: "/logos/acme-logo.png"
      VUE_APP_AUTH_API_URL: "http://auth-api.demodeck.local"
      VUE_APP_API_BASE_URL: "http://product-api.demodeck.local"
      VUE_APP_TENANT_API_URL: "http://tenant-api.demodeck.local"
      VUE_APP_VERSION: "1.0.0"
      VUE_APP_ENVIRONMENT: "production"
```

## Building Tenant Images

### Manual Build Example

To build the ACME tenant UI image:

```bash
cd ../demodeck-tenant-ui

docker build \
  --build-arg VUE_APP_TENANT_NAME="acme" \
  --build-arg VUE_APP_TITLE="ACME Corporation Portal" \
  --build-arg VUE_APP_PRIMARY_COLOR="#dc2626" \
  --build-arg VUE_APP_LOGO_URL="/logos/acme-logo.png" \
  --build-arg VUE_APP_AUTH_API_URL="http://auth-api.demodeck.local" \
  --build-arg VUE_APP_API_BASE_URL="http://product-api.demodeck.local" \
  --build-arg VUE_APP_TENANT_API_URL="http://tenant-api.demodeck.local" \
  --build-arg VUE_APP_VERSION="1.0.0" \
  --build-arg VUE_APP_ENVIRONMENT="production" \
  -t demodeck-tenant-ui:v1.0.0 .
```

### CI/CD Pipeline Integration

In your CI/CD pipeline, you can extract the build configuration from the Helm values and build tenant-specific images:

```yaml
# Example GitHub Actions or Azure DevOps pipeline step
- name: Build Tenant UI
  run: |
    TENANT_NAME=acme
    IMAGE_TAG=$(yq eval ".tenantUis.${TENANT_NAME}.tag" values.yaml)
    
    # Extract build args from values.yaml
    BUILD_ARGS=""
    while IFS= read -r line; do
      key=$(echo "$line" | cut -d: -f1 | xargs)
      value=$(echo "$line" | cut -d: -f2- | xargs | sed 's/^"//' | sed 's/"$//')
      BUILD_ARGS="$BUILD_ARGS --build-arg $key=\"$value\""
    done < <(yq eval ".tenantUis.${TENANT_NAME}.buildConfig | to_entries | .[] | .key + \": \" + .value" values.yaml)
    
    # Build the image
    eval "docker build $BUILD_ARGS -t demodeck-tenant-ui:$IMAGE_TAG ../demodeck-tenant-ui"
```

## Adding New Tenants

To add a new tenant (e.g., "initech"):

1. **Add configuration to values.yaml**:
```yaml
tenantUis:
  initech:
    name: initech-ui
    image: demodeck-tenant-ui
    tag: "v1.0.0"
    replicaCount: 1
    port: 80
    host: "initech.demodeck.local"
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
    buildConfig:
      VUE_APP_TENANT_NAME: "initech"
      VUE_APP_TITLE: "Initech Solutions Portal"
      VUE_APP_PRIMARY_COLOR: "#059669"
      VUE_APP_LOGO_URL: "/logos/initech-logo.png"
      VUE_APP_AUTH_API_URL: "http://auth-api.demodeck.local"
      VUE_APP_API_BASE_URL: "http://product-api.demodeck.local"
      VUE_APP_TENANT_API_URL: "http://tenant-api.demodeck.local"
      VUE_APP_VERSION: "1.0.0"
      VUE_APP_ENVIRONMENT: "production"
```

2. **Create a deployment template**:
Copy `templates/tenant-uis/acme-ui.yaml` to `templates/tenant-uis/initech-ui.yaml` and update the references from `acme` to `initech`.

3. **Build the tenant-specific image**:
Use the build command with the initech configuration.

4. **Deploy with Helm**:
```bash
helm install demodeck-initech . --set tenantUis.initech.enabled=true
```

## Important Notes

- **No Runtime Environment Variables**: The tenant UIs no longer use runtime environment variables. All configuration is baked into the image at build time.
- **Unique Image Tags**: Each tenant should have a unique image tag to avoid conflicts.
- **Build Order**: Images must be built before deployment. Consider using a CI/CD pipeline to automate this process.
- **Registry**: In production, push tenant-specific images to your container registry with appropriate tags.

## Deployment Process

1. Build tenant-specific images with appropriate build args
2. Push images to your container registry
3. Update Helm values with correct image tags
4. Deploy with Helm

This approach ensures each tenant gets a completely isolated and customized UI experience while maintaining the same codebase.