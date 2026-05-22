# Fundamentals Dashboard

## Objective

Introduce an **Executive Fundamental Dashboard** page to QuantEdge Studio, positioned between Investment Targets and Research Lab in the sidebar. The page enables institutional-grade evaluation of a company's financial health — ROIC, FCF dynamics, leverage, and valuation multiples — with sub-5-second comprehension latency.

## Key Design Principles

- **Data density over decoration.** Typography hierarchy carries the visual weight; color is used exclusively for status signaling.
- **Bloomberg-meets-research-report aesthetic.** Monospace tabular numerics, sharp-corner radius (`0.125rem`), no decorative gradients.
- **Options-aware context bridging.** Live Spot Price, Gamma Flip, and Max Pain surface alongside accounting data to instantly flag when a structurally sound company is trapped in a short-gamma zone.
- **Perpetual memory.** Active ticker and toggle states persist across sessions via `localStorage`.

---

## 1. Sidebar Integration

| Property | Value |
|---|---|
| Route | `/fundamentals` |
| Sidebar position | Below Investment Targets, above Research Lab |
| Icon | `account_balance` (Material Symbols) |
| Label | `Fundamentals` |
| Accent color | `text-amber-500` |

---

## 2. Global Header & Control Bar

A sticky sub-header inside the page body, following the Volatility Lab header pattern.

**Left cluster:**
- **Ticker selector** — dropdown populated from `/api/v1/targets`, same style as Volatility Lab's symbol select.
- **Company name & metadata** — bold headline next to the selector, with Sector / Industry pills rendered as `bg-primary/5 text-primary/60` badges.
- **Bridge metrics strip** — inline horizontal block showing:  
  `Live Spot Price` · `Gamma Flip` · `Max Pain`  
  Sourced from the existing options/GEX endpoints to bridge microstructure with fundamentals.

**Right cluster:**
- **Time Horizon toggle** — segmented pill control: `5-Year (Default)` / `10-Year` / `20-Year Full History`
- **View toggle** — `Quarterly (10-Q)` / `Annual (10-K)`

---

## 3. Row 1: Health & Quality Scorecard (Top Fold)

Four KPI cards in a `grid-cols-4` row, each surfacing a single decisive institutional metric.

| Card | Primary Metric | Sub-Text | Alert Logic |
|---|---|---|---|
| **Capital Efficiency** | ROIC | 5-Yr Average | Green > 15% · Yellow 8–15% · Red < WACC |
| **The Cash Engine** | FCF Yield | FCF Margin | Green > 10Y Treasury + 2% |
| **Leverage Risk** | Net Debt / EBITDA | Total Debt ($B) | Yellow > 2.5x · Red > 5.0x |
| **Debt Service** | Interest Coverage | EBIT / Interest Exp | Red < 2.0x |

Status badges:
- **Optimal** — `bg-emerald-500/10 text-emerald-400` with static dot
- **Caution** — `bg-amber-500/10 text-amber-400` with static dot
- **Critical** — `bg-rose-500/10 text-rose-400` with pulsing dot

Tooltip on hover: formula overlay + raw data points (e.g., `ROIC = NOPAT / Invested Capital = $5,120M / $27,826M`).

---

## 4. Row 2: Core Financial Engine (Main Body)

Split grid — `col-span-8` left, `col-span-4` right.

### Left: Cash & Income Matrix

A clean financial table with quarterly columns. Row design:

| Column | Purpose |
|---|---|
| Trend (mini-sparkline) | 32×16px inline SVG, primary color for positive trend, error color for declining |
| Line item name | Bold, readable label |
| Q1–Q4 numerical cells | Right-aligned, tabular-nums, monospace |

**Displayed line items:** Total Revenue · Operating Income (EBIT) · Operating Cash Flow · Capital Expenditures · Free Cash Flow (highlighted in `text-primary font-black`) · Shares Outstanding (Diluted)

Table toolbar includes an `Export to CSV` utility button (top-right of the panel).

### Right: Valuation & Peer Comp

**Valuation Multiples block:**
- Trailing P/E with historical median and valuation badge (`Undervalued` / `Fair` / `Stretched`)
- Forward P/E
- PEG Ratio with `Growth Justified` badge when < 1.0
- EV / EBITDA

**Peer Multiples Comparison widget:**
A horizontal mini-bar chart comparing EV/EBITDA against top 3 closest sector peers. Target company bar uses `bg-primary`; peers use `bg-primary/30`. A `◀ YOU` label marks the active ticker.

---

## 5. Row 3: Pipeline Integrity & System Alerts (Bottom Fold)

A collapsible structural footer (same interaction as ResearchLab's log strip).

**Status items displayed:**
1. **Data Source:** Connection status to Alpha Vantage + last successful sync timestamp
2. **Database:** PostgreSQL ↔ DuckDB parity confirmation
3. **Variance Alerts:** Automatically surfaced anomalies (e.g., CapEx spike, FCF margin compression)

---

## 6. Data Source Strategy

Initial implementation uses **Alpha Vantage** (existing API key from env).

| Alpha Vantage Function | Consumed Data |
|---|---|
| `OVERVIEW` | P/E, PEG, EV/EBITDA, Beta, Sector, Industry, Market Cap, Shares Outstanding |
| `INCOME_STATEMENT` | Revenue, EBIT, Interest Expense (quarterly + annual) |
| `BALANCE_SHEET` | Total Debt, Cash, Shareholders Equity |
| `CASH_FLOW` | OCF, CapEx → FCF derived |

**Client-side derived metrics:**

| Metric | Formula |
|---|---|
| ROIC | NOPAT / (Total Equity + Long-Term Debt) |
| FCF | Operating Cash Flow − Capital Expenditures |
| FCF Yield | FCF / Market Cap |
| FCF Margin | FCF / Revenue |
| Net Debt/EBITDA | (Short+Long Debt − Cash) / EBITDA |
| Interest Coverage | EBIT / Interest Expense |

> **Caching strategy:** Alpha Vantage free tier = 25 req/day. Responses cached in `localStorage` with a 6-hour TTL keyed by `fundamentals_${ticker}_${view}`.

---

## 7. Component Architecture

```
pages/
  Fundamentals.tsx

components/Fundamentals/
  FundamentalsHeader.tsx      ← Ticker, bridge metrics, toggles
  HealthScorecard.tsx         ← 4-card KPI row
  KPICard.tsx                 ← Reusable conditional-color card
  FinancialTable.tsx           ← Cash & Income matrix with sparklines
  ValuationPanel.tsx           ← Multiples + peer comp
  PeerComparisonChart.tsx      ← Mini horizontal bar chart
  SystemAlerts.tsx             ← Pipeline integrity footer
```
