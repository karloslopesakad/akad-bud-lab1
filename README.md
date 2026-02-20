# AKAD BUD Lab 1

Next.js application with Infrastructure as Code (CloudFormation) for deployment to AWS ECS Fargate with Application Load Balancer.

## 📋 Overview

This project demonstrates:
- **Frontend**: Next.js with TypeScript and Tailwind CSS
- **Infrastructure**: AWS CloudFormation for ECS, Fargate, ALB, VPC
- **CI/CD**: GitHub Actions workflows for infrastructure and application deployment
- **Containerization**: Docker with multi-stage builds
- **Monitoring**: CloudWatch Logs integration

## 🏗️ Project Structure

```
akad-bud-lab1/
├── src/
│   └── app/
│       ├── layout.tsx       # Root layout
│       ├── page.tsx         # Hello World page
│       └── globals.css      # Tailwind styles
├── iac/
│   └── cloudformation/
│       └── infrastructure.yaml  # ECS + ALB + VPC stack
├── scripts/
│   ├── deploy-iac.sh        # Deploy CloudFormation
│   └── deploy-app.sh        # Deploy application to ECS
├── .github/
│   └── workflows/
│       ├── deploy-infrastructure.yml  # Infrastructure CI/CD
│       └── deploy-application.yml     # Application CI/CD
├── Dockerfile               # Docker build configuration
├── package.json             # Node.js dependencies
├── next.config.js           # Next.js configuration
├── tailwind.config.js       # Tailwind CSS configuration
└── tsconfig.json            # TypeScript configuration
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ and npm
- AWS CLI configured with credentials
- Docker (for local testing)
- GitHub account with repository access

### Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

The application will be available at `http://localhost:3000`

## 📦 Deployment

### 1. Infrastructure Deployment (CloudFormation)

Deploy the AWS infrastructure (VPC, ECS Cluster, ALB, Security Groups):

```bash
# Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"  # If using temporary credentials
export AWS_REGION="us-east-1"
export ENVIRONMENT_NAME="lab1"

# Deploy infrastructure
bash scripts/deploy-iac.sh
```

**Automatic Deployment**: Infrastructure is automatically deployed when changes are pushed to the `iac/` directory on the main branch.

### 2. Application Deployment (ECS)

Build and deploy the application to ECS Fargate:

```bash
# Set environment variables (same as infrastructure)
export AWS_ACCOUNT_ID="010438495533"
export AWS_REGION="us-east-1"
export ECR_REPO_NAME="akad-bud-lab1"
export CLUSTER_NAME="lab1-cluster"
export SERVICE_NAME="lab1-service"

# Deploy application
bash scripts/deploy-app.sh
```

**Automatic Deployment**: Application is automatically deployed when changes are pushed to `src/`, `Dockerfile`, or other app files on the main branch.

## 🔐 GitHub Secrets Configuration

Configure the following secrets in your GitHub repository settings:

```
AWS_ACCESS_KEY_ID=ASIAQE3ROZUWU7WVPB6Q
AWS_SECRET_ACCESS_KEY=j470SO0a5a7lK9tQtqgYkOpAs5lHmH+PyTzOAuG9
AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjENb//////////wEaCXVz...
ECR_IMAGE_URI=010438495533.dkr.ecr.us-east-1.amazonaws.com/akad-bud-lab1:latest
```

## 📊 AWS Infrastructure

### Created Resources

- **VPC**: 10.0.0.0/16
- **Subnets**: 2 Public + 2 Private across 2 AZs
- **Internet Gateway**: For public subnet routing
- **NAT Gateway**: For private subnet egress
- **Application Load Balancer**: HTTP on port 80
- **ECS Cluster**: Lab1-cluster
- **ECS Service**: 2 Fargate tasks
- **Security Groups**: ALB and ECS task groups
- **CloudWatch Logs**: 7-day retention
- **IAM Roles**: Task execution and task roles

### Network Architecture

```
Public Subnets (10.0.1.0/24, 10.0.2.0/24)
├── ALB (Port 80)
└── NAT Gateway

Private Subnets (10.0.11.0/24, 10.0.12.0/24)
└── ECS Fargate Tasks (Port 3000)
```

## 🐳 Docker

Build Docker image locally:

```bash
# Build image
docker build -t akad-bud-lab1:latest .

# Run container
docker run -p 3000:3000 akad-bud-lab1:latest
```

## 📈 Monitoring

View application logs:

```bash
aws logs tail /ecs/lab1-logs --follow
```

View ECS service status:

```bash
aws ecs describe-services \
  --cluster lab1-cluster \
  --services lab1-service \
  --region us-east-1
```

## 🔄 CI/CD Workflows

### Deploy Infrastructure Workflow

Triggered on:
- Push to `main` branch with changes in `iac/` directory
- Manual workflow dispatch

Actions:
1. Validate CloudFormation template
2. Deploy CloudFormation stack
3. Post deployment summary with ALB DNS

### Deploy Application Workflow

Triggered on:
- Push to `main` branch with changes in application files
- Manual workflow dispatch

Actions:
1. Build Docker image
2. Login to ECR
3. Push image to ECR
4. Register new ECS task definition
5. Update ECS service
6. Wait for service stabilization
7. Post deployment summary with application URL

## 🛠️ Troubleshooting

### Service won't start

```bash
# Check task logs
aws logs tail /ecs/lab1-logs --follow

# Check service events
aws ecs describe-services \
  --cluster lab1-cluster \
  --services lab1-service \
  --region us-east-1
```

### ECR image not found

```bash
# List ECR repositories
aws ecr describe-repositories --region us-east-1

# List images in repository
aws ecr describe-images \
  --repository-name akad-bud-lab1 \
  --region us-east-1
```

### ALB health checks failing

```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region us-east-1
```

## 📝 Next Steps

- [ ] Add SSL/TLS support (ACM certificate)
- [ ] Implement auto-scaling policies
- [ ] Add RDS database
- [ ] Configure Route53 custom domain
- [ ] Add WAF protection
- [ ] Implement CI/CD for staging/production environments

## 📄 License

MIT

## 👥 Authors

AKAD Seguros - Innovation Engineering Team

## 📞 Support

For issues and questions, contact: karlos.lopes@akadseguros.com.br
