# 029 Fundamentals Dashboard Implementation

## Status
- [ ] Sidebar nav entry
- [ ] Route registration in `App.tsx`
- [ ] Alpha Vantage data fetching service functions
- [ ] Backend proxy endpoints (optional — to protect API key)
- [ ] `Fundamentals.tsx` page scaffold
- [ ] `FundamentalsHeader` component
- [ ] `HealthScorecard` + `KPICard` components
- [ ] `FinancialTable` component with mini-sparklines
- [ ] `ValuationPanel` component
- [ ] `PeerComparisonChart` component
- [ ] `SystemAlerts` component
- [ ] `localStorage` caching layer (6-hour TTL)
- [ ] CSV export utility

---

## Implementation Details

### 1. Sidebar Entry
**File:** `apps/frontend/src/components/Layout/Sidebar.tsx`
- [ ] Insert new `NavItem` into `navItems` array between `targets` and `research`:
  ```ts
  { to: '/fundamentals', icon: 'account_balance', label: 'Fundamentals', color: 'text-amber-500' }
  ```

### 2. Route Registration
**File:** `apps/frontend/src/App.tsx`
- [ ] Import `Fundamentals` page component.
- [ ] Add `<Route path="fundamentals" element={<Fundamentals />} />` after the `targets` route.

### 3. Alpha Vantage API Functions
**File:** `apps/frontend/src/services/api.ts`
- [ ] Add `fetchFundamentalsOverview(symbol)` → calls `OVERVIEW` function.
- [ ] Add `fetchIncomeStatement(symbol)` → calls `INCOME_STATEMENT` function.
- [ ] Add `fetchBalanceSheet(symbol)` → calls `BALANCE_SHEET` function.
- [ ] Add `fetchCashFlow(symbol)` → calls `CASH_FLOW` function.
- [ ] Implement a unified `fetchFundamentals(symbol, view: '10-Q' | '10-K')` orchestrator that calls all four and derives computed metrics.
- [ ] Cache all responses in `localStorage` with 6-hour TTL key: `fundamentals_${symbol}_${view}`.
- [ ] Alpha Vantage base URL: `https://www.alphavantage.co/query?apikey=${AV_API_KEY}&...`

**Derived metric helpers (pure functions in `services/fundamentalsUtils.ts`):**
- [ ] `computeROIC(netIncome, taxExpense, totalEquity, longTermDebt) → number`
- [ ] `computeFCF(ocf, capex) → number`
- [ ] `computeFCFYield(fcf, marketCap) → number`
- [ ] `computeFCFMargin(fcf, revenue) → number`
- [ ] `computeNetDebtEBITDA(shortDebt, longDebt, cash, ebitda) → number`
- [ ] `computeInterestCoverage(ebit, interestExpense) → number`
- [ ] `getKPIStatus(metric, thresholds) → 'optimal' | 'caution' | 'critical'`

### 4. `Fundamentals.tsx` Page Scaffold
**File:** `apps/frontend/src/pages/Fundamentals.tsx`
- [ ] State: `symbol` (from `localStorage` fallback to first target), `view: '10-Q' | '10-K'`, `horizon: '5Y' | '10Y' | '20Y'`, `data`, `isLoading`, `error`.
- [ ] On mount: load targets list, set default symbol, call `fetchFundamentals`.
- [ ] On symbol/view/horizon change: re-fetch and update.
- [ ] Layout: `flex flex-col h-full overflow-hidden bg-surface text-on-surface`.

### 5. `FundamentalsHeader` Component
**File:** `apps/frontend/src/components/Fundamentals/FundamentalsHeader.tsx`
- [ ] Ticker `<select>` — same style as Volatility Lab (`bg-surface-container-low border border-outline-variant/20 rounded-xl px-4 py-2 text-sm font-bold font-mono`).
- [ ] Company name + Sector/Industry badge pills (`bg-primary/5 text-primary/60 rounded-md border border-primary/10`).
- [ ] Bridge metrics strip (Spot, Gamma Flip, Max Pain) — sourced from existing `/api/v1/options` endpoints for the selected symbol. Render as a compact inline `flex gap-6` block with dividers.
- [ ] Time Horizon segmented toggle: `bg-surface-container-high/50 p-1 rounded-2xl` container; active pill: `bg-primary text-on-primary rounded-xl`.
- [ ] View toggle (10-Q / 10-K): same segmented pill pattern.

### 6. `HealthScorecard` + `KPICard` Components
**Files:** `apps/frontend/src/components/Fundamentals/HealthScorecard.tsx`, `KPICard.tsx`
- [ ] `HealthScorecard`: `grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4`.
- [ ] `KPICard` props: `title`, `primaryValue`, `primaryLabel`, `subValue`, `subLabel`, `status: 'optimal' | 'caution' | 'critical'`, `tooltipFormula`, `tooltipCalc`.
- [ ] Card shell: `bg-surface-container-low/40 p-6 rounded-3xl border border-outline-variant/5 hover:border-primary/20 transition-all hover:shadow-2xl hover:shadow-primary/5`.
- [ ] Primary metric: `text-3xl font-mono font-black text-on-surface`.
- [ ] Status badge: conditional color classes per `status` value (emerald / amber / rose).
- [ ] Tooltip: `onMouseEnter` shows a `position: absolute` overlay with formula + raw data; `onMouseLeave` hides it. Style: `bg-surface-container-highest border border-outline-variant/20 rounded-xl p-3 shadow-2xl text-[11px] font-mono`.

### 7. `FinancialTable` Component
**File:** `apps/frontend/src/components/Fundamentals/FinancialTable.tsx`
- [ ] Wrapping panel: `bg-surface-container-lowest rounded-3xl border border-outline-variant/10 p-6 shadow-xl shadow-primary/5`.
- [ ] Table toolbar (top-right): `Export to CSV` button.
- [ ] Table header: `text-[9px] font-bold uppercase tracking-[0.3em] text-on-surface-variant/40 border-b border-outline-variant/10`.
- [ ] Each row: `border-b border-outline-variant/5 hover:bg-surface-container-low/50 transition-colors`.
- [ ] Trend column: inline SVG sparkline (32×16px). Positive slope → `stroke: var(--primary)` / `#7bd0ff`; negative → `stroke: var(--error)`.
- [ ] Numerical cells: `text-sm font-mono text-right tabular-nums text-on-surface`.
- [ ] FCF row emphasis: `font-black text-primary`.
- [ ] CSV export: serialize visible rows to CSV blob and trigger `<a download>`.

### 8. `ValuationPanel` Component
**File:** `apps/frontend/src/components/Fundamentals/ValuationPanel.tsx`
- [ ] Wrapping panel: `bg-surface-container-low/40 rounded-3xl border border-outline-variant/5 p-6`.
- [ ] Section title: `text-[9px] font-bold uppercase tracking-[0.3em] text-on-surface-variant/40 mb-4`.
- [ ] Each multiple row: metric label (`text-xs text-on-surface-variant/60`) + value (`text-lg font-mono font-bold`) + optional badge.
- [ ] Valuation badges: Undervalued → `bg-emerald-500/10 text-emerald-400`; Fair → `bg-amber-500/10 text-amber-400`; Stretched → `bg-rose-500/10 text-rose-400`.
- [ ] Includes `PeerComparisonChart` sub-component below.

### 9. `PeerComparisonChart` Component
**File:** `apps/frontend/src/components/Fundamentals/PeerComparisonChart.tsx`
- [ ] Peers hardcoded per ticker for MVP (e.g., BABA → JD, PDD, AMZN); future: derive from sector peer group.
- [ ] Horizontal bar chart: `<div>` bars with inline `width: %` style. Target bar → `bg-primary`; peers → `bg-primary/30`.
- [ ] Labels: `text-xs font-mono font-bold` for ticker, `text-xs font-mono text-on-surface-variant` for value.
- [ ] `◀ YOU` indicator on target row: `text-[9px] font-bold text-primary uppercase ml-2`.

### 10. `SystemAlerts` Component
**File:** `apps/frontend/src/components/Fundamentals/SystemAlerts.tsx`
- [ ] Collapsible footer strip (same toggle pattern as ResearchLab logs).
- [ ] Status row template: `flex items-center gap-2 text-xs font-mono text-on-surface-variant/60`.
- [ ] Status dot: `w-1.5 h-1.5 rounded-full` — emerald for healthy, amber + `animate-pulse` for warning.
- [ ] Variance alerts derived from comparing YoY or QoQ deltas in the financial data: flag if CapEx change > 20% YoY, FCF margin drops > 5pp, etc.

---

## Testing & Validation
- [ ] Verify Alpha Vantage responses parse correctly for multiple tickers (BABA, AAPL, NVDA).
- [ ] Confirm `localStorage` cache prevents duplicate API calls within the 6-hour TTL.
- [ ] Verify conditional KPI status colors render correctly at all threshold boundaries.
- [ ] Validate sparkline SVG renders without crashing on incomplete quarterly data (< 4 quarters).
- [ ] Confirm CSV export produces valid, correctly-ordered output.
- [ ] Confirm sidebar link appears in correct position and `text-amber-500` accent renders across all 5 themes.
- [ ] Confirm Bridge Metrics (Gamma Flip, Max Pain) gracefully degrade to `N/A` if options data is unavailable for a ticker.
