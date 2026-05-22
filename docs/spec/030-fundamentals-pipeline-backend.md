# Fundamentals Data Pipeline — Backend Design

## Objective

Build a robust, low-maintenance SEC EDGAR ingestion pipeline that feeds real accounting data into the Fundamentals Dashboard. The design follows the existing QuantEdge ELT pattern: raw landing in PostgreSQL → normalized serving layer → DuckDB OLAP compute → REST API endpoints consumed by the frontend.

---

## 1. Architecture Overview

The pipeline integrates naturally with the existing dual-queue Temporal worker, the `quant` PostgreSQL schema, and the DuckDB analytical layer already used by the options engine.

```
[SEC EDGAR API (Free)]
       │
       │  Backfill: companyfacts/{CIK}.json  (one-shot, full history)
       │  Daily Sync: submissions/{CIK}.json (lightweight filing check)
       │  Rate limit: 10 RPS max · User-Agent header required
       ▼
┌─────────────────────────────────────────────────────────────┐
│  PostgreSQL · quant schema (existing DB: crystal_db)        │
│                                                             │
│  ├── quant.sec_raw_facts      (JSONB landing zone)          │
│  └── quant.financial_facts    (normalized serving layer)    │
└─────────────────────────────────────────────────────────────┘
       │
       ▼  (vectorized analytical compute, in-memory)
┌─────────────────────────────────────────────────────────────┐
│  DuckDB (existing pattern from options_engine)              │
│  · Reads from quant.financial_facts via postgres extension  │
│  · Computes FCF, ROIC, Net Debt/EBITDA, Interest Coverage   │
│  · Writes derived matrix to data/fundamentals/              │
│    ├── {ticker}_fundamentals_quarterly.parquet              │
│    └── {ticker}_fundamentals_annual.parquet                 │
└─────────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│  FastAPI (apps/api/main.py)                                 │
│  · GET /api/v1/fundamentals/{symbol}                        │
│  · GET /api/v1/fundamentals/{symbol}/kpis                   │
│  · POST /api/v1/fundamentals/backfill/{symbol}              │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. SEC EDGAR Integration Rules

The SEC EDGAR system is completely free but enforces two hard rules that will result in an **IP ban** if violated:

| Rule | Requirement |
|---|---|
| **User-Agent** | Must declare a descriptive header: `QuantEdge-Studio kepingbi.research@domain.com` |
| **Rate Limit** | Maximum **10 requests per second** — enforced via `time.sleep(0.15)` between requests |

### Core Endpoints

| Purpose | Endpoint |
|---|---|
| Ticker → CIK mapping | `https://www.sec.gov/files/company_tickers.json` |
| Full historical facts (backfill) | `https://data.sec.gov/api/xbrl/companyfacts/CIK{padded_cik}.json` |
| Latest filing list (daily sync) | `https://data.sec.gov/submissions/CIK{padded_cik}.json` |

The `companyfacts` payload for a single ticker delivers **10–20 years of structured GAAP accounting data in one request** — a major efficiency advantage over scraping quarterly reports.

---

## 3. Update Cadence

### Backfill (Run Once Per New Symbol)

Triggered manually or automatically when a new ticker is added to `quant.stock`. Pulls the full `companyfacts` JSON, lands it in `quant.sec_raw_facts`, then parses to `quant.financial_facts`.

**Trigger:** When a new symbol is added to Investment Targets (existing `quant.stock` table) and `sec_raw_facts` has no row for that ticker.

### Daily Sync (6:00 PM EST, M-F)

Pulls the lightweight **Submissions API** for each target symbol. Inspects the `filings.recent.form` array. If a new `10-Q` or `10-K` appears since the last recorded `last_fetched_at`, trigger a targeted re-parse of only that symbol's facts.

This avoids re-downloading the large `companyfacts` payload daily — the submissions check is ~10KB vs ~500KB for facts.

### Schedule ID: `fundamentals-daily-sync`
- Queue: `ingestion-tasks` (existing worker already registered)
- Time: **Daily M-F at 6:00 PM CST** (after market close)
- Workflow: `FundamentalsIngestionWorkflow`

---

## 4. Database Schema (PostgreSQL `quant` schema)

All tables live in the existing `quant` schema (DB: `crystal_db`). This avoids any schema proliferation and keeps the data co-located with `quant.stock`, `quant.pattern_result`, etc.

### Flyway Migration: `V8__create_fundamentals_tables.sql`

```sql
-- ── Landing Zone ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quant.sec_raw_facts (
    ticker          VARCHAR(10) PRIMARY KEY REFERENCES quant.stock(symbol) ON DELETE CASCADE,
    cik             VARCHAR(10) NOT NULL,
    raw_payload     JSONB NOT NULL,
    last_fetched_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_filing_at  DATE        -- tracks latest 10-Q/10-K date seen in Submissions API
);

-- ── Normalized Serving Layer ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quant.financial_facts (
    fact_id         SERIAL PRIMARY KEY,
    ticker          VARCHAR(10)  NOT NULL REFERENCES quant.stock(symbol) ON DELETE CASCADE,
    concept         VARCHAR(100) NOT NULL,  -- US-GAAP XBRL concept name
    form_type       VARCHAR(10)  NOT NULL,  -- '10-Q' or '10-K'
    fiscal_year     INT          NOT NULL,
    fiscal_quarter  INT          NOT NULL,  -- 1/2/3 for Q; 4 for annual 10-K
    period_end_date DATE         NOT NULL,
    value           NUMERIC(24, 4) NOT NULL,
    inserted_at     TIMESTAMPTZ  DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_fact_period UNIQUE (ticker, concept, fiscal_year, fiscal_quarter)
);

-- Optimized index for API point-lookups and DuckDB analytical joins
CREATE INDEX IF NOT EXISTS idx_fin_facts_lookup
    ON quant.financial_facts (ticker, fiscal_year DESC, fiscal_quarter);

CREATE INDEX IF NOT EXISTS idx_fin_facts_concept
    ON quant.financial_facts (concept, ticker);
```

### Target GAAP Concepts to Extract

| XBRL Concept | Dashboard Usage |
|---|---|
| `Revenues` | Total Revenue |
| `OperatingIncomeLoss` | EBIT |
| `NetCashProvidedByUsedInOperatingActivities` | Operating Cash Flow |
| `PaymentsToAcquirePropertyPlantAndEquipment` | CapEx |
| `LongTermDebt` | Leverage Risk |
| `CashAndCashEquivalentsAtCarryingValue` | Net Debt computation |
| `InterestExpense` | Interest Coverage |
| `NetIncomeLoss` | ROIC computation |
| `IncomeTaxExpense` | NOPAT computation |
| `Assets` | ROIC denominator proxy |
| `StockholdersEquity` | Invested Capital |
| `CommonStockSharesOutstanding` | Diluted Shares |
| `EarningsPerShareDiluted` | EPS check |

> **Note on concept aliases:** SEC EDGAR uses multiple XBRL names for the same concept across filing vintages (e.g., `Revenues` vs `RevenueFromContractWithCustomerExcludingAssessedTax`). The parser must attempt a prioritized alias list per concept.

---

## 5. DuckDB Analytical Layer

Follows the identical pattern used in `libs/shared/options_engine/`. DuckDB connects to Postgres via the `postgres` extension, runs vectorized pivots in-memory, and writes compressed Parquet to `data/fundamentals/`.

### 5.1 Q4 Single-Quarter Flow Metric Subtraction
By default, standard XBRL reports on form `10-K` represent the full 12-month fiscal year duration. To present a consistent 3-month quarterly series for the fourth quarter (Q4), the analytical layer automatically applies a subtraction step for all flow concepts (Revenue, Operating Income, Cash Flows).
The Q4 value for a fiscal year is calculated as:
$$\text{Value}_{\text{Q4}} = \text{Value}_{\text{Annual (10-K)}} - \left(\text{Value}_{\text{Q1 (10-Q)}} + \text{Value}_{\text{Q2 (10-Q)}} + \text{Value}_{\text{Q3 (10-Q)}}\right)$$
If any of the preceding quarterly filings are missing, the subtraction defaults to the annual value to avoid negative or distorted results. Point-in-time metrics (balance sheet items like Cash, Debt, and Total Assets) do not use subtraction and map directly to the `10-K` period end values.

### 5.2 Primary Currency Resolution & FX Scaling
To avoid time-series corruption from foreign listings reporting in multiple denominations (e.g. NetEase reporting in CNY and USD), the ingestion pipeline implements strict currency alignment:
1. **Primary Currency Identification**: Resolves the currency with the absolute maximum entries in the raw SEC XBRL payload.
2. **Strict Currency Filtering**: Filters and parses only facts matching the primary currency.
3. **FX Scaling**: Scales non-USD currencies using curated HSL exchange rates (e.g. `CNY: 0.14`, `EUR: 1.08`, `GBP: 1.27`, `JPY: 0.0064`) to align everything with the USD reporting standard in the serving layer.

### 5.3 Duplicate Prevention and Grouping Strategy
To prevent duplicate quarters resulting from amended filings (`10-Q/A`) or shifted reporting end dates, the DuckDB `PIVOT_QUERY` groups strictly by the key `(ticker, fiscal_year, fiscal_quarter)` and takes `MAX(period_end_date)`. This guarantees exactly one row per quarterly period in the final Parquet serving layer.

### 5.4 Active Database Fact Pruning
To prevent cumulative YTD or older obsolete facts from sticking around in PostgreSQL when duration filters are modified, the pipeline executes a targeted `DELETE FROM quant.financial_facts WHERE ticker = %s` immediately prior to upserting the parsed concepts. This keeps the normalized relational store 100% clean and pristine.

### 5.5 Shares Outstanding (Diluted) Alignment
For complete quarterly trend mapping, the pipeline prioritizes `WeightedAverageNumberOfDilutedSharesOutstanding` (true diluted shares over the period) and `WeightedAverageNumberOfSharesOutstandingBasic` as aliases for `CommonStockSharesOutstanding`. These are subject to duration-aware filtering so that YTD share counts are rejected in favor of single-quarter 3-month entries.

### 5.6 Computed Metrics

| Metric | Formula | GAAP Inputs |
|---|---|---|
| **Free Cash Flow** | OCF − CapEx | `NetCashProvidedByUsedInOperatingActivities` − `PaymentsToAcquirePropertyPlantAndEquipment` |
| **FCF Margin** | FCF / Revenue | Above ÷ `Revenues` |
| **ROIC** | NOPAT / (Equity + LT Debt) | `(NetIncomeLoss + IncomeTaxExpense) / (StockholdersEquity + LongTermDebt)` |
| **Net Debt/EBITDA** | (LT Debt − Cash) / (EBIT + D&A) | Approximate: use OperatingIncomeLoss × 1.15 for EBITDA proxy |
| **Interest Coverage** | EBIT / Interest Expense | `OperatingIncomeLoss / InterestExpense` |
| **FCF Yield** | FCF / Market Cap | FCF from above; Market Cap from `quant.stock.market_cap` |

### 5.7 Parquet Output Layout

```
data/fundamentals/
  BABA/
    quarterly.parquet    ← 20yr quarterly fact matrix + derived KPIs
    annual.parquet       ← 20yr annual fact matrix + derived KPIs
  AAPL/
    quarterly.parquet
    annual.parquet
```

The API reads directly from Parquet (via DuckDB) for sub-50ms response times on dashboard load.

---

## 6. Temporal Workflow Design

### New Workflow: `FundamentalsIngestionWorkflow`

Queue: `ingestion-tasks` (no new worker registration needed — the existing worker handles it).

```
FundamentalsIngestionWorkflow
  └── Activity: fetch_all_target_symbols           (reuse existing fetch_registry_symbols)
  └── Activity: check_submissions_for_new_filings  (lightweight SEC submissions poll)
  └── Activity: ingest_sec_raw_facts               (companyfacts pull → JSONB upsert)
  └── Activity: parse_facts_to_relational          (JSONB → quant.financial_facts)
  └── Activity: run_fundamentals_duckdb_compute    (Parquet derivation)
```

For the **backfill** path (new symbol): all 4 activities run sequentially.
For the **daily sync** path: only symbols flagged by `check_submissions_for_new_filings` proceed beyond step 2.

### Signature Resilience (per governance doc §3.1)

```python
@workflow.run
async def run(self, input_data: dict = {}) -> dict:
    ...
```

---

## 7. API Endpoints

New routes added to `apps/api/main.py` under the `/api/v1/fundamentals` prefix:

| Method | Path | Response | Description |
|---|---|---|---|
| `GET` | `/fundamentals/{symbol}` | Full financial row matrix (quarterly or annual) + metadata | Powers the Cash & Income Matrix table |
| `GET` | `/fundamentals/{symbol}/kpis` | ROIC, FCF Yield, Net Debt/EBITDA, Interest Coverage + status | Powers the Health Scorecard |
| `GET` | `/fundamentals/{symbol}/valuation` | P/E, Forward P/E, PEG, EV/EBITDA + peers | Powers the Valuation Panel |
| `POST` | `/fundamentals/backfill/{symbol}` | `{ status, ticker, facts_inserted }` | Triggers one-shot SEC backfill via Temporal |
| `GET` | `/fundamentals/{symbol}/sync-status` | `{ last_fetched_at, last_filing_at, is_stale }` | Powers System Alerts footer |

Query parameters: `?view=10-Q|10-K` · `?limit=20` (quarters or years to return).

---

## 8. Data Flow: From Frontend Toggle to Parquet

```
User selects "BABA" + "10-Q" + "5-Year"
         │
         ▼
GET /api/v1/fundamentals/BABA?view=10-Q&limit=20
         │
         ▼
API reads data/fundamentals/BABA/quarterly.parquet (via DuckDB)
         │  · Filters last 20 rows
         │  · Returns structured JSON with pre-computed FCF, ROIC, etc.
         ▼
Frontend renders FinancialTable + HealthScorecard
```

No live SEC calls on dashboard load — all data is pre-computed and cached in Parquet.

---

## 9. Transition Plan: Mock → Live

The current mock data in `fundamentalsUtils.ts` has been fully replaced by live API calls. The frontend `fetchFundamentals()` and `fetchLiveFundamentalsData()` calls in `api.ts` have been successfully mapped to our live FastAPI endpoints.

---

## 10. Advanced Calculation Mechanics

### 10.1 Multi-Filing Q4 Flow Subtraction Pipeline
To provide a complete quarterly series, flow metrics (Revenue, EBIT, OCF, CapEx) for Q4 periods are calculated by identifying the corresponding annual `10-K` filing and subtracting the cumulative sum of the preceding three quarters (Q1, Q2, and Q3) retrieved from the historical `10-Q` filings:
$$\text{Q4 Flow} = \text{Annual Flow (10-K)} - \sum_{i=1}^{3} \text{Quarterly Flow } Q_i \text{ (10-Q)}$$
This derived Q4 facts set is saved directly in the `quarterly.parquet` file under `fiscal_quarter = 4`, providing seamless chronological flow data across all 69 tickers in the database with no manual backfill latency.

### 10.2 Dynamic Peer Comparison and EV/EBITDA Engine
The `/fundamentals/{symbol}/valuation` endpoint selects peer companies dynamically using their `stock_group` registry in `quant.stock`:
1. It reads the target's `stock_group` array to find a specific niche sub-group (e.g. `'Quantum'`, `'Homebuilders'`). If none exist, it falls back to the primary sector ETF group (e.g. `'XLK'`, `'XLY'`).
2. It fetches up to 2 closest peers (sorted by proximity of market capitalization size to select valid competitors).
3. For the target and peers, it computes:
   * **TTM EBITDA**: Derived as TTM EBIT * 1.15.
   * **Enterprise Value (EV)**: $\text{EV} = \text{Market Capitalization} + \text{Long-Term Debt} - \text{Cash}$ (using cash/debt from the most recent quarter).
   * **EV/EBITDA**: $\frac{\text{EV}}{\text{EBITDA}}$.
4. If peers share negative multiples (e.g., loss-making startups like `QBTS`, `IONQ`, `RGTI`), the frontend's chart scales dynamically using absolute values (`Math.abs`) for perfect visual alignment.
