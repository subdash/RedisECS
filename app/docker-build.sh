# Make sure the script receives exactly one argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ecr-uri>"
    exit 1
fi

ECR=$1
APP_URI="${ECR}"/rate-limit-app:latest
REDIS_URI="${ECR}"/rate-limit-redis:latest
# Early exit on error
set -e
# Authenticate with Elastic Container Registry
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$ECR1"
# Build and tag docker images locally
docker build -t rate-limit-app:latest -f docker/App.Dockerfile .
docker build -t rate-limit-redis:latest -f docker/Redis.Dockerfile .
# Push app image to ECR
docker tag rate-limit-app:latest "$APP_URI"
docker push "$APP_URI"
# Push Redis image to ECR
docker tag rate-limit-redis:latest "$REDIS_URI"
docker push "$REDIS_URI"
