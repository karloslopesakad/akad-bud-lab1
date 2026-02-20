# 🔐 GitHub Secrets Setup

O repositório foi criado com sucesso, mas os secrets precisam ser adicionados manualmente.

**Repositório**: https://github.com/karloslopesakad/akad-bud-lab1

## Como adicionar os secrets:

### Passo 1: Ir para Settings do Repositório
1. Acesse https://github.com/karloslopesakad/akad-bud-lab1
2. Clique em **Settings**
3. No menu lateral, vá em **Secrets and variables** → **Actions**

### Passo 2: Adicione cada secret clicando em "New repository secret"

#### Secret 1: AWS_ACCESS_KEY_ID
```
Name: AWS_ACCESS_KEY_ID
Value: <Your AWS Access Key from credentials>
```

#### Secret 2: AWS_SECRET_ACCESS_KEY
```
Name: AWS_SECRET_ACCESS_KEY
Value: <Your AWS Secret Key from credentials>
```

#### Secret 3: AWS_SESSION_TOKEN
```
Name: AWS_SESSION_TOKEN
Value: <Your AWS Session Token from credentials>
```

#### Secret 4: ECR_IMAGE_URI
```
Name: ECR_IMAGE_URI
Value: 010438495533.dkr.ecr.us-east-1.amazonaws.com/akad-bud-lab1:latest
```

**Os valores exatos foram compartilhados via mensagem privada de Slack/Teams.**

### Passo 3: Criar novo token com `workflow` scope (Opcional, se quiser CI/CD)

Se quiser adicionar as pipelines do GitHub Actions, você precisa de um token com permissão de `workflow`:

1. Vá em https://github.com/settings/tokens
2. Clique em **Generate new token**
3. Marque os scopes:
   - `repo` (completo)
   - `workflow`
   - `write:packages`
4. Gere o token
5. Use este novo token para fazer push dos workflows

### Passo 4: Adicionar as pipelines de CI/CD

Copie os workflows dos arquivos:
- `.github/workflows/deploy-infrastructure.yml` (criado em `/bud/.openclaw/workspace/akad-bud-lab1/.github/workflows/`)
- `.github/workflows/deploy-application.yml` (criado em `/bud/.openclaw/workspace/akad-bud-lab1/.github/workflows/`)

E faça push com um token que tenha `workflow` scope.

---

## ✅ Status Atual

- ✅ Repositório criado: https://github.com/karloslopesakad/akad-bud-lab1
- ✅ Codebase completo em main branch
- ✅ Scripts de deployment em `/scripts/`
- ⏳ Secrets precisam ser adicionados manualmente (ou com novo token)
- ⏳ Workflows precisam ser adicionados (requer token com `workflow` scope)

---

## 📝 Próximos Passos

1. Adicionar os 4 secrets acima
2. Opcionalmente, gerar novo token e adicionar workflows
3. Fazer push de commits para `main` para triggar pipelines
4. Monitorar execução em **Actions** tab
