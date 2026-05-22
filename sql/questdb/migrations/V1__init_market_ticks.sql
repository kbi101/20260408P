-- Baseline Schema for Market Data Store
-- Optimized for High-Frequency Ingestion

CREATE TABLE IF NOT EXISTS market_ticks (
    symbol SYMBOL CAPACITY 256 CACHE,
    side SYMBOL CAPACITY 2 CACHE,
    price DOUBLE,
    size DOUBLE,
    timestamp TIMESTAMP
) TIMESTAMP(timestamp) PARTITION BY DAY WAL;

-- Indexing for frequent lookups
ALTER TABLE market_ticks ALTER COLUMN symbol ADD INDEX;
