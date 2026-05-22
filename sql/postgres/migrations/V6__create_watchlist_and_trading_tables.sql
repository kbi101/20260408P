-- Migration: V6__create_watchlist_and_trading_tables
-- Purpose: Establish tables for Watch List, Portfolio, and Transactions

-- 1. Portfolio Table
CREATE TABLE IF NOT EXISTS quant.portfolio (
    symbol TEXT PRIMARY KEY,
    shares DECIMAL NOT NULL DEFAULT 0,
    avg_price DECIMAL NOT NULL DEFAULT 0,
    market_value DECIMAL,
    last_price DECIMAL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Watch List Table
CREATE TABLE IF NOT EXISTS quant.watchlist (
    symbol TEXT PRIMARY KEY,
    priority TEXT NOT NULL DEFAULT 'Medium', -- High, Medium, Low
    thesis TEXT,
    intelligence JSONB DEFAULT '{}'::jsonb,  -- Automated insights/signals
    metadata JSONB DEFAULT '{}'::jsonb,      -- UI-specific or legacy info
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Transactions Table
CREATE TABLE IF NOT EXISTS quant.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol TEXT NOT NULL,
    action TEXT NOT NULL,         -- BUY, SELL
    quantity DECIMAL NOT NULL,
    price DECIMAL NOT NULL,
    commission DECIMAL DEFAULT 0,
    account_id TEXT,             -- Brokerage account reference
    provider TEXT,               -- IBKR, Schwab, etc.
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 4. Initial Seed for Watch List (SPY)
INSERT INTO quant.watchlist (symbol, priority, thesis)
VALUES ('SPY', 'High', 'Core index tracker. ML Engine prediction active.')
ON CONFLICT (symbol) DO NOTHING;

-- 5. Seed initial Portfolio (Matching hardcoded example if needed)
INSERT INTO quant.portfolio (symbol, shares, avg_price)
VALUES 
    ('AAPL', 100, 150.00),
    ('SPY', 50, 480.00)
ON CONFLICT (symbol) DO NOTHING;

-- 6. Trigger to ensure Portfolio items are always in Watch List
CREATE OR REPLACE FUNCTION quant.sync_portfolio_to_watchlist()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO quant.watchlist (symbol, priority, thesis)
    VALUES (NEW.symbol, 'High', 'Active Portfolio Position (Automatic)')
    ON CONFLICT (symbol) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_portfolio_watchlist
AFTER INSERT OR UPDATE ON quant.portfolio
FOR EACH ROW EXECUTE FUNCTION quant.sync_portfolio_to_watchlist();
