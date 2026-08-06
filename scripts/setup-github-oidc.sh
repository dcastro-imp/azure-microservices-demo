#!/bin/bash
# One-time setup: connects THIS repo's GitHub Actions workflows to YOUR OWN
# Azure subscription via OIDC (no passwords/secrets stored anywhere) — see
# docs/AZURE-LEARNING-GUIDE.md and infra/README.md for how this works and
# why. Safe to re-run; it's idempotent for the Azure AD pieces, and updates
# GitHub Environments/variables if they already exist.
#
# Requires: az (logged in: az login), gh (logged in: gh auth login), and
# that you've already forked/cloned this repo under your own GitHub account
# (or have write access to the repo you're pointing this at).
set -e

read -p "GitHub owner (usuario u organizacion, ej. 'tu-usuario'): " GITHUB_OWNER
read -p "Nombre del repo (ej. 'azure-microservices-demo'): " REPO_NAME
read -p "Resource group que este pipeline puede administrar (ej. rg-microservices): " TARGET_RG
read -p "Nombre del ACR (debe ser unico globalmente, ej. acrmicro$(whoami)): " ACR_NAME_INPUT
read -p "Que environments configurar? (dev / dev,staging,prod) [dev]: " ENVS
ENVS=${ENVS:-dev}

REPO="$GITHUB_OWNER/$REPO_NAME"
APP_NAME="github-actions-$REPO_NAME"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
CURRENT_GH_USER=$(gh api user --jq .login)

echo ""
echo "=== 1. Creando (o reusando) el App Registration '$APP_NAME' ==="
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
if [ -z "$APP_ID" ]; then
  APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
  az ad sp create --id "$APP_ID" > /dev/null
  echo "Creado: $APP_ID"
else
  echo "Ya existia: $APP_ID"
fi

echo ""
echo "=== 2. Resource group destino ==="
if ! az group show --name "$TARGET_RG" &>/dev/null; then
  az group create --name "$TARGET_RG" --location centralus > /dev/null
  echo "Resource group '$TARGET_RG' creado."
fi
RG_ID=$(az group show --name "$TARGET_RG" --query id -o tsv)

echo ""
echo "=== 3. Otorgando permisos (Owner, solo sobre $TARGET_RG) ==="
az role assignment create --assignee "$APP_ID" --role Owner --scope "$RG_ID" 2>/dev/null || echo "(ya existia)"

IFS=',' read -ra ENV_ARRAY <<< "$ENVS"
for ENV in "${ENV_ARRAY[@]}"; do
  echo ""
  echo "=== Configurando ambiente '$ENV' ==="

  echo "--- Federated credential (formato estandar) ---"
  az ad app federated-credential create --id "$APP_ID" --parameters "{
    \"name\": \"github-$ENV\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:environment:$ENV\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" 2>/dev/null || echo "(ya existia)"

  echo "--- GitHub Environment '$ENV' ---"
  if [ "$ENV" = "dev" ]; then
    gh api --method PUT "repos/$REPO/environments/$ENV" > /dev/null
  else
    # staging/prod: requiere aprobacion manual de quien corrio este setup.
    gh api --method PUT "repos/$REPO/environments/$ENV" \
      -f "reviewers[][type]=User" -F "reviewers[][id]=$(gh api user --jq .id)" > /dev/null
  fi

  echo "--- Variables del environment '$ENV' ---"
  gh variable set AZURE_CLIENT_ID --env "$ENV" --body "$APP_ID" --repo "$REPO"
  gh variable set AZURE_TENANT_ID --env "$ENV" --body "$TENANT_ID" --repo "$REPO"
  gh variable set AZURE_SUBSCRIPTION_ID --env "$ENV" --body "$SUBSCRIPTION_ID" --repo "$REPO"
  gh variable set ACR_NAME --env "$ENV" --body "$ACR_NAME_INPUT" --repo "$REPO"

  echo "Ambiente '$ENV' listo."
done

echo ""
echo "=== Listo ==="
echo "App Registration: $APP_ID"
echo ""
echo "IMPORTANTE: si al correr el workflow ves el error AADSTS700213 (federated"
echo "credential no coincide), revisa el log del paso 'Login to Azure' del run"
echo "fallido — GitHub imprime el 'subject claim' EXACTO que envio. Crea un"
echo "federated credential adicional con ese valor exacto:"
echo ""
echo "  az ad app federated-credential create --id $APP_ID --parameters '{"
echo "    \"name\": \"github-<env>-alt\","
echo "    \"issuer\": \"https://token.actions.githubusercontent.com\","
echo "    \"subject\": \"<pega-aqui-el-subject-exacto-del-log>\","
echo "    \"audiences\": [\"api://AzureADTokenExchange\"]"
echo "  }'"
echo ""
echo "(Esto pasa porque el formato del 'subject' de GitHub puede variar segun"
echo "el tipo de cuenta/repo — ver docs/AZURE-LEARNING-GUIDE.md.)"
