-- Migration: V7__add_fundamental_metrics_to_stock
-- Adds P/E Ratio, Beta, Market Sentiment, and Next Earnings Date columns to quant.stock table

ALTER TABLE quant.stock ADD COLUMN IF NOT EXISTS pe_ratio NUMERIC;
ALTER TABLE quant.stock ADD COLUMN IF NOT EXISTS beta NUMERIC;
ALTER TABLE quant.stock ADD COLUMN IF NOT EXISTS market_sentiment VARCHAR(50);
ALTER TABLE quant.stock ADD COLUMN IF NOT EXISTS next_earnings_date VARCHAR(50);
