# 032 Market Overview Dashboard — Implementation Plan

## Status
- [x] V10 Postgres migration (`quant.market_overview_log` table)
- [x] `scripts/apply_v10.py` — migration helper script
- [x] `apps/api/research/market_overview.py` — unified API router
- [x] Router registered in `apps/api/main.py`
- [x] `apps/frontend/src/services/api.ts` — `fetchMarketOverview()` added
- [x] `apps/frontend/src/pages/MarketOverview.tsx` — full dashboard UI
- [x] Sidebar entry added (`radar` icon, cyan, under Production)
- [x] Route added in `apps/frontend/src/App.tsx`
- [x] Frontend rebuilt and container restarted
- [x] End-to-end verified: API returns live data, Postgres rows persisted

---

## Implementation Details

### 1. Database Migration
**File:** `sql/postgres/migrations/V10__create_market_overview_log.sql`
**File:** `scripts/apply_v10.py`

- [x] Created `quant.market_overview_log` with columns for all macro indices, VIX term structure, yields, SPY options mechanics, and a `JSONB raw_data` column for the full response blob.
- [x] `captured_at TIMESTAMPTZ DEFAULT now()` auto-timestamps every row.
- [x] `apply_v10.py` applies the migration using `psycopg` — runs standalone outside Docker.

### 2. Backend Router
**File:** `apps/api/research/market_overview.py`

All fetch functions are synchronous and run inside `run_in_executor` thread pool. `asyncio.gather` dispatches all six in parallel:

#### `fetch_yfinance_macro()`
- [x] Fetches: `ES=F`, `NQ=F`, `RTY=F`, `^VIX`, `^TNX`, `DX-Y.NYB`, `CL=F`, `GC=F`, `SI=F`.
- [x] Uses `ticker.history(period="2d")` to compute daily % change.
- [x] Falls back to `fast_info.last_price` if history is unavailable.

#### `scrape_vix_central()`
- [x] `GET http://vixcentral.com/ajax_update` with required spoof headers:
  - `Referer: http://vixcentral.com/`
  - `X-Requested-With: XMLHttpRequest`
- [x] Parses JSON array: `data[0]` = month labels, `data[2]` = futures prices.
- [x] Computes `contango_pct = (F2 − F1) / F1 × 100`.
- [x] Returns `state`: `"Contango"` or `"Backwardation"`.

#### `fetch_alpha_vantage_2y()`
- [x] Calls `TREASURY_YIELD` endpoint with `maturity=2year&interval=daily`.
- [x] Skips `"."` placeholder values (holiday/weekend entries) by walking `data[]` list.
- [x] Returns latest valid float value in percent.

#### `query_options_mechanics()`
- [x] Connects to `db/options_analytics.db` (DuckDB, read-only).
- [x] Queries `silver_options` table for SPY at `MAX(trade_date)`.
- [x] Computes: Net GEX (0DTE), Call/Put Wall by GEX, Call/Put Wall by OI, PCR ratios (0DTE and all-expiry).
- [x] Returns `None` gracefully if DuckDB file does not exist.

#### `query_upcoming_earnings()`
- [x] Queries `quant.stock` with date regex filter `'^\\d{4}-\\d{2}-\\d{2}$'`.
- [x] Orders by `ABS(next_earnings_date::DATE − CURRENT_DATE)` ascending.
- [x] Returns top 8 rows with symbol, name, market_cap, next_earnings_date, market_sentiment.

#### `fetch_watchlist_anomalies()`
- [x] Loads symbols from `quant.watchlist` (up to 25).
- [x] Falls back to `["AAPL", "NVDA", "MSFT", "AMZN", "META", "TSLA"]` if table is empty.
- [x] Downloads 15-day daily OHLCV via `yf.download(group_by='ticker')`.
- [x] Computes `vol_ratio = today_vol / 14d_avg_vol`.
- [x] Returns top 6 by vol_ratio descending.

#### `persist_checklist_to_db()`
- [x] Extracts structured fields from the final metrics dict.
- [x] Inserts into `quant.market_overview_log` including `raw_data = psycopg.types.json.Json(metrics)`.
- [x] Called via `run_in_executor` (fire-and-forget, non-blocking).

#### `get_market_overview()` — Main Handler
- [x] Computes VIX regime label from spot price (< 15 / 15–20 / > 20 thresholds).
- [x] Computes yield spread (`us10y − us2y`).
- [x] Handles `isinstance(result, Exception)` for each gather result — degrades gracefully.

**File:** `apps/api/main.py`
- [x] Imported `market_overview_router` from `research.market_overview`.
- [x] Registered with prefix `/api/v1/research`, tag `"Market Overview"`.

### 3. Frontend Service
**File:** `apps/frontend/src/services/api.ts`
- [x] Added `fetchMarketOverview()`: `GET ${API_BASE_URL}/research/market-overview`.

### 4. Frontend Dashboard
**File:** `apps/frontend/src/pages/MarketOverview.tsx`

- [x] **TypeScript interfaces**: `MacroTicker`, `VixTermStructure`, `Yields`, `OptionsData`, `EarningsItem`, `VolumeAnomaly`, `MarketOverviewData`.
- [x] **Helper functions**: `fmt()`, `fmtBig()`, `changeColor()`, `changeBg()`, `changeMark()`, `regimeColor()`, `regimeBg()`, `sentimentBadge()`, `daysUntil()`.
- [x] **Reusable sub-components**: `SectionLabel`, `TickerCard`, `MiniStat`.

**Sections rendered:**

| Section | Key UI Elements |
|---|---|
| Index Futures | 3-col TickerCard grid, auto divergence warning banner |
| Volatility Complex | VIX spot + regime badge, term structure bar viz, risk gauges table |
| Rates & Yield Curve | 10Y / 2Y / Spread cards, inversion warning text |
| SPY 0DTE Options Mechanics | Net GEX + wall metrics, PCR ratio bars with color zones |
| Earnings Calendar | Table with proximity labels (TODAY / TOMORROW / in Xd / Xd ago), sentiment badge |
| Volume Anomalies | Table with vol ratio bar, SPIKE badge for vol_ratio > 1.5x |

- [x] Refresh button with spinner animation on load.
- [x] `lastRefresh` timestamp displayed in header.
- [x] Error banner shown if API call fails.

**File:** `apps/frontend/src/components/Layout/Sidebar.tsx`
- [x] Added to `productionItems`: `{ to: '/market-overview', icon: 'radar', label: 'Market Overview', color: 'text-cyan-400' }`.

**File:** `apps/frontend/src/App.tsx`
- [x] Imported `MarketOverview` from `./pages/MarketOverview`.
- [x] Added route: `<Route path="market-overview" element={<MarketOverview />} />`.

---

## Testing & Validation

### API Verification
- [x] `GET /api/v1/research/market-overview` returns HTTP 200 with full JSON.
- [x] ES=7451.75, NQ=29390.5, RTY=2821.0, VIX=17.44, TNX=4.57, DXY=99.12.
- [x] VIX term structure: F1=20.06 (Jun), F2=21.5 (Jul), Contango +7.18%.
- [x] Yields: 10Y=4.57%, 2Y=4.07%, Spread=+0.50% (non-inverted).
- [x] Options: Spot=741.25, Net GEX=+$296M, Call Wall=740, Put Wall=740, PCR 0DTE OI=0.32.
- [x] Persistence: `SELECT count(*) FROM quant.market_overview_log` → confirmed 2 rows after two refreshes.

### Frontend Verification
- [x] `GET http://localhost:3100/market-overview` → HTTP 200.
- [x] Sidebar shows "Market Overview" under Production with cyan radar icon.
- [x] All 5 dashboard sections render correctly.

---

## File Manifest

| File | Type | Description |
|---|---|---|
| `sql/postgres/migrations/V10__create_market_overview_log.sql` | New | DDL for pre-market snapshot log |
| `scripts/apply_v10.py` | New | Standalone migration script |
| `apps/api/research/market_overview.py` | New | Unified data aggregation + persistence router |
| `apps/api/main.py` | Modified | Registered `market_overview_router` |
| `apps/frontend/src/services/api.ts` | Modified | Added `fetchMarketOverview()` |
| `apps/frontend/src/pages/MarketOverview.tsx` | New | Full pre-market dashboard UI |
| `apps/frontend/src/components/Layout/Sidebar.tsx` | Modified | Added Market Overview nav entry |
| `apps/frontend/src/App.tsx` | Modified | Added `/market-overview` route |
