-- V2__seed_infrastructure_components.sql
-- Seed the registry with the current Redis and QuestDB configuration

-- 1. Register QuestDB (Time-series tier)
INSERT INTO quant.infra_registry (name, type, provider, config, metadata, status)
VALUES (
    'QuestDB Historical Store',
    'database',
    'questdb',
    '{"host": "host.docker.internal", "port": 8812, "user": "admin", "password": "quest", "web_console": "http://localhost:3103"}',
    '{"version": "7.3.9", "notes": "Time-series database for high-frequency tick data storage."}',
    'online'
) ON CONFLICT (name) DO NOTHING;

-- 2. Register Redis Cache (Log & KV tier)
INSERT INTO quant.infra_registry (name, type, provider, config, metadata, status)
VALUES (
    'Ingestion Log Stream',
    'cache',
    'redis',
    '{"host": "host.docker.internal", "port": 6379, "db_index": 0}',
    '{"version": "7.2.4", "notes": "Redis Streams used for real-time Black Box log replay."}',
    'online'
) ON CONFLICT (name) DO NOTHING;

-- 3. Register Temporal (Orchestration tier)
INSERT INTO quant.infra_registry (name, type, provider, config, metadata, status)
VALUES (
    'Temporal Orchestrator',
    'worker',
    'temporal',
    '{"host": "temporal:7233", "web_console": "http://localhost:3104", "namespace": "default"}',
    '{"version": "v1.24.3", "installation": "temporal-server", "logs": "docker logs temporal", "notes": "Stateful workflow orchestration engine."}',
    'online'
) ON CONFLICT (name) DO NOTHING;

-- 4. Register DuckDB (OLAP Analytics tier)
INSERT INTO quant.infra_registry (name, type, provider, config, metadata, status)
VALUES (
    'DuckDB Analytics Kernel',
    'database',
    'duckdb',
    '{"host": "embedded:in-process", "database": "db/options_analytics.db"}',
    '{"version": "v1.1.3", "installation": "python module (duckdb)", "notes": "OLAP analytics engine for options structures and liquidity ledgers. Running in-process inside Volatility Lab API."}',
    'online'
) ON CONFLICT (name) DO NOTHING;
