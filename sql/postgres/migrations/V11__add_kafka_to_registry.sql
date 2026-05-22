-- Migration: V11__add_kafka_to_registry
-- Purpose: Seed the infrastructure registry with the default Apache Kafka configuration

INSERT INTO quant.infra_registry (name, type, provider, config, metadata, status)
VALUES (
    'Kafka Message Hub',
    'broker',
    'kafka',
    '{"host": "host.docker.internal:9094", "internal_host": "kafka:9092", "zookeeper_less": true}',
    '{"version": "3.7.0", "installation": "quantedge-kafka", "logs": "docker logs quantedge-kafka", "notes": "Event-driven day trading message bus and telemetry pipeline running in KRaft mode."}',
    'online'
) ON CONFLICT (name) DO NOTHING;
