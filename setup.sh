#!/bin/bash
set -e

echo "=== Carregando variáveis de ambiente ==="
if [ ! -f .env ]; then
  echo "Erro: Arquivo .env não encontrado. Copie .env.example para .env e preencha as credenciais."
  exit 1
fi
source .env

echo "=== 1. Camada de Fundação: Configurando Ambiente e Cluster ==="
# Criação ou verificação do ambiente e cluster Confluent
echo "Usando Environment ID: $CONFLUENT_ENVIRONMENT_ID e Cluster ID:$CONFLUENT_CLUSTER_ID"

# Criando Service Accounts e ACLs de segurança
echo "Criando Service Accounts para Producer e Consumer..."
PRODUCER_SA_ID=$(confluent iam service-account create desafio-producer --description "Producer Service Account" -o json | jq -r '.id')
CONSUMER_SA_ID=$(confluent iam service-account create desafio-consumer --description "Consumer Service Account" -o json | jq -r '.id')

echo "Aplicando ACLs de escrita e leitura..."
confluent kafka acl create --producer --service-account "$PRODUCER_SA_ID" --topic "desafio-" --prefix
confluent kafka acl create --consumer --service-account "$CONSUMER_SA_ID" --topic "desafio-" --prefix --group "desafio-"

echo "=== 2. Camada de Contrato: Registrando Schema Avro ==="
confluent schema-registry schema create \
  --subject "desafio.payments-value" \
  --schema schemas/payment-schema.json \
  --type AVRO

echo "=== 3. Camada de Ingestão: Subindo o Conector CDC (Postgres) ==="
confluent connect cluster create --cluster-id "$CONFLUENT_CLUSTER_ID" --config-file connectors/cdc.json

echo "=== Pipeline configurado com sucesso! ==="
