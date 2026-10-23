-- Criação da tabela de transações com base no tópico CDC Avro
CREATE TABLE transactions (
    transaction_id STRING,
    card_id STRING,
    account_id STRING,
    merchant_id STRING,
    amount DECIMAL(15, 2),
    `timestamp` BIGINT,
    event_time AS TO_TIMESTAMP_LTZ(`timestamp`, 3),
    WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
    'connector' = 'confluent',
    'topic' = 'public.transactions',
    'value.format' = 'avro-registry'
);

-- Tópico de saída para fraudes detectadas
CREATE TABLE fraud_alerts (
    card_id STRING,
    alert_reason STRING,
    transaction_count BIGINT,
    window_end TIMESTAMP(3)
) WITH (
    'connector' = 'confluent',
    'topic' = 'desafio.fraud.detected',
    'value.format' = 'json'
);

-- Regra de Fraude: 3 transações no mesmo cartão em menos de 60 segundos
INSERT INTO fraud_alerts
SELECT 
    card_id,
    'VELOCITY_FRAUD_3_TX_60S' AS alert_reason,
    total_tx,
    window_end
FROM transactions
MATCH_RECOGNIZE (
    PARTITION BY card_id
    ORDER BY event_time
    MEASURES
        COUNT(T.transaction_id) as total_tx,
        LAST(T.event_time) as window_end
    PATTERN (T{3,}?)
    WITHIN INTERVAL '60' SECOND
    DEFINE
        T AS TRUE
) AS mr;
