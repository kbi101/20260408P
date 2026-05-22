-- Migration: V10__create_market_overview_log
-- Purpose: Establish tables for storing historical pre-market checklist and regime outputs

CREATE TABLE IF NOT EXISTS quant.market_overview_log (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    es_price DECIMAL,
    es_change_pct DECIMAL,
    nq_price DECIMAL,
    nq_change_pct DECIMAL,
    rty_price DECIMAL,
    rty_change_pct DECIMAL,
    vix_price DECIMAL,
    vix_change_pct DECIMAL,
    f1_price DECIMAL,
    f2_price DECIMAL,
    contango_pct DECIMAL,
    vix_regime TEXT,
    us10y_yield DECIMAL,
    us2y_yield DECIMAL,
    yield_spread DECIMAL,
    dxy_price DECIMAL,
    spy_spot DECIMAL,
    spy_0dte_gex DECIMAL,
    spy_call_wall DECIMAL,
    spy_put_wall DECIMAL,
    spy_pcr DECIMAL,
    raw_data JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_market_overview_log_timestamp ON quant.market_overview_log(timestamp DESC);
