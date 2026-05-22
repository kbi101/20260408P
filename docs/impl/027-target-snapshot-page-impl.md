# 027 Target Snapshot Page Implementation

## Status
- [x] Backend API Endpoint (`/api/snapshot/{symbol}`)
- [x] TargetSnapshot Shell (Modeless UI)
- [x] Component Refactoring for Prop Integration
- [x] Live Trading Integration

## Implementation Details

### 1. Backend Data Aggregation
**File:** `apps/api/research/snapshot.py` and `main.py`
- [x] Create a `GET /api/v1/research/snapshot/{symbol}` endpoint.
- [x] Aggregate data from:
  - Options endpoints (Max Pain, GEX, Support, Resistance overall and per-expiry via `OptionsEnricher` dynamically enriched with live non-blocking CBOE Market VIX, aggregate/expiry-level Implied Volatility (IV), and aggregate/expiry-level Put-Call Ratios for Open Interest and Volume).
  - ML/Regime endpoints.
  - Pattern detection endpoints.
  - Fundamental data sources with live yfinance enrichment mapping P/E Ratio, Beta, Next Earnings Date, and an Advanced Multi-Factor Quantitative Sentiment Overlay deriving positioning conviction (Squeeze-Watch, Exhausted, Accumulation, Heavily-Shorted) from target spreads and short interest ratios.
  - Relative Strength ratios (RRG RS-Ratio mapping asset vs Sector ETF and Sector ETF vs SPY). Resolved dynamically from PostgreSQL `quant.stock`'s `stock_group` mapping with local dictionary fallback to prevent static default errors for REITs like AMH/WELL.
- [x] Return a unified JSON payload structured for the Snapshot UI.

### 2. TargetSnapshot Modeless Shell
**File:** `apps/frontend/src/components/Research/TargetSnapshot.tsx`
- [x] Import `framer-motion` and `useDragControls`.
- [x] Create a `<motion.div drag>` container with `dragListener={false}` to isolate dragging strictly to the top header via `dragControls.start(e)`.
- [x] Enable seamless native CSS `resize: both` without Framer Motion pan/move event stealing.
- [x] Implement header with Drag Handle, Symbol, Name, and Close button.
- [x] Implement Z-Index management via Global Context.
- [x] Render highly rich sub-panels for Options Structure (Net GEX, Max Pain, Support/Resistance matrices, CBOE Market VIX, global/expiry-level Implied Volatility, and global/expiry-level OI & Volume Put-Call Ratios) and an aesthetic visual resize indicator at the bottom right.
- [x] Integrate real-time Archival Pulse structural signatures directly into the left column layout to display positive/negative pattern triggers perfectly formatted.

### 3. Application-Wide Persistence (Global Context Hoisting)
**Files:** `apps/frontend/src/services/SnapshotContext.tsx` and `App.tsx`
- [x] Create `SnapshotProvider` to store `openSnapshots` array globally at the root layout level.
- [x] Decouple modal persistence from local component unmounting by wrapping routing context in `<SnapshotProvider>`.
- [x] Provide `useSnapshots` custom hook exposing global `openSnapshot` triggers to any downstream view.

### 4. Integration into Recommendation Portals
**File:** `apps/frontend/src/components/LiveTrading/SwingRecommendationsTab.tsx` and `UniversalAlphaEngineTab.tsx`
- [x] Integrate `useSnapshots` into the recommendations dashboards.
- [x] Trigger snapshot deep dives seamlessly from both Ensemble and Universal Alpha tabs.

## Testing & Validation
- [x] Verify multiple snapshots persist seamlessly across primary route transitions (e.g., Live Trading to Data Explorer).
- [x] Verify localized Options Structure displays real-time Support/Resistance and per-expiry GEX concentrations perfectly scaled.
- [x] Validate zero visual distortion or math scaling issues on percentage fields.
