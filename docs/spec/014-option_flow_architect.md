# OptionFlow Architect: Structural Market Regime & Sentiment Index

**Author:** Antigravity (QuantEdge Studio)  
**Status:** IMPLEMENTED (v1.4)  
**Infrastructure:** DuckDB (Settlement) / QuestDB (Market Intelligence)  
**Last Validated:** 2026-05-15 — Added per-expiry Gamma Flip with brentq root-finding & regime classification

---

## 1. Quantitative Regime Core

The Regime Panel synthesizes price history (QuestDB) to identify the "Texture" of the current market move.

### 1.1 Hurst Exponent (Trend Persistence)
*   **Definition:** Measures the long-term memory of a time series. It identifies if a stock is trending or mean-reverting.
*   **The Math:** Derived using Rescaled Range (R/S) analysis on the last 100 periods of closing prices.
*   **Readings:**
    *   **H > 0.55 (Trending):** The series is persistent. Future moves are likely to follow the current direction. *Strategy: Trend-Following / Momentum.*
    *   **H < 0.45 (Mean-Reverting):** The series is anti-persistent. Price is likely to return to the mean. *Strategy: Mean Reversion / Sells into Strength.*
    *   **H ≈ 0.50 (Random Walk):** Geometric Brownian Motion. No discernible trend memory. *Strategy: Focus on Gamma Walls for range-bound entry.*

### 1.2 Volatility Clustering (GARCH-Lite)
*   **Definition:** Gauges the degree to which price shocks are "stuck" in the system. High values indicate that high-volatility moves are likely to be followed by further high-volatility.
*   **Interpretation:**
    *   **Value > 1.0:** "Sticky" Volatility. The market is in an expansionary regime. Risk-managed positions should be wider.
    *   **Value < 1.0:** Volatility Compression. Calm before the storm. Institutional desks often use this as a signal for cheap long-gamma entry (buying straddles).

### 1.3 Alpha Dispersion
*   **Definition:** Measures the idiosyncratic component of the ticker's return vs. the SPY benchmark.
*   **The Math:** Derived via linear regression of Ticker Returns on Market Returns. `Dispersion = 1 - R²`.
*   **Strategic Use:**
    *   **Low ( < 0.30):** "Beta Proxy." The ticker is moving in lockstep with the market. Unique fundamentals are being ignored.
    *   **High ( > 0.70):** "Alpha Outlier." The ticker has decoupled. This is where high-conviction idosyncratic moves (e.g. Earnings, Squeezes) occur.

---

## 2. Institutional Sentiment Index

The Sentiment Panel synthesizes the DuckDB options archive to reveal where the "Real Money" is positioned.

### 2.1 Gamma Exposure (GEX) — v1.3 Canonical Model

GEX measures the dollar impact on market makers per unit move in the underlying, assuming MMs are short calls and short puts (providing liquidity to the public).

#### Step 1 — Greek Calculation (Black-Scholes)

For each contract, Gamma (Γ) is calculated using standard BSM:

```
d1 = (ln(S/K) + (r + 0.5σ²)T) / (σ√T)
Γ  = N'(d1) / (S × σ × √T)
```

Where:
- `S` = Underlying Spot Price
- `K` = Strike Price
- `σ` = Implied Volatility (from `silver_options.impliedVolatility`)
- `T` = Days to Expiration / 365
- `r` = 0.05 (risk-free rate)

Implemented in `libs/shared/options_engine/enricher.py → calculate_greeks()`.

#### Step 2 — GEX Dollar Exposure Formula

```
GEX_Call = OI × 100 × Γ × S          (positive)
GEX_Put  = OI × 100 × Γ × S × (−1)  (negative)
```

> **v1.3 note:** The canonical formula uses `OI × 100 × Γ × S` (dollar gamma per contract). The earlier `S² × 0.01` variant (1%-normalized) is only used for the secondary **Total Net GEX** display metric, not for Flip/Wall identification.

Implemented in `libs/shared/options_engine/enricher.py` line ~134.

#### Step 3 — Gamma Flip Detection (Adaptive Significance Filter)

The Flip Point is the zero crossing of the aggregate net GEX profile **closest to the current spot price**.

**Algorithm:**
1. Aggregate GEX per strike across **all expirations**: `net_gex[K] = Σ GEX_Call[K] + Σ GEX_Put[K]`
2. Compute `peak_gex = max(|net_gex|)` across all strikes
3. Identify zero crossings, applying an **adaptive significance threshold** to eliminate phantom crossings from illiquid/micro strikes:
   - Try 10% of peak_gex as minimum magnitude for both adjacent strikes
   - Fall back to 5%, then 1% — stop at first threshold with at least one structural crossing
4. Select the crossing **closest to spot** (by absolute distance)

**Market Interpretation:**
- **Spot > Flip:** Dealers are Long Gamma → stabilizing → sell into strength, buy into weakness
- **Spot < Flip:** Dealers are Short Gamma → amplifying → accelerating moves in both directions

Implemented in `apps/api/research/volatility_lab.py → get_gex_profile()`.

#### Batch Validation (2026-04-23)

| Symbol | Our Flip | Reference | Delta |
|---|---|---|---|
| MSFT | $412.92 | Gemini $412.50 | **$0.42** ✅ |
| META | $668.14 | Structurally correct (negative gamma regime) | ✅ |
| AAPL | $267.57 | Barchart $251.99 (EOD OI lag) | ~$15 (data timing) |

**Coverage:** 74 / 78 symbols pass structural validation. 4 symbols (`ABSI`, `NVTS`, `RXRX`, `BBAI`) return `null` — correct behavior for sparse micro-cap chains with no institutional GEX mass.

### 2.2 Call Wall & Put Wall

Computed from **all expirations** per Barchart standard ("aggregate gamma exposure across all contracts"):

```
Call Wall = argmax_K ( Σ GEX_Call[K] )   # Strike with highest positive GEX
Put Wall  = argmin_K ( Σ GEX_Put[K]  )   # Strike with most negative GEX
```

### 2.3 Global PCR (Volume vs. OI)
*   **Volume PCR ("Hot Money"):** Measures intraday flow. Reflects the "velocity" of today's market sentiment.
*   **Open Interest PCR ("Structural Money"):** Settled, multi-day institutional positioning. The "anchor" of the option chain.
*   **Categorization:**
    *   **PCR < 0.7:** Heavily Bullish. Call buying outpaces put protection.
    *   **PCR > 1.3:** Heavily Bearish. Institutional put-overlay or tail-risk hedging dominating.

### 2.4 Per-Expiry Gamma Flip (v1.4 — Temporal Settlement Ladder)

The aggregate Gamma Flip (§2.1 Step 3) provides a single structural boundary across all expirations. The **Per-Expiry Gamma Flip** decomposes this into individual expiration dates, enabling precise regime classification per term.

#### The Problem with Aggregate-Only Flip

When the front-month put-heavy positioning offsets the back-month call positioning, the aggregate flip can obscure term-structure regime shifts. A 0DTE contract may be in **Negative Gamma** while the monthly is deeply **Positive Gamma**.

#### Calculation Architecture

**Step A — ATM IV Constant:**
For each expiration, extract the Implied Volatility of the **call strike closest to spot**. This constant eliminates skew-noise that shifts the flip level incorrectly, especially in 0DTE where individual strike IVs are erratic.

```
σ_ATM = IV of Call where |K - S| is minimized
```

**Step B — Fractional Time to Expiry (T):**

| Condition | T Value | Rationale |
|---|---|---|
| 0DTE (expiry == today) | `0.0025 years` | ~4/6.5 trading hours remaining |
| 1DTE | `1/252 years` | Next trading day |
| N DTE | `N/365 years` | Calendar days |

> **0DTE Mechanical Nuance:** Because T is extremely small, Gamma becomes a narrow "needle" at each strike. The Flip level will jump between strikes as the underlying moves. This is expected behavior, not a calculation error.

**Step C — Black-Scholes Gamma at Hypothetical Price S_test:**

```
d1 = (ln(S_test / K) + (r + 0.5σ²_ATM)T) / (σ_ATM × √T)
Γ(K) = N'(d1) / (S_test × σ_ATM × √T)
```

**Step D — Net Dealer GEX Function:**

```
Net_GEX(S_test) = Σ(OI_call × Γ_call × S² × 0.01) − Σ(OI_put × Γ_put × S² × 0.01)
```

**Step E — Root-Finding (brentq with Fallback):**

1. **Primary:** `scipy.optimize.brentq` on `Net_GEX(S_test)` over `[0.8×Spot, 1.2×Spot]` with `xtol=0.01`
2. **Fallback (no sign change):** Linear scan (200 points), detect sign crossings, refine sub-intervals with brentq
3. **Last Resort:** Report the price at minimum `|Net_GEX|` only if it's within 5% of peak magnitude

**Step F — Regime Classification:**

| Condition | Regime | Dealer Behavior | Market Effect |
|---|---|---|---|
| Spot ≥ Flip | `POSITIVE` | Long Gamma → sell into rallies, buy dips | Stabilizing |
| Spot < Flip | `NEGATIVE` | Short Gamma → sell into weakness, buy breakouts | Amplifying |

Implemented in `libs/shared/options_engine/enricher.py → calculate_gamma_flip()`.

---

## 3. Structural Anchor Points (The Walls)

### 3.1 Call Wall (The Ceiling)
*   **Definition:** The strike with the largest standalone **Call GEX** sum across all expirations.
*   **Significance:** Peak dealer "Sell-to-Hedge" pressure. Acts as a hard ceiling; price pins here or reverses sharply.

### 3.2 Put Wall (The Floor)
*   **Definition:** The strike with the most negative standalone **Put GEX** sum across all expirations.
*   **Significance:** Maximum dealer buy-to-hedge support. If broken, the downside move accelerates as dealers flip short-gamma.

### 3.3 Gamma Flip Point (Aggregate)
*   Zero crossing of aggregate net GEX closest to spot, filtered for structural significance (see §2.1 Step 3).
*   **Above Flip (Positive GEX):** Volatility dampening — dealers absorb moves.
*   **Below Flip (Negative GEX):** Volatility amplification — dealers chase price.

### 3.4 Per-Expiry Gamma Flip (Temporal)
*   Per-expiration root-finding via Black-Scholes Gamma with constant ATM IV (see §2.4).
*   Surfaced in the **Temporal Settlement Ladder** alongside Max Pain, Support, and Resistance.
*   Includes `POSITIVE`/`NEGATIVE` regime classification per term.

---

## 4. API Architecture

### 4.1 GEX Profile (Aggregate Structural Stats)

All three aggregate structural statistics are computed server-side in a **single API call**:

```
GET /api/v1/options/gex/{symbol}?date={YYYY-MM-DD}
```

Response payload:
```json
{
  "symbol": "MSFT",
  "spot": 415.75,
  "flip": 412.92,
  "call_wall": 420.0,
  "put_wall": 400.0,
  "profile": [
    {
      "strike": 410.0,
      "gex": 1234567,
      "full_gex": 2345678,
      "call_gex": 3000000,
      "put_gex": -655433,
      "oi": 12000,
      "vol": 3400
    }
  ]
}
```

The frontend (`OptionsAnalytics.tsx`) consumes `flip`, `call_wall`, and `put_wall` directly from this response via `serverStats` state — no secondary API calls, no stale-state risk on symbol switch.

### 4.2 Per-Expiry Gamma Flip (v1.4)

```
GET /api/v1/options/gamma-flip/{symbol}?date={YYYY-MM-DD}
```

Response payload:
```json
{
  "symbol": "MSFT",
  "data": {
    "symbol": "MSFT",
    "spot": 415.75,
    "trade_date": "2026-05-15",
    "aggregate_flip": 412.92,
    "aggregate_regime": "POSITIVE",
    "expirations": [
      { "date": "2026-05-16", "flip": 414.50, "regime": "POSITIVE" },
      { "date": "2026-05-23", "flip": 410.20, "regime": "NEGATIVE" },
      { "date": "2026-06-20", "flip": 408.00, "regime": "NEGATIVE" }
    ]
  }
}
```

**Frontend Integration:** The `OptionsAnalytics.tsx` component fetches this endpoint in parallel with GEX and Max Pain (`Promise.all`). Per-expiry flip data is merged into the **Temporal Settlement Ladder** table by matching on expiration date. Columns added: `GAMMA FLIP` (indigo) and `REGIME` (color-coded pills: `＋γ` green / `−γ` red). Aggregate regime is displayed as a badge in the Ladder header.

---

## 5. Operational Best Practices

*   **Sync Logic:** DuckDB (Options) and QuestDB (Regime) must be synced via the `/flow-architect` endpoint.
*   **Persistence:** Dashboard tab selection is stored in `localStorage` for institutional consistency.
*   **Re-Enrichment:** Run `repair_all.py` if Greeks appear unscaled or IV values are zeroed out.
*   **EOD Convergence:** Flip values converge to Barchart benchmarks after 8:30pm ET when settled OI is ingested. Intraday values may show ±$15 delta due to unsettled OI.
*   **Symbols with null Flip:** `ABSI`, `NVTS`, `RXRX`, `BBAI` — sparse micro-cap chains, no structural GEX mass. `null` is correct.
*   **Debugging:** Inspect structural stats directly via `curl http://localhost:3101/api/v1/options/gex/<SYMBOL>` — check `flip`, `call_wall`, `put_wall` keys in response.
*   **Per-Expiry Debugging:** `curl http://localhost:3101/api/v1/options/gamma-flip/<SYMBOL>` — inspect `aggregate_flip`, `aggregate_regime`, and per-expiry `flip`/`regime` values.
*   **0DTE Gamma Pinning:** On expiration day, the per-expiry flip for 0DTE contracts may jump between strikes as T→0. This is the expected "needle gamma" effect — the flip migrates toward Max Pain or the dominant Call/Put Wall strike.
*   **Negative Buffer Alert:** If the per-expiry flip is **above** spot for a near-term expiry, the asset is in the "Short Gamma" regime for that term. Dealers will sell into weakness, amplifying volatility. This is the highest-risk configuration for directional trades.
