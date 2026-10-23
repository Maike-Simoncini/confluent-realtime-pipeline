# 🚀 Pipeline Real-Time End-to-End com Confluent Cloud

Pipeline de streaming de pagamentos em tempo real construído com arquitetura orientada a eventos (EDA), integrando PostgreSQL, Confluent Cloud (Kafka), Debezium CDC, Apache Flink SQL e detecção de fraude automatizada.

## 🏗️ Arquitetura do Pipeline

```text
[ PostgreSQL / Neon ] 
       │ (CDC - Debezium)
       ▼
[ Confluent Cloud Kafka (Tópicos Avro) ]
       │
       ▼
[ Apache Flink SQL (Enriquecimento + Janela MATCH_RECOGNIZE) ]
       │
       ├──► [ Tópico de Alerta de Fraude: desafio.fraud.detected ]
       └──► [ Consumidores Finais ]

```

📂 O Que Cada Camada Faz (Com Evidências)
1️⃣ Camada 1 — Fundação
 * O que faz: Criação do ambiente isolado, cluster Kafka gerenciado (AWS / us-east-1) e isolamento estrito de identidades via Service Accounts (Princípio do Menor Privilégio).
 * Evidência de execução:
```
$ confluent iam service-account list
+-------------------+----------------------+
|     NAME          |          ID          |
+-------------------+----------------------+
| desafio-producer  | sa-xxxxxx            |
| desafio-consumer  | sa-yyyyyy            |
+-------------------+----------------------+
```

2️⃣ Camada 2 — Contrato de Dados
 * O que faz: Padronização e versionamento de contratos de mensagens utilizando o Confluent Schema Registry com formato Avro e política de compatibilidade BACKWARD.
 * Evidência de evolução de schema:

```
$ confluent schema-registry schema test-compatibility --subject "desafio.payments-value" --schema schemas/payment-schema.json
Compatibility: SUCCESS (Campo novo aceito com valor default)
```

3️⃣ Camada 3 — Ingestão (CDC)
 * O que faz: Extração contínua de mudanças (CDC) do banco de dados relacional (PostgreSQL) usando o conector PostgresCdcSourceV2 sem sobrecarregar a origem.
 * Carga de Seed: 200 customers | 240 accounts | 320 cards | 60 merchants | 2000 transactions.
 * Evidência de captura de eventos (Envelope Debezium):

```
{
  "before": null,
  "after": {
    "transaction_id": "tx_99812",
    "card_id": "card_4021",
    "amount": 1500.00,
    "timestamp": 1718000000000
  },
  "op": "c"
}
```

4️⃣ Camada 4 — Processamento (Flink SQL)
 * O que faz: Processamento analítico em tempo real com Apache Flink SQL, aplicando regras de janela temporal (MATCH_RECOGNIZE) para identificar padrões suspeitos de fraude (ex: 3 transações no mesmo cartão em menos de 60 segundos).
 * Evidência de alerta disparado:

```
{
  "card_id": "card_4021",
  "alert_reason": "VELOCITY_FRAUD_3_TX_60S",
  "transaction_count": 3,
  "window_end": "2026-06-15T12:05:30.100Z"
}
```

5️⃣ Camada 5 — Operação & Negócio
 * Observabilidade: Monitoramento de picos de received_bytes e lag de consumo via Confluent Metrics API.
 * Segurança: Isolamento por Service Accounts com ACLs granulares restritas ao prefixo desafio-*.
 * Custos: Otimização do cluster Basic e uso de retenção de tópicos adequada para evitar cobranças excedentes de armazenamento.
 * Confiabilidade: Garantia de idempotência implementada no código consumidor para mitigar entrega at-least-once.

💰 Custo Total
 * Custo estimado do período de testes: <US$ 2.50> (Baseado no consumo por hora do cluster Basic e do Confluent Flink Serverless).

👨‍💻 Autor
 * Desenvolvido por Maike.

