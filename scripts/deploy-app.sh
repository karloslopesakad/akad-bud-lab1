#!/bin/bash
set -e

# Deploy Application to ECS

AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-010438495533}
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPO_NAME=${ECR_REPO_NAME:-akad-bud-lab1}
DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG:-latest}
CLUSTER_NAME=${CLUSTER_NAME:-lab1-cluster}
SERVICE_NAME=${SERVICE_NAME:-lab1-service}

ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
FULL_IMAGE_URI="$ECR_REGISTRY/$ECR_REPO_NAME:$DOCKER_IMAGE_TAG"

echo "🚀 Deploying Application to ECS"
echo "📍 Region: $AWS_REGION"
echo "🐳 Image: $FULL_IMAGE_URI"
echo "📦 Cluster: $CLUSTER_NAME"
echo "🔧 Service: $SERVICE_NAME"

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

# Build Docker image
echo "🔨 Building Docker image..."
docker build -t "$ECR_REPO_NAME:$DOCKER_IMAGE_TAG" .
docker tag "$ECR_REPO_NAME:$DOCKER_IMAGE_TAG" "$FULL_IMAGE_URI"

# Check if repository exists, if not create it
echo "📦 Checking ECR repository..."
if ! aws ecr describe-repositories \
  --repository-names "$ECR_REPO_NAME" \
  --region "$AWS_REGION" 2>/dev/null; then
  echo "📝 Creating ECR repository: $ECR_REPO_NAME"
  aws ecr create-repository \
    --repository-name "$ECR_REPO_NAME" \
    --region "$AWS_REGION"
fi

# Push to ECR
echo "📤 Pushing image to ECR..."
docker push "$FULL_IMAGE_URI"

# Get current task definition
echo "📥 Fetching current task definition..."
TASK_DEF=$(aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --region "$AWS_REGION" \
  --query 'services[0].taskDefinition' \
  --output text)

if [ -z "$TASK_DEF" ] || [ "$TASK_DEF" == "None" ]; then
  echo "❌ Service not found: $SERVICE_NAME in cluster $CLUSTER_NAME"
  exit 1
fi

# Get task definition JSON
TASK_DEF_JSON=$(aws ecs describe-task-definition \
  --task-definition "$TASK_DEF" \
  --region "$AWS_REGION" \
  --query 'taskDefinition' \
  --output json)

# Update container image in task definition
NEW_TASK_DEF=$(echo "$TASK_DEF_JSON" | \
  jq -r ".containerDefinitions[0].image = \"$FULL_IMAGE_URI\" | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)")

# Register new task definition
echo "🔄 Registering new task definition..."
NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --region "$AWS_REGION" \
  --cli-input-json "$(echo "$NEW_TASK_DEF")" \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "✅ New task definition registered: $NEW_TASK_DEF_ARN"

# Update service with new task definition
echo "🔄 Updating ECS service..."
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --task-definition "$NEW_TASK_DEF_ARN" \
  --region "$AWS_REGION" > /dev/null

echo "✅ Service update initiated!"

# Wait for service to stabilize
echo "⏳ Waiting for service to stabilize (this may take a few minutes)..."
aws ecs wait services-stable \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --region "$AWS_REGION"

echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Service Status:"
aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --region "$AWS_REGION" \
  --query 'services[0].[serviceName,status,desiredCount,runningCount]' \
  --output table
