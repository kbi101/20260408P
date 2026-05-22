-- V12__create_journal_tables.sql
-- Create database schema for Cognitive Cockpit Trading Journal

-- 1. Brokerage Accounts
CREATE TABLE IF NOT EXISTS quant.brokerage_accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brokerage_name TEXT NOT NULL,         -- e.g., 'Simulator', 'Schwab', 'Interactive Brokers'
    account_number TEXT NOT NULL,         -- e.g., 'Sim-01', 'U1234567'
    display_name TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (brokerage_name, account_number)
);

-- Seed default accounts
INSERT INTO quant.brokerage_accounts (account_id, brokerage_name, account_number, display_name)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'Simulator', 'Default-Sim', 'Default Simulation Account')
ON CONFLICT (brokerage_name, account_number) DO NOTHING;

-- 2. Journal Pre-Trade Plans
CREATE TABLE IF NOT EXISTS quant.journal_plans (
    plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    symbol TEXT NOT NULL,
    timeframe TEXT NOT NULL,             -- 'DAY_TRADE', 'SWING', 'LONG_TERM'
    strategy_name TEXT NOT NULL,          -- '5-min ORB', 'Mean Reversion', 'Freestyle', etc.
    planned_entry DECIMAL NOT NULL,
    planned_stop DECIMAL NOT NULL,
    planned_target DECIMAL NOT NULL,
    planned_risk DECIMAL NOT NULL,
    target_r_multiple DECIMAL NOT NULL,
    checklist_responses JSONB DEFAULT '{}'::jsonb,
    locked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Journal Positions
CREATE TABLE IF NOT EXISTS quant.journal_positions (
    position_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID REFERENCES quant.journal_plans(plan_id) ON DELETE SET NULL,
    account_id UUID NOT NULL REFERENCES quant.brokerage_accounts(account_id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PLANNED', -- 'PLANNED', 'ACTIVE', 'CLOSED'
    avg_entry_price DECIMAL,
    avg_exit_price DECIMAL,
    total_shares DECIMAL DEFAULT 0,
    realized_pnl DECIMAL DEFAULT 0,
    actual_r_multiple DECIMAL DEFAULT 0,
    rule_adherence_score INT DEFAULT 100,
    psychology_tags JSONB DEFAULT '[]'::jsonb, -- Array of emoji strings
    entry_time TIMESTAMP WITH TIME ZONE,
    exit_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Custom Metadata Fields (Freestyle flexibility layer)
CREATE TABLE IF NOT EXISTS quant.journal_custom_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    position_id UUID NOT NULL REFERENCES quant.journal_positions(position_id) ON DELETE CASCADE,
    key TEXT NOT NULL,                   -- e.g., 'coffee_intake', 'market_sentiment'
    value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (position_id, key)
);

-- 5. Notebook Entries / Markdown summaries
CREATE TABLE IF NOT EXISTS quant.journal_notes (
    note_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    position_id UUID REFERENCES quant.journal_positions(position_id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content_markdown TEXT NOT NULL,
    attachment_paths JSONB DEFAULT '[]'::jsonb, -- JSON string list of local paths
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
