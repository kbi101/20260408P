# Pre-Market Overview Dashboard — Design Specification

## Objective

Build a professional-grade pre-market briefing dashboard that synthesizes the macro environment with the underlying mechanical structure of the market. The page replaces the need for manual multi-tab lookups by pulling all critical data into a single, auto-refreshing view every morning before the opening bell.

---

## 1. Architecture Overview

The dashboard aggregates six heterogeneous data sources into a single unified API response, persists every fetch as a historical snapshot, and renders all metrics in a structured, actionable layout.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Pre-Market Overview Pipeline                          │
│                                                                                 │
│  Browser (React: /market-overview)                                              │
│       │                                                                         │
│       ▼  GET /api/v1/research/market-overview                                   │
│  FastAPI Router: market_overview.py                                             │
│       │                                                                         │
│       ├──▶ yfinance (live)          ES, NQ, RTY, VIX, TNX, DXY, CL, GC, SI    │
│       ├──▶ vixcentral.com (scrape)  F1/F2 VIX futures term structure           │
│       ├──▶ Alpha Vantage (API)      2Y Treasury Yield                          │
│       ├──▶ DuckDB (local)           SPY GEX, Walls, PCR (0DTE + total)         │
│       ├──▶ Postgres (local)         Earnings calendar, Watchlist symbols        │
│       └──▶ yfinance (live)          15-day volume ratio for watchlist           │
│                                                                                 │
│       └── [fire & forget] INSERT INTO quant.market_overview_log                │
│                                                                                 │
│  Response JSON → React renders 5 dashboard sections                             │
└─────────────────────────────────────────────────────────────────────────────────┘
```

All six fetches are dispatched **in parallel** via `asyncio.gather`. Each source degrades gracefully — if it fails, its section shows `—` rather than breaking the page.

---

## 2. Data Sources & Checklist Sections

### 2.1 Macro Futures — Index Futures

| Ticker | Symbol | Purpose |
|---|---|---|
| ES | `ES=F` | S&P 500 E-mini futures |
| NQ | `NQ=F` | Nasdaq 100 futures |
| RTY | `RTY=F` | Russell 2000 futures |

**Divergence Detection:** If `|NQ.change_pct − RTY.change_pct| > 1.0%`, the UI shows an amber warning banner indicating potential sector rotation.

### 2.2 Volatility Complex

| Metric | Source | Threshold Logic |
|---|---|---|
| VIX Spot | yfinance `^VIX` | < 15 = Low; 15–20 = Elevated; > 20 = High |
| VIX Regime Label | Computed | Shown as color-coded badge |
| F1 (front-month VIX future) | VixCentral `/ajax_update` | — |
| F2 (second-month VIX future) | VixCentral `/ajax_update` | — |
| Contango % | `(F2 − F1) / F1 × 100` | Positive = Contango (normal); Negative = Backwardation (stress) |

**VixCentral Scraping:** Requires headers: `User-Agent`, `Referer: http://vixcentral.com/`, `X-Requested-With: XMLHttpRequest`.

### 2.3 Risk Gauges

| Ticker | Symbol | Context |
|---|---|---|
| DXY | `DX-Y.NYB` | Dollar strength (inverse risk-asset pressure) |
| Crude Oil | `CL=F` | Inflation / growth proxy |
| Gold | `GC=F` | Safe haven demand |
| Silver | `SI=F` | Industrial risk-on signal |

### 2.4 Rates & Yield Curve

| Metric | Source |
|---|---|
| US 10Y Yield | yfinance `^TNX` (reported in %, no scaling needed) |
| US 2Y Yield | Alpha Vantage `TREASURY_YIELD` (maturity=2year, daily) |
| 10Y–2Y Spread | Computed: `us10y − us2y` (negative = inverted curve) |

> **Alpha Vantage Constraint:** 25 req/day free tier. Refreshing 2–4 times per morning stays well within limits.

### 2.5 SPY 0DTE Options Mechanics

All computed from the local DuckDB file (`db/options_analytics.db`, table `silver_options`):

| Metric | Computation |
|---|---|
| Spot Price | `underlying_price` at `MAX(trade_date)` for SPY |
| Net GEX (0DTE) | `SUM(gex)` where `expiration = MIN(expiration ≥ trade_date)` |
| Call Wall (GEX) | Strike with highest `gex` among calls (0DTE) |
| Put Wall (GEX) | Strike with lowest `gex` among puts (0DTE) |
| Call Wall (OI) | Strike with highest `openInterest` among calls (0DTE) |
| Put Wall (OI) | Strike with highest `openInterest` among puts (0DTE) |
| PCR 0DTE OI | `SUM(put OI) / SUM(call OI)` — 0DTE expiry only |
| PCR 0DTE Vol | `SUM(put vol) / SUM(call vol)` — 0DTE expiry only |
| PCR Total OI | Same ratios across all expirations |
| PCR Total Vol | Same ratios across all expirations |

**Net GEX Interpretation:**
- Positive → Dealers are long gamma → Market-maker pinning force (suppresses moves)
- Negative → Dealers are short gamma → Market-makers amplify moves

**PCR Thresholds:** < 0.7 = Bullish, 0.7–1.2 = Neutral, > 1.2 = Bearish.

### 2.6 Earnings Calendar

Sourced from `quant.stock` table in Postgres. Query filters for:
- `next_earnings_date` matching `YYYY-MM-DD` regex
- Sorted by `ABS(next_earnings_date::DATE − CURRENT_DATE)` ascending
- Returns top 8 nearest (before or after today)

Displayed with proximity label: `TODAY`, `TOMORROW`, `in Xd`, or `Xd ago`.

### 2.7 Watchlist Volume Anomalies

1. Fetch symbols from `quant.watchlist` (up to 25).
2. Download 15-day 1d OHLCV from yfinance.
3. Compute 14-day rolling average volume (excluding today's bar).
4. `vol_ratio = today_volume / avg_volume`
5. Sort descending by `vol_ratio`, return top 6.

---

## 3. Database Schema

### `quant.market_overview_log`

**Migration:** `sql/postgres/migrations/V10__create_market_overview_log.sql`

| Column | Type | Description |
|---|---|---|
| `id` | SERIAL (PK) | Auto-increment |
| `captured_at` | TIMESTAMPTZ | Defaults to `now()` |
| `es_price` / `es_change_pct` | NUMERIC | S&P 500 futures |
| `nq_price` / `nq_change_pct` | NUMERIC | Nasdaq 100 futures |
| `rty_price` / `rty_change_pct` | NUMERIC | Russell 2000 futures |
| `vix_price` / `vix_change_pct` | NUMERIC | VIX spot |
| `f1_price` / `f2_price` | NUMERIC | Front & second-month VIX futures |
| `contango_pct` | NUMERIC | Term structure slope |
| `vix_regime` | VARCHAR(80) | Regime label string |
| `us10y_yield` / `us2y_yield` | NUMERIC | Treasury yields |
| `yield_spread` | NUMERIC | 10Y − 2Y |
| `dxy_price` | NUMERIC | Dollar index |
| `spy_spot` | NUMERIC | SPY underlying price |
| `spy_0dte_gex` | NUMERIC | Net gamma exposure (0DTE) |
| `spy_call_wall` / `spy_put_wall` | NUMERIC | GEX-based key strikes |
| `spy_pcr` | NUMERIC | Put/call ratio (0DTE OI) |
| `raw_data` | JSONB | Full API response blob |

---

## 4. API Design

**Endpoint:** `GET /api/v1/research/market-overview`

**Response Schema:**
```json
{
  "timestamp": "2026-05-20T14:00:00",
  "macro": {
    "ES": { "price": 5320.25, "change_pct": 0.45 },
    "NQ": { "price": 18740.50, "change_pct": 0.82 },
    "RTY": { "price": 2140.00, "change_pct": -0.15 },
    "VIX": { "price": 16.20, "change_pct": -3.10 },
    "TNX": { "price": 4.57, "change_pct": -0.80 },
    "DXY": { "price": 103.40, "change_pct": -0.12 },
    "CL":  { "price": 79.30, "change_pct": 0.40 },
    "GC":  { "price": 2340.10, "change_pct": 0.22 },
    "SI":  { "price": 27.50, "change_pct": 0.55 }
  },
  "vix_term_structure": {
    "f1": 17.30, "f2": 18.60,
    "f1_month": "Jun", "f2_month": "Jul",
    "contango_pct": 7.51, "state": "Contango"
  },
  "vix_regime": "Elevated Volatility (Caution / Rotational)",
  "yields": { "us10y": 4.57, "us2y": 4.07, "spread": 0.50 },
  "options": {
    "trade_date": "2026-05-20", "expiration_0dte": "2026-05-20",
    "spot_price": 530.45, "net_gex": 296000000,
    "call_wall_gex": 532.0, "put_wall_gex": 525.0,
    "call_wall_oi": 535.0, "put_wall_oi": 520.0,
    "pcr_0dte_oi": 0.72, "pcr_0dte_vol": 0.61,
    "pcr_total_oi": 1.35, "pcr_total_vol": 0.88
  },
  "earnings": [ { "symbol": "NVDA", "name": "...", "market_cap": 3e12, "next_earnings_date": "2026-05-20", "market_sentiment": "Bullish" } ],
  "volume_anomalies": [ { "symbol": "XLB", "latest_vol": 20000000, "avg_vol": 10000000, "vol_ratio": 2.0, "price": 98.50, "pct_change": 1.4 } ]
}
```

---

## 5. Frontend Dashboard

### Layout

`MarketOverview.tsx` — single scrollable page under the **Production** sidebar group.

**Header:** Page title + timestamp of last refresh + Refresh button.

**Section 1 — Index Futures**
- 3-column card grid: ES, NQ, RTY
- Each card: price, % change, color-coded background (green tint / red tint / neutral)
- Automatic divergence warning banner if NQ vs RTY spread > 1%

**Section 2 — Volatility Complex**
- Left: VIX spot with regime badge and threshold markers (15 / 20)
- Center: VIX term structure with bar visualization + Contango/Backwardation label
- Right: Risk gauges (DXY, CL, GC, SI) in a stacked table

**Section 3 — Rates & Yield Curve**
- 4-column grid: 10Y, 2Y, and 10Y–2Y spread (with inversion warning if negative)

**Section 4 — SPY 0DTE Options Mechanics**
- Left: GEX panel (Net GEX, Call/Put walls by GEX + OI)
- Right: PCR panel (4 ratio bars with color-coded bearish/bullish zones)

**Section 5 — Earnings + Volume Anomalies**
- Side-by-side tables (lg:grid-cols-2)
- Earnings: symbol, date, market cap, sentiment badge, proximity label
- Volume: symbol, price, % change, vol ratio bar + spike badge

### Navigation
- **Sidebar section:** Production
- **Icon:** `radar` (cyan accent)
- **Route:** `/market-overview`

---

## 6. Persistence Strategy

Every successful API call fires a background `run_in_executor` insert to `quant.market_overview_log`. This is non-blocking — the response is returned to the client immediately. The log enables:

- Morning-by-morning regime comparison
- Correlation of VIX regimes with intraday outcomes
- Historical PCR / GEX tracking

---

## 7. Refresh Cadence

The page is **manually refreshed** (no auto-poll timer). Each refresh fetches fresh data from all live sources. The Alpha Vantage 2Y yield will return the prior-day value outside market hours — this is expected behavior and acceptable given the 25 req/day limit.
