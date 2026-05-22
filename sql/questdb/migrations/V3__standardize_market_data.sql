-- Standardize Market Data Schema
-- Adds support for multiple intervals and market sessions
-- Enables Deduplication for data integrity

-- 1. Add missing columns to support multiple timeframes
ALTER TABLE market_data ADD COLUMN interval SYMBOL CAPACITY 16 CACHE;
ALTER TABLE market_data ADD COLUMN session SYMBOL CAPACITY 16 CACHE;

-- 2. Configure Deduplication logic
-- This ensures that only one record per symbol/timestamp/interval is kept
-- Note: Requires QuestDB 7.3+
ALTER TABLE market_data SET DEDUP UPSERT KEYS(timestamp, symbol, interval);

-- 3. Cleanup existing index if redundant (symbol is already part of dedup key)
-- But keeping it for query performance is still recommended in QuestDB
ALTER TABLE market_data ALTER COLUMN symbol ADD INDEX;
