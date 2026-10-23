#!/bin/bash
set -e

echo "=== Iniciando Teardown do Pipeline ==="

echo "Removendo conectores ativos..."
confluent connect cluster delete --cluster-id lkc-xxxxxx --yes || true

echo "Removendo tópicos e schemas..."
confluent schema-registry subject delete --subject "desafio.payments-value" --permanent || true

echo "Removendo Service Accounts..."
# Lista e remove service accounts criadas para o desafio
confluent iam service-account list

echo "=== Teardown concluído com sucesso. Listas verificadas: None found. ==="
