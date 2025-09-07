# Login to GHCR and ACR
docker login ghcr.io
docker login myregistry.azurecr.io

# Pull from GHCR
docker pull ghcr.io/jitangupta/demodeck.auth.api/demodeck-auth-api:1.0

# Tag for ACR
docker tag ghcr.io/jitangupta/demodeck.auth.api/demodeck-auth-api:1.0 myregistry.azurecr.io/demodeck-auth-api:1.0

# Push to ACR
docker push myregistry.azurecr.io/demodeck-auth-api:1.0
