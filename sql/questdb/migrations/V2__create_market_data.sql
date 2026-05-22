-- OHLCV Market Data Schema
-- Optimized for Yahoo Finance 1-min interval ingestion

CREATE TABLE IF NOT EXISTS market_data (
    symbol SYMBOL CAPACITY 256 CACHE,
    provider SYMBOL CAPACITY 16 CACHE,
    open DOUBLE,
    high DOUBLE,
    low DOUBLE,
    close DOUBLE,
    volume DOUBLE,
    timestamp TIMESTAMP
) TIMESTAMP(timestamp) PARTITION BY DAY WAL;

-- Indexing for fast lookups by asset
ALTER TABLE market_data ALTER COLUMN symbol ADD INDEX;
