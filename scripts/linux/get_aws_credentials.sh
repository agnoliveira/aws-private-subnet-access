#!/bin/bash

# Mude o secret_name e a região
SECRET_NAME="My-Secret"
REGION="us-east-1"

# Obtém o JSON do secret
SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query SecretString \
    --output text)

# Faz export das variáveis extraídas do JSON
export AWS_ACCESS_KEY_ID=$(echo "$SECRET_JSON" | jq -r '.AWS_ACCESS_KEY_ID')
export AWS_SECRET_ACCESS_KEY=$(echo "$SECRET_JSON" | jq -r '.AWS_SECRET_ACCESS_KEY')

# Se o secret tiver token temporário (caso use credenciais STS)
if echo "$SECRET_JSON" | jq -e '.AWS_SESSION_TOKEN' >/dev/null; then
    export AWS_SESSION_TOKEN=$(echo "$SECRET_JSON" | jq -r '.AWS_SESSION_TOKEN')
fi

# Define região padrão se quiser
export AWS_DEFAULT_REGION=$REGION

echo "Credenciais carregadas com sucesso para a região $AWS_DEFAULT_REGION."
