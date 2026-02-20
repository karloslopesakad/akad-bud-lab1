# 🔧 Manual Workflow Setup

Como o GitHub Personal Access Token atual não tem `workflow` scope, os workflows precisam ser adicionados manualmente via interface web ou com um novo token.

## 📋 Opção 1: Adicionar via GitHub Web (Recomendado)

### Passo 1: Acesse o repositório no GitHub
https://github.com/karloslopesakad/akad-bud-lab1

### Passo 2: Crie a primeira workflow (Infrastructure)
1. Clique em **Add file** → **Create new file**
2. Caminho: `.github/workflows/deploy-infrastructure.yml`
3. Cole o conteúdo abaixo:

```yaml
name: Deploy Infrastructure

on:
  push:
    branches:
      - main
    paths:
      - 'iac/**'
      - '.github/workflows/deploy-infrastructure.yml'
  workflow_dispatch:

env:
  AWS_REGION: us-east-1
  ENVIRONMENT_NAME: lab1

jobs:
  deploy-infrastructure:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Validate CloudFormation template
        run: |
          aws cloudformation validate-template \
            --template-body file://iac/cloudformation/infrastructure.yaml \
            --region ${{ env.AWS_REGION }}

      - name: Deploy CloudFormation Stack
        run: bash scripts/deploy-iac.sh
        env:
          STACK_NAME: akad-bud-lab1-stack
          TEMPLATE_PATH: iac/cloudformation/infrastructure.yaml
          AWS_REGION: ${{ env.AWS_REGION }}
          ENVIRONMENT_NAME: ${{ env.ENVIRONMENT_NAME }}
          CONTAINER_IMAGE: ${{ secrets.ECR_IMAGE_URI }}

      - name: Get Stack Outputs
        run: |
          ALB_DNS=$(aws cloudformation describe-stacks \
            --stack-name akad-bud-lab1-stack \
            --region ${{ env.AWS_REGION }} \
            --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
            --output text)
          echo "ALB_DNS=$ALB_DNS" >> $GITHUB_ENV

      - name: Post deployment summary
        run: |
          echo "## Infrastructure Deployment Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "✅ CloudFormation stack deployed successfully" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Stack Details:**" >> $GITHUB_STEP_SUMMARY
          echo "- Stack Name: akad-bud-lab1-stack" >> $GITHUB_STEP_SUMMARY
          echo "- Region: ${{ env.AWS_REGION }}" >> $GITHUB_STEP_SUMMARY
          echo "- ALB DNS: ${{ env.ALB_DNS }}" >> $GITHUB_STEP_SUMMARY
```

4. Clique em **Commit changes**

### Passo 3: Crie a segunda workflow (Application)
1. Clique em **Add file** → **Create new file**
2. Caminho: `.github/workflows/deploy-application.yml`
3. Cole o conteúdo abaixo:

```yaml
name: Deploy Application

on:
  push:
    branches:
      - main
    paths:
      - 'src/**'
      - 'public/**'
      - 'Dockerfile'
      - 'package.json'
      - 'next.config.js'
      - 'tsconfig.json'
      - '.github/workflows/deploy-application.yml'
  workflow_dispatch:

env:
  AWS_REGION: us-east-1
  AWS_ACCOUNT_ID: 010438495533
  ECR_REPO_NAME: akad-bud-lab1
  CLUSTER_NAME: lab1-cluster
  SERVICE_NAME: lab1-service

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to ECR
        run: |
          aws ecr get-login-password --region ${{ env.AWS_REGION }} | \
            docker login --username AWS --password-stdin ${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.${{ env.AWS_REGION }}.amazonaws.com

      - name: Build Docker image
        run: |
          docker build -t ${{ env.ECR_REPO_NAME }}:${{ github.sha }} .
          docker tag ${{ env.ECR_REPO_NAME }}:${{ github.sha }} ${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.${{ env.AWS_REGION }}.amazonaws.com/${{ env.ECR_REPO_NAME }}:${{ github.sha }}
          docker tag ${{ env.ECR_REPO_NAME }}:${{ github.sha }} ${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.${{ env.AWS_REGION }}.amazonaws.com/${{ env.ECR_REPO_NAME }}:latest

      - name: Create ECR repository if not exists
        run: |
          aws ecr describe-repositories \
            --repository-names ${{ env.ECR_REPO_NAME }} \
            --region ${{ env.AWS_REGION }} || \
          aws ecr create-repository \
            --repository-name ${{ env.ECR_REPO_NAME }} \
            --region ${{ env.AWS_REGION }}

      - name: Push image to ECR
        run: |
          docker push ${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.${{ env.AWS_REGION }}.amazonaws.com/${{ env.ECR_REPO_NAME }}:${{ github.sha }}
          docker push ${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.${{ env.AWS_REGION }}.amazonaws.com/${{ env.ECR_REPO_NAME }}:latest

      - name: Get ECS task definition
        run: |
          TASK_DEF=$(aws ecs describe-services \
            --cluster ${{ env.CLUSTER_NAME }} \
            --services ${{ env.SERVICE_NAME }} \
            --region ${{ env.AWS_REGION }} \
            --query 'services[0].taskDefinition' \
            --output text)
          echo "TASK_DEF=$TASK_DEF" >> $GITHUB_ENV
          
          aws ecs describe-task-definition \
            --task-definition $TASK_DEF \
            --region ${{ env.AWS_REGION }} \
            --query 'taskDefinition' \
            --output json > task-definition.json

      - name: Update task definition with new image
        run: |
          jq ".containerDefinitions[0].image = \"${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.${{ env.AWS_REGION }}.amazonaws.com/${{ env.ECR_REPO_NAME }}:${{ github.sha }}\" | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)" task-definition.json > new-task-definition.json
          cat new-task-definition.json

      - name: Register new task definition
        run: |
          aws ecs register-task-definition \
            --region ${{ env.AWS_REGION }} \
            --cli-input-json file://new-task-definition.json > registered-task-def.json
          
          TASK_DEF_ARN=$(jq -r '.taskDefinition.taskDefinitionArn' registered-task-def.json)
          echo "NEW_TASK_DEF_ARN=$TASK_DEF_ARN" >> $GITHUB_ENV

      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster ${{ env.CLUSTER_NAME }} \
            --service ${{ env.SERVICE_NAME }} \
            --task-definition ${{ env.NEW_TASK_DEF_ARN }} \
            --region ${{ env.AWS_REGION }}

      - name: Wait for service to stabilize
        run: |
          aws ecs wait services-stable \
            --cluster ${{ env.CLUSTER_NAME }} \
            --services ${{ env.SERVICE_NAME }} \
            --region ${{ env.AWS_REGION }}

      - name: Get deployment info
        run: |
          aws ecs describe-services \
            --cluster ${{ env.CLUSTER_NAME }} \
            --services ${{ env.SERVICE_NAME }} \
            --region ${{ env.AWS_REGION }} \
            --query 'services[0]' > service-info.json
          
          ALB_DNS=$(aws cloudformation describe-stacks \
            --stack-name akad-bud-lab1-stack \
            --region ${{ env.AWS_REGION }} \
            --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
            --output text)
          echo "ALB_DNS=$ALB_DNS" >> $GITHUB_ENV

      - name: Post deployment summary
        run: |
          echo "## Application Deployment Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "✅ Application deployed successfully to ECS" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Deployment Details:**" >> $GITHUB_STEP_SUMMARY
          echo "- Image: ${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.${{ env.AWS_REGION }}.amazonaws.com/${{ env.ECR_REPO_NAME }}:${{ github.sha }}" >> $GITHUB_STEP_SUMMARY
          echo "- Cluster: ${{ env.CLUSTER_NAME }}" >> $GITHUB_STEP_SUMMARY
          echo "- Service: ${{ env.SERVICE_NAME }}" >> $GITHUB_STEP_SUMMARY
          echo "- URL: http://${{ env.ALB_DNS }}" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Task Definition:** ${{ env.NEW_TASK_DEF_ARN }}" >> $GITHUB_STEP_SUMMARY
```

4. Clique em **Commit changes**

---

## 📋 Opção 2: Gerar novo token com `workflow` scope

Se preferir fazer push via git:

1. Acesse: https://github.com/settings/tokens
2. Clique em **Generate new token** (classic)
3. Marque os scopes:
   - ✅ `repo` (todos)
   - ✅ `workflow`
   - ✅ `write:packages`
4. Clique em **Generate token**
5. Copie o token novo
6. Execute:

```bash
cd /bud/.openclaw/workspace/akad-bud-lab1

# Remova o remote antigo
git remote remove origin

# Adicione com novo token
git remote add origin https://<SEU_NOVO_TOKEN>@github.com/karloslopesakad/akad-bud-lab1.git

# Faça push dos workflows
git add .github/
git commit -m "✅ Add GitHub Actions CI/CD pipelines"
git push origin main
```

---

## ✅ Verificação

Depois que os workflows forem adicionados:

1. Acesse: https://github.com/karloslopesakad/akad-bud-lab1/actions
2. Você deve ver:
   - ✅ `Deploy Infrastructure` workflow
   - ✅ `Deploy Application` workflow

3. Para testar:
   - Faça um commit na pasta `iac/` → dispara Infrastructure
   - Faça um commit na pasta `src/` → dispara Application

---

## 🎯 Próximos Passos

Depois de adicionar os workflows:

1. Adicione os 4 secrets do GitHub (veja `GITHUB_SECRETS_SETUP.md`)
2. Faça commit em algum arquivo para testar o pipeline
3. Monitore em **Actions** tab
