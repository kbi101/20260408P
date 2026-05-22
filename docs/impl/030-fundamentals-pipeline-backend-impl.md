# 030 Fundamentals Pipeline Backend — Implementation Plan

## Status
- [x] V8 Flyway migration (DDL for `sec_raw_facts` + `financial_facts`)
- [x] `libs/shared/activities_fundamentals.py` — 4 activity definitions
- [x] `libs/shared/workflows_fundamentals.py` — `FundamentalsIngestionWorkflow`
- [x] Worker registration for fundamentals activities + workflow
- [x] `data/fundamentals/` directory (mapped volume in docker-compose)
- [x] FastAPI endpoints in `apps/api/main.py`
- [x] API functions in `apps/frontend/src/services/api.ts`
- [x] Replace mock data in `fundamentalsUtils.ts` with live API calls
- [x] Temporal schedule: `fundamentals-daily-sync`
- [x] Integration test: BABA end-to-end backfill → API → frontend

---

## Implementation Details

### 1. Flyway Migration
**File:** `sql/postgres/migrations/V8__create_fundamentals_tables.sql`
- [ ] Create `quant.sec_raw_facts` with JSONB `raw_payload`, `cik`, `last_fetched_at`, `last_filing_at`.
- [ ] Create `quant.financial_facts` with `ticker`, `concept`, `form_type`, `fiscal_year`, `fiscal_quarter`, `period_end_date`, `value`.
- [ ] Add composite unique constraint `(ticker, concept, fiscal_year, fiscal_quarter)`.
- [ ] Add index `idx_fin_facts_lookup ON (ticker, fiscal_year DESC, fiscal_quarter)`.
- [ ] Add index `idx_fin_facts_concept ON (concept, ticker)`.
- [ ] Both tables FK to `quant.stock(symbol) ON DELETE CASCADE`.

### 2. Activities
**File:** `libs/shared/activities_fundamentals.py`

**Class: `FundamentalsActivities`**

- [ ] `get_padded_cik(ticker)` — helper (not an activity): fetches `https://www.sec.gov/files/company_tickers.json`, matches ticker, returns zero-padded 10-digit CIK. Cache result in class dict to avoid redundant calls.

- [ ] `@activity.defn check_submissions_for_new_filings(input: dict) -> list[str]`
  - Accepts `{ "symbols": [...] }`.
  - For each symbol, fetches `https://data.sec.gov/submissions/CIK{cik}.json`.
  - Inspects `filings.recent.form` list — searches for any `10-Q` or `10-K` with `filingDate` > `sec_raw_facts.last_filing_at` for that ticker.
  - Enforces `time.sleep(0.15)` between requests (10 RPS limit).
  - Returns list of symbols that need a re-fetch.
  - Sets **User-Agent header**: `QuantEdge-Studio kepingbi.research@domain.com`.

- [ ] `@activity.defn ingest_sec_raw_facts(input: dict) -> str`
  - Accepts `{ "ticker": "BABA" }`.
  - Fetches `https://data.sec.gov/api/xbrl/companyfacts/CIK{cik}.json`.
  - Upserts to `quant.sec_raw_facts` via `ON CONFLICT (ticker) DO UPDATE SET raw_payload = EXCLUDED.raw_payload, last_fetched_at = CURRENT_TIMESTAMP`.
  - Returns `"OK:{ticker}:{bytes_stored}"`.

- [ ] `@activity.defn parse_facts_to_relational(input: dict) -> dict`
  - Accepts `{ "ticker": "BABA" }`.
  - Reads `raw_payload` JSONB from `quant.sec_raw_facts`.
  - Navigates `payload['facts']['us-gaap']` for each target concept (13 concepts from research doc).
  - **Alias resolution**: attempt primary concept name first; fall back to alias list (e.g., `Revenues` → `RevenueFromContractWithCustomerExcludingAssessedTax`).
  - Filters to rows where `form` is `'10-Q'` or `'10-K'` and both `fy` and `fp` keys exist.
  - Maps `fp` to fiscal quarter: `Q1→1, Q2→2, Q3→3, FY→4`.
  - Batch inserts via `psycopg.executemany` with `ON CONFLICT DO UPDATE SET value = EXCLUDED.value`.
  - Returns `{ "ticker": ..., "concepts_parsed": N, "rows_upserted": M }`.

- [ ] `@activity.defn run_fundamentals_duckdb_compute(input: dict) -> str`
  - Accepts `{ "ticker": "BABA", "view": "10-Q" | "10-K" | "both" }`.
  - Opens DuckDB in-memory connection.
  - `INSTALL postgres; LOAD postgres;` + `ATTACH '{DB_CONN}' AS pg (TYPE POSTGRES, SCHEMA 'quant')`.
  - Runs pivot query (see research doc §5) to compute FCF, ROIC, Net Debt/EBITDA, Interest Coverage.
  - Writes two files:
    - `data/fundamentals/{ticker}/quarterly.parquet`
    - `data/fundamentals/{ticker}/annual.parquet`
  - Returns path string.
  - **DuckDB connection must be opened with `read_only=False`** (only this activity writes; API reads in `read_only=True` per existing convention from `c4e79a44` fix).

### 3. Workflow
**File:** `libs/shared/workflows_fundamentals.py`

- [ ] `@workflow.defn class FundamentalsIngestionWorkflow`
  - `run(self, input_data: dict = {}) -> dict`
  - `mode = input_data.get("mode", "daily_sync")` — `"backfill"` or `"daily_sync"`.

  **Backfill path** (`mode == "backfill"`):
  ```
  1. ingest_sec_raw_facts({ "ticker": symbol })
  2. parse_facts_to_relational({ "ticker": symbol })
  3. run_fundamentals_duckdb_compute({ "ticker": symbol, "view": "both" })
  ```

  **Daily sync path** (`mode == "daily_sync"`):
  ```
  1. fetch_registry_symbols (reuse existing MarketDataActivities method)
  2. check_submissions_for_new_filings({ "symbols": [...] })
  3. For each stale symbol:
       ingest_sec_raw_facts → parse_facts_to_relational → run_duckdb_compute
  ```

  - `start_to_close_timeout` per activity:
    - `check_submissions`: `timedelta(minutes=5)`
    - `ingest_sec_raw_facts`: `timedelta(minutes=3)`
    - `parse_facts_to_relational`: `timedelta(minutes=2)`
    - `run_fundamentals_duckdb_compute`: `timedelta(minutes=5)`

### 4. Worker Registration
**File:** `services/worker/main.py`
- [ ] Import `FundamentalsIngestionWorkflow` from `shared.workflows_fundamentals`.
- [ ] Import `FundamentalsActivities` from `shared.activities_fundamentals`.
- [ ] Instantiate `fund_activities = FundamentalsActivities()`.
- [ ] Add to `worker_ingest` (queue: `ingestion-tasks`):
  - Workflow: `FundamentalsIngestionWorkflow`
  - Activities:
    - `fund_activities.check_submissions_for_new_filings`
    - `fund_activities.ingest_sec_raw_facts`
    - `fund_activities.parse_facts_to_relational`
    - `fund_activities.run_fundamentals_duckdb_compute`

### 5. Docker Volume
**File:** `docker-compose.yml`
- [ ] Add `./data/fundamentals:/app/data/fundamentals` to the `api` service volumes (read-only Parquet access).
- [ ] Add same mount to `worker` service volumes (Parquet write access).
- [ ] Create `data/fundamentals/` directory locally.

### 6. FastAPI Endpoints
**File:** `apps/api/main.py`

- [ ] `GET /api/v1/fundamentals/{symbol}`
  - Query params: `view: str = "10-Q"`, `limit: int = 20`.
  - Opens DuckDB `read_only=True` on `data/fundamentals/{symbol}/quarterly.parquet` or `annual.parquet`.
  - Returns JSON: `{ symbol, view, rows: [{ fiscal_year, fiscal_quarter, period_end_date, concept, value }] }`.
  - 404 if Parquet file does not exist (prompt backfill).

- [ ] `GET /api/v1/fundamentals/{symbol}/kpis`
  - Reads from Parquet, computes latest-period KPI snapshot.
  - Returns: `{ roic, fcf_yield, net_debt_ebitda, interest_coverage, period_end_date }`.

- [ ] `GET /api/v1/fundamentals/{symbol}/valuation`
  - Reads P/E and EPS-based multiples from Parquet.
  - Reads `market_cap` from `quant.stock` for FCF Yield and EV calculation.
  - Returns multiples block.

- [ ] `POST /api/v1/fundamentals/backfill/{symbol}`
  - Triggers `FundamentalsIngestionWorkflow` with `{ "mode": "backfill", "symbol": symbol }` on `ingestion-tasks`.
  - Returns `{ "workflow_id": ..., "status": "scheduled" }`.

- [ ] `GET /api/v1/fundamentals/{symbol}/sync-status`
  - Reads `last_fetched_at`, `last_filing_at` from `quant.sec_raw_facts`.
  - Returns staleness flag: `is_stale = (now - last_fetched_at) > 24h`.

### 7. Temporal Schedule Registration
**File:** `apps/api/main.py` (startup schedules baseline)
- [ ] Add schedule `fundamentals-daily-sync`:
  - Workflow: `FundamentalsIngestionWorkflow`
  - Input: `{ "mode": "daily_sync" }`
  - Cron: Daily M-F at **6:00 PM CST** (after market close)
  - Queue: `ingestion-tasks`
  - Must follow routing rule: `"Options"` not in workflow name → `ingestion-tasks` ✓

### 8. Frontend API Integration
**File:** `apps/frontend/src/services/api.ts`
- [ ] `fetchFundamentals(symbol, view, limit)` → `GET /fundamentals/{symbol}?view=...&limit=...`
- [ ] `fetchFundamentalsKPIs(symbol)` → `GET /fundamentals/{symbol}/kpis`
- [ ] `fetchFundamentalsValuation(symbol)` → `GET /fundamentals/{symbol}/valuation`
- [ ] `triggerFundamentalsBackfill(symbol)` → `POST /fundamentals/backfill/{symbol}`
- [ ] `fetchFundamentalsSyncStatus(symbol)` → `GET /fundamentals/{symbol}/sync-status`

**File:** `apps/frontend/src/services/fundamentalsUtils.ts`
- [ ] Replace `getMockFundamentals(symbol)` call in `Fundamentals.tsx` with `fetchFundamentals()`.
- [ ] Remove mock data entries from `MOCK_DB` once live endpoints are validated.
- [ ] Keep derived metric helper functions (`computeROIC`, etc.) — they still run client-side on the API response.

### 9. GAAP Concept Alias Map
The parser must try multiple XBRL names per concept. Implement as a dict in `activities_fundamentals.py`:

```python
CONCEPT_ALIASES = {
    "Revenues": [
        "Revenues",
        "RevenueFromContractWithCustomerExcludingAssessedTax",
        "SalesRevenueNet",
        "SalesRevenueGoodsNet",
    ],
    "OperatingIncomeLoss": [
        "OperatingIncomeLoss",
        "IncomeLossFromContinuingOperationsBeforeIncomeTaxesExtraordinaryItemsNoncontrollingInterest",
    ],
    "NetCashProvidedByUsedInOperatingActivities": [
        "NetCashProvidedByUsedInOperatingActivities",
        "NetCashProvidedByOperatingActivities",
    ],
    "PaymentsToAcquirePropertyPlantAndEquipment": [
        "PaymentsToAcquirePropertyPlantAndEquipment",
        "CapitalExpendituresIncurredButNotYetPaid",
        "AcquisitionsNetOfCashAcquiredAndPurchasesOfBusinesses",
    ],
    # ... (remaining 9 concepts follow same pattern)
}
```

---

## Testing & Validation
- [x] Run V8 migration via Flyway: `docker compose run --rm flyway migrate`.
- [x] Manual backfill test: `POST /api/v1/fundamentals/backfill/BABA` → verify Parquet files created under `data/fundamentals/BABA/`.
- [x] Verify `quant.financial_facts` row count for BABA > 100 rows (multiple concepts × quarters).
- [x] Validate KPI endpoint: confirm ROIC, FCF, Net Debt/EBITDA values are reasonable against public sources.
- [x] Confirm SEC User-Agent header is set correctly — inspect with `curl -v` to avoid IP ban risk.
- [x] Confirm `time.sleep(0.15)` is in place between all EDGAR requests.
- [x] Test daily sync with a ticker that has a new filing vs one without — confirm only stale symbols trigger a re-ingest.
- [x] Confirm `read_only=True` on DuckDB connections in API endpoints (per existing convention).
- [x] Confirm Temporal schedule appears in UI at `localhost:3104` under `fundamentals-daily-sync`.
- [x] Replace mock data in frontend and validate dashboard renders identically with live data.

### Automated Parity Testing
We implemented a complete automated mathematical parity test suite in `tests/test_fundamentals_parity.py` to audit and enforce absolute accuracy:
* **Scope**: Audits 16 distinct data items over the last 4 quarters (Revenue, EBIT, OCF, and CapEx) for a randomly picked processed symbol against raw PostgreSQL SEC data.
* **Q4 Logic Validation**: Implements Q4 subtraction logic in the test suite to verify DuckDB's calculated Q4 value matches raw 10-K subtraction expectations.
* **Currency Resolution**: Inspects and enforces strict primary currency matching to confirm foreign listings (like NetEase in RUB/CNY) validate correctly against their primary denominations.
* **Execution**: Run `python3 tests/test_fundamentals_parity.py` to pick a random ticker and confirm 100% mathematical match. Verified across multiple cycles (including complex structures like AMD, WMT, FCX, and CCJ) with zero discrepancies.

### Advanced Pipeline Enhancements

#### 1. Multi-Filing Q4 Flow Subtraction & Period Labeling
To resolve the industry-wide "missing Q4 quarterly period" issue (since companies only file annual `10-K` forms rather than a separate Q4 `10-Q`), we implemented a rigorous flow-subtraction pipeline:
* **Calculations**: For flow metrics (Revenue, EBIT, OCF, CapEx), a dynamic Q4 single-quarter period is derived by subtracting the cumulative Q1-Q3 flows (summed from matching `10-Q` filings) from the annual `10-K` figures.
* **Rebuild Scripting**: Executed a global synchronization rebuilder mapping directly into the worker container to regenerate clean `quarterly.parquet` and `annual.parquet` files for **all 69 active tickers** in the database. Every ticker is now fully populated with Q4 metrics.
* **Period Labeling**: Mapped parsed Q4 data with explicit `fiscal_quarter = 4` labeling so that the frontend matrix displays clean chronological rows (`Q1 2026`, `Q4 2025`, `Q3 2025`, etc.) with no gaps.

#### 2. Dynamic Peer Valuation & EV/EBITDA Engine
Replaced the static frontend placeholder mock (which was showing hardcoded Chinese e-commerce giants and arbitrary positive multiples for every ticker) with a fully responsive dynamic peer comp engine:
* **Target Peer Selection**: The backend FastAPI `/valuation` endpoint fetches the stock's `stock_group` registry in Postgres, identifies similar companies sharing a sub-group (e.g. `IONQ` and `RGTI` for `QBTS`), and retrieves their rolling parquet facts.
* **TTM Calculations**: Calculates live trailing multiples using Enterprise Value (`EV = Market Cap + Debt - Cash`) and EBITDA proxy (`TTM EBIT * 1.15`).
* **Visual Scaling**: Updated the UI bar chart component to dynamically scale widths using `Math.abs`, enabling robust scaling for negative multiples (common in early-growth startups) with zero rendering distortion.

