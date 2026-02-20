#!/bin/bash
set -e

# Deploy Infrastructure as Code using CloudFormation

STACK_NAME=${STACK_NAME:-akad-bud-lab1-stack}
TEMPLATE_PATH=${TEMPLATE_PATH:-iac/cloudformation/infrastructure.yaml}
AWS_REGION=${AWS_REGION:-us-east-1}
ENVIRONMENT_NAME=${ENVIRONMENT_NAME:-lab1}
CONTAINER_IMAGE=${CONTAINER_IMAGE:-010438495533.dkr.ecr.us-east-1.amazonaws.com/akad-bud-lab1:latest}

echo "🚀 Deploying CloudFormation Stack: $STACK_NAME"
echo "📍 Region: $AWS_REGION"
echo "📦 Template: $TEMPLATE_PATH"
echo "🐳 Container Image: $CONTAINER_IMAGE"

# Check if template file exists
if [ ! -f "$TEMPLATE_PATH" ]; then
  echo "❌ Template file not found: $TEMPLATE_PATH"
  exit 1
fi

# Deploy or update stack
aws cloudformation deploy \
  --template-file "$TEMPLATE_PATH" \
  --stack-name "$STACK_NAME" \
  --parameter-overrides \
    EnvironmentName="$ENVIRONMENT_NAME" \
    ContainerImage="$CONTAINER_IMAGE" \
  --capabilities CAPABILITY_IAM \
  --region "$AWS_REGION" \
  --no-fail-on-empty-changeset

echo "✅ CloudFormation deployment completed!"

# Get outputs
echo ""
echo "📊 Stack Outputs:"
aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs' \
  --output table

# Get load balancer URL
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

if [ -n "$ALB_DNS" ]; then
  echo ""
  echo "🌐 Application URL: http://$ALB_DNS"
fi
