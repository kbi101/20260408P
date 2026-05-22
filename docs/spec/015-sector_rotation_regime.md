# Sector Rotation Architect: Parametric Relative Vector Analysis

**Author:** Antigravity (QuantEdge Studio)  
**Status:** PRODUCTION SPECIFICATION
**Infrastructure:** FastAPI / QuestDB (Market Data) / DuckDB (Alpha Engine) / PostgreSQL (Constituents) / Recharts (Temporal)

---

## 1. Executive Summary
The Sector Rotation Architect treats the market as a collection of **Relative Vectors**. By defining a "Zero-Point" (Baseline), we identify institutional capital flows before they manifest in top-line price action. This specification documents the **Vector Lab** engine, which integrates live opening-hour tracking, Semiconductor sub-vectors (`SOXX`), Momentum persistence, Gamma exposure, component-to-sector level rotation, and automated asset governance mapping.

---

## 2. Quantitative Vector Definitions

### 2.1 RS-Ratio (Relative Strength Quotient)
The X-Axis measures the structural relative strength of the asset normalized against a baseline (e.g., SPY or a Sector ETF) using a Z-score distribution:
- **RS-Raw:** `Asset Close / Baseline Close`
- **Normalization:** `100 + ((RS-Raw - Rolling Mean) / Rolling StdDev) * 1.5`

### 2.2 RS-Momentum (Relative Velocity)
The Y-Axis measures the rate of change (velocity) of the RS-Ratio:
- **Normalization:** `100 + (Δ RS-Ratio * 2)` over the Momentum Window.

### 2.3 Volume Weighted Average Price (VWAP)  
*(Research Lab Integration)*  
Calculates the cumulative volume-weighted typical price, resetting at each session start.
- **Formula:** $VWAP = \frac{\sum (TypicalPrice \times Volume)}{\sum Volume}$ where $TypicalPrice = \frac{High + Low + Close}{3}$
- **Utility:** Audits price deviations from "Institutional Equilibrium." Breach of VWAP during a pattern formation signals institutional accumulation/distribution conviction.

### 2.4 Hurst Exponent (H)
Measures the **Persistence** of the rotation vector.
- **Goal:** Filter out "Random Walk" (noise) from true "Regime Shift" (persistence).
- **Metric:**
    - $H > 0.55$: Persistent rotation. Capital flow is unidirectional and likely to continue.
    - $H < 0.45$: Mean-reverting. Rotation is a noise spike or a temporary squeeze.

### 2.5 Net GEX (Gamma Exposure)
Aggregates the notional Gamma hedging pressure across the option chain of the target asset.
- **Positive GEX:** "The Stable Regime." Market makers buy dips and sell rips, dampening volatility and supporting the rotation.
- **Negative GEX:** "The Volatile Regime." Market makers sell into weakness and buy into strength, accelerating the rotation's velocity but increasing fragility.

### 2.6 Component-to-Sector Level Rotation
To isolate individual constituent performance within a sector, the engine supports component-level relative vector calculation.
- **Baseline Selection:** The baseline asset is redefined as the selected Sector ETF (e.g., `XLK` or `SOXX`).
- **Constituent Resolution:** Stock symbols belonging to the selected sector are dynamically resolved from the PostgreSQL database (`quant.stock`) by checking if their `stock_group` JSONB array contains the sector symbol:
  ```sql
  SELECT symbol FROM quant.stock WHERE stock_group::jsonb @> %s::jsonb AND is_active = True
  ```
- **Fallback Holdings:** If the database contains no active constituent mappings, a pre-defined fallback list containing the top 10 liquid holdings for each Sector ETF is loaded to prevent dashboard interruption.

---

## 3. Temporal Diagnostics (The Chronology Suite)

The Vector Lab integrates **Live Intraday Sweeping** alongside historical settlement to provide three primary views for auditing capital flow:

### 3.0 Live Market-Hour Sweep Engine
During active market sessions, the gateway automatically executes asynchronous multi-ticker `yfinance` sweeps across all monitored sector or component targets. If the current date lacks a finalized database entry, the engine dynamically constructs an unclosed daily bar using real-time quotes, preserving RRG normalizations, baseline merging parity, and live user sequence scrubbing.

### 3.1 Visual & Tabular Views
The dashboard provides a tabbed switcher for toggling between different analytical scopes:

1. **Vector Map (Sector-Level):** Sector-to-market rotation vectors normalized against SPY, QQQ, etc.
2. **Component Map (Component-Level):** Individual constituent relative strength and momentum vectors normalized against their parent Sector ETF.
3. **Sector Registry:** Detailed database constituent table showing individual stock attributes, group mappings, and active statuses.

### 3.2 Trajectory Trails (RRG Map)
The RRG Map visualizes relative rotation through four distinct quadrants:

| Quadrant | Position | Strength (X) | Momentum (Y) | Institutional Sentiment |
| :--- | :--- | :--- | :--- | :--- |
| **Leading** | Top-Right | > 100 | > 100 | High Conviction Outperformance |
| **Weakening** | Bottom-Right | > 100 | < 100 | Fading Outperformance |
| **Lagging** | Bottom-Left | < 100 | < 100 | Confirmed Underperformance |
| **Improving** | Top-Left | < 100 | > 100 | Emerging Accumulation |

- **Trajectory Trails:** Each node leaves a historical path of configurable length (Tail Depth) demonstrating rotation direction. Clockwise rotation confirms structural accumulation.

### 3.3 Trajectory Chronology (Trend Chart)
A time-series audit for the selected symbols.
- **Plotted Line:** Shows the $RS-Ratio$ over time to visualize structural relative strength trajectories.
- **Selection parity:** Users can click on nodes in the RRG Map or rows in the Rotation Board to multi-select and compare their historical strength trajectories side-by-side.

### 3.4 Two-Column Real-Estate Layout Architecture
To maximize the utilization of standard and wide-screen desktop real estate, the dashboard implements a highly dense, dual-column interactive structure:
- **Left Column (Visual & Temporal Stack):**
  - **Trajectory Chronology (Top):** Time-series relative strength analysis for comparison of user-selected tickers.
  - **RRG Map (Bottom):** High-density aspect-square scatter plot charting real-time rotation vectors and historical trail depths with automated playback controls.
- **Right Column (Analytical Feed Stack):**
  - **Rotation Board:** High-frequency grid listing exact normalized coordinates, Hurst values, and Net GEX figures.
  - **Alpha Insight Box:** Context-aware strategic guidelines generated based on current active sector states.

---

## 4. Parametric Control Engine

To eliminate visual friction and align relative strength vectors with optimized trading profiles, the numeric sliders for Lookback and Momentum have been consolidated into **Segmented Institutional Presets**:

### 4.1 Institutional Swing Presets

| Preset | Target Hold Period | Lookback Window | Momentum Factor | Operational Focus |
| :--- | :--- | :---: | :---: | :--- |
| **Tactical Swing** | 3 - 10 Days | `60d` | `5d` | High-beta momentum trading. Responsive to rapid, early-stage capital velocity inflections. |
| **Intermediate Swing** | 2 - 4 Weeks | `100d` | `10d` | *Default baseline*. Filters short-term noise to isolate stable, multi-week capital rotation. |
| **Macro Position** | 1 - 6 Months | `252d` | `20d` | Long-term macro cycle tracking. Isolates secular accumulation trends over 1 trading year. |

### 4.2 Dynamic Trajectory Controls

| Control Parameter | Range | UI Element | Operational Impact |
| :--- | :--- | :--- | :--- |
| **Tail Depth** | 0 - 40p | Deck Slider | Adjusts the number of trailing vector segments displayed for path tracing. |
| **Chronos Sequence** | 0 - 60p | Playback Slider | Replays and steps through historical time-series sequences to audit past rotation cycles. |
| **Baseline Dropdown** | SPY, QQQ, Sector ETFs | Dropdown | Redefines the baseline asset against which all relative vectors are normalized. |

---

## 5. Strategic Operational Policy
1. **Automated Governance Integration:** Newly added investment targets are automatically mapped to GICS sector classifications, aligning GICS sector values to govern component rotation baseline assignment.
2. **Regime Identification:** Identify symbols in the **Improving** quadrant (Top-Left).
3. **Persistence Audit:** Ensure `Hurst > 0.55` (indicated by persistent trend strength).
4. **Volatility Support:** Confirm `Positive GEX` for low-volatility allocation or `Negative GEX` for tactical breakout chasing.
5. **Temporal Audit:** Verify the **Trajectory Trail** is moving clockwise and the **Chronology Chart** shows Momentum leads Ratio.

---

## 6. RRG Quadrant Transition Matrix Reference
For a complete statistical mapping of all four quadrant transition pathways, baseline probabilities, failed inside-turn rates, and tactical strategies, see the comprehensive [RRG Quadrant Transition Matrix](file:///Users/kepingbi/20260408/docs/research/016-rrg_transition_matrix.md) research guide.


