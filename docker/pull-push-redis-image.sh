IMAGE_NAME="redis"
IMAGE_TAG="alpine3.20"
IMAGE_ID="$IMAGE_NAME:$IMAGE_TAG"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ecr_repo_url>"
    exit 1
fi

ECR=$1

# Getting this to work may take some finagling. Resources that may help:
# https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html
# https://github.com/awslabs/amazon-ecr-credential-helper
# We want to authenticate with ECR so that we can use those credentials to pull from
# docker hub and push to our private ECR repository.
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR
docker pull $IMAGE_ID
docker tag $IMAGE_ID "${ECR}":latest
docker push "${ECR}":latest
