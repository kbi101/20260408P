-- Migration: V9__create_simulator_tables
-- Purpose: Establish tables for simulation accounts, sessions, and trades

-- 1. Simulation Accounts Table
CREATE TABLE IF NOT EXISTS quant.simulation_accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    balance DECIMAL NOT NULL DEFAULT 100000.00,
    initial_balance DECIMAL NOT NULL DEFAULT 100000.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Simulation Sessions Table
CREATE TABLE IF NOT EXISTS quant.simulation_sessions (
    session_id UUID PRIMARY KEY,
    account_id UUID NOT NULL REFERENCES quant.simulation_accounts(account_id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    strategy_name TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    initial_cash DECIMAL NOT NULL,
    current_cash DECIMAL NOT NULL,
    status TEXT NOT NULL, -- RUNNING, COMPLETED, STOPPED, FAILED
    total_trades INT DEFAULT 0,
    win_rate DECIMAL DEFAULT 0,
    net_profit DECIMAL DEFAULT 0,
    sharpe_ratio DECIMAL DEFAULT 0,
    max_drawdown DECIMAL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Simulation Trades Table
CREATE TABLE IF NOT EXISTS quant.simulation_trades (
    trade_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES quant.simulation_sessions(session_id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    action TEXT NOT NULL, -- BUY, SELL
    quantity DECIMAL NOT NULL,
    price DECIMAL NOT NULL,
    pnl DECIMAL DEFAULT 0,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 4. Initial Seed for Simulation Account
INSERT INTO quant.simulation_accounts (account_id, name, balance, initial_balance)
VALUES ('00000000-0000-0000-0000-000000000001', 'Default Sim Account', 100000.00, 100000.00)
ON CONFLICT (account_id) DO NOTHING;
