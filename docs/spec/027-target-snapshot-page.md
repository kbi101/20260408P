# 027 Target Snapshot Page Specification

## 1. Objective
To provide a comprehensive, modeless "Deep Dive" interface for any selected symbol within the QuantEdge Studio platform. This interface aggregates technical, quantitative, and fundamental data points into a single draggable widget, allowing researchers to evaluate assets without losing context of the primary grid.

## 2. Trigger Point
- **Page:** `apps/frontend/src/components/LiveTrading/SwingRecommendationsTab.tsx` and `UniversalAlphaEngineTab.tsx`
- **Location:** Action row of the individual recommendation cards and the universal funnel inspection.
- **Component Details:** A button labeled **"Research Deep Dive"**.
- **Action:** Clicking this button appends the selected symbol to an `openSnapshots` state array (managed in `SwingRecommendationsTab`) and launches the modeless `<TargetSnapshot />` component.

## 3. UI/UX Design (Modeless Float)
- **Library:** `framer-motion` (specifically `<motion.div drag />`).
- **Features:** 
  - Draggable handle in the header.
  - Z-Index management (brings the active window to the front on focus).
  - Close/Minimize controls in the top right corner.
  - Sized appropriately to fit within a modern desktop display without overwhelming the viewport.

## 4. Component Layout
The Snapshot Window uses a structured Grid/Flexbox layout.

### Header
- Symbol identifier.
- Company Name.
- Current Market Price (if fetched).
- Window controls (Drag handle, Minimize, Close).

### Body Sections
**Section A: Visual Analytics**
- **Component:** Repurposed `<PriceChart />`
- **Details:** Displays the historical chart with baseline indicators (SMA, EMA, Bollinger Bands). Receives `symbol` as a prop.

**Section B: Calculated Intelligence**
Aggregates quantitative insights:
- **Options Data:** Max Pain, GEX, Resistance, and Support (derived from `OptionsAnalytics` / `OptionFlowArchitect`). Includes integrated CBOE Volatility Index (**Market VIX**) via non-blocking multi-threaded background fetch, aggregate/expiration-level implied volatility (**Asset IV**), and both aggregate and per-expiration **Put-Call Ratios (OI & Volume PCRs)**.
- **Relative Strength:** Sector classification (dynamically resolved from PostgreSQL `quant.stock`'s `stock_group` mapping with local dictionary fallback to prevent static default errors for REITs like AMH/WELL) and Relative Strength scores (RS-Ratio, RS-Momentum).
- **Pattern Recognition:** 
  - Positive triggers (e.g., Bull Flag, VCP).
  - Negative triggers (e.g., Bear Flag, H&S).
- **Strategy Engine:** Triggered Entry/Exit signals from active algorithms.
- **AI Forecasting:** 
  - Foundation Forecast.
  - Current Regime State (Bull, Bear, Sideways).
  - TimeSFM predicted ranking.

**Section C: Fundamental & Market Data**
A high-contrast informational grid containing:
- **Earnings:** Last ER Date, Next ER Date.
- **Financials:** P/E Ratio, Beta.
- **Sentiments:** Analyst Sentiment Score, Broad Market Sentiment.

## 5. Architectural Requirements
1. **Component Modularity:** Existing complex components (e.g., `MLPredictionTab`, `PatternBrowser`) must be refactored to accept a `symbol` prop, ensuring they can render locally within the Snapshot without relying on global page states or internal search bars.
2. **Unified Data Ingestion:** 
   - A new backend endpoint `/api/snapshot/{symbol}` should be created to aggregate required intelligence.
   - This prevents the "waterfall" effect of 10+ isolated React components firing concurrent network requests when a window opens.

## 6. Implementation Scope
- [x] Backend: Design and deploy `/api/snapshot/{symbol}`.
- [x] Frontend: Build the `<TargetSnapshot />` modeless shell using Framer Motion.
- [x] Frontend: Refactor required sub-components to support isolated symbol props.
- [x] Frontend: Integrate `<TargetSnapshot />` into `SwingRecommendationsTab.tsx` and `UniversalAlphaEngineTab.tsx`.
