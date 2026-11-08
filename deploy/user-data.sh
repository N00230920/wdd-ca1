#!/usr/bin/env bash
set -e

# Install Docker
dnf install -y docker
systemctl enable --now docker

# Write the deploy script to /usr/local/bin/deploy-drop
cat > /usr/local/bin/deploy-drop <<'SCRIPT'
#!/usr/bin/env bash
# Deploys one image of the drop app.
# Usage: deploy-drop <tag>
set -euo pipefail

# Send errors to the same place as normal output, so that GitHub Actions
# shows everything in one block.
exec 2>&1

TAG="$1"
REGION=eu-west-1

# Works out the registry address from the account the instance belongs to
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
IMAGE="$REGISTRY/drop-app:$TAG"

echo "Deploying $IMAGE"

# Fetches all env vars beginning with /drop-app/ from the parameter store
# and copies them into a .env file called drop.env
aws ssm get-parameters-by-path \
  --region "$REGION" \
  --path /drop-app/ \
  --with-decryption \
  --query 'Parameters[].[Name,Value]' \
  --output text \
  | sed 's|^/drop-app/||' \
  | tr '\t' '=' > /etc/drop.env

# Sets permissions for file owner only to have access to .env file
chmod 600 /etc/drop.env

# Login to ECR to pull drop app containers
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

docker pull "$IMAGE"

# Replace the running container with one from the new image
docker rm -f drop || true
docker run -d \
  --name drop \
  --restart unless-stopped \
  -p 80:8000 \
  --env-file /etc/drop.env \
  "$IMAGE"

# Delete images that no container is using, so old versions don't fill the disk
docker image prune -af

echo "Deployed $IMAGE"
SCRIPT

chmod +x /usr/local/bin/deploy-drop

# Start the newest image
/usr/local/bin/deploy-drop latest