-- V8__create_fundamentals_tables.sql
-- Creates the SEC EDGAR raw landing zone and normalized serving layer
-- for the Fundamentals Dashboard pipeline (spec: docs/research/030-fundamentals-pipeline-backend.md)

-- ── Landing Zone: Raw JSONB Payload ──────────────────────────────────────────
-- Stores the full companyfacts JSON from SEC EDGAR per ticker.
-- One row per ticker; upserted on each backfill or daily re-fetch.
CREATE TABLE IF NOT EXISTS quant.sec_raw_facts (
    ticker          VARCHAR(10) PRIMARY KEY REFERENCES quant.stock(symbol) ON DELETE CASCADE,
    cik             VARCHAR(10)  NOT NULL,
    raw_payload     JSONB        NOT NULL,
    last_fetched_at TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    last_filing_at  DATE         -- latest 10-Q/10-K filing date seen in Submissions API
);

COMMENT ON TABLE quant.sec_raw_facts IS
    'Raw JSONB landing zone from SEC EDGAR companyfacts API. One row per ticker.';

-- ── Serving Layer: Normalized Financial Facts ─────────────────────────────────
-- Parsed, structured rows from the JSONB payload.
-- Each row is one GAAP concept × one fiscal period × one ticker.
CREATE TABLE IF NOT EXISTS quant.financial_facts (
    fact_id         SERIAL PRIMARY KEY,
    ticker          VARCHAR(10)    NOT NULL REFERENCES quant.stock(symbol) ON DELETE CASCADE,
    concept         VARCHAR(150)   NOT NULL,  -- XBRL US-GAAP concept name
    form_type       VARCHAR(10)    NOT NULL,  -- '10-Q' or '10-K'
    fiscal_year     INT            NOT NULL,
    fiscal_quarter  INT            NOT NULL,  -- 1/2/3 for Q; 4 for annual 10-K
    period_end_date DATE           NOT NULL,
    value           NUMERIC(24, 4) NOT NULL,
    inserted_at     TIMESTAMPTZ    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_fact_period UNIQUE (ticker, concept, fiscal_year, fiscal_quarter)
);

COMMENT ON TABLE quant.financial_facts IS
    'Normalized GAAP facts extracted from quant.sec_raw_facts JSONB.';
COMMENT ON COLUMN quant.financial_facts.fiscal_quarter IS
    '1=Q1, 2=Q2, 3=Q3, 4=Annual (10-K)';

-- ── Indexes for fast API lookups and DuckDB analytical joins ──────────────────
CREATE INDEX IF NOT EXISTS idx_fin_facts_lookup
    ON quant.financial_facts (ticker, fiscal_year DESC, fiscal_quarter);

CREATE INDEX IF NOT EXISTS idx_fin_facts_concept
    ON quant.financial_facts (concept, ticker);
