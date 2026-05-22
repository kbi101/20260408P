# Implementation Notes 015: Sector & Component Relative Rotation

## Phase 1: Database & Fallback Definition (Complete)
* [x] **PostgreSQL Constituent Querying:** Designed a query to fetch sector constituents from the `quant.stock` database table based on whether their `stock_group` JSONB array contains the requested sector:
  ```sql
  SELECT symbol FROM quant.stock WHERE stock_group::jsonb @> %s::jsonb AND is_active = True
  ```
* [x] **Curated Fallback Mapping:** Defined a static fallback dictionary in the backend representing the top 10 liquid holdings for major sector ETFs (`XLK`, `SOXX`, `XLY`, `XLV`, `XLF`, `XLI`, `XLE`, `XLB`, `XLP`, `XLU`, `XLRE`, `XLC`) to prevent UI interruptions if database mappings are empty.

---

## Phase 2: Backend API Endpoints (Complete)
* [x] **File:** [vector_lab.py](file:///Users/kepingbi/20260408/apps/api/research/vector_lab.py)
* [x] **Sector-Level Rotation endpoint:** `/sector-rotation` calculates normalized relative strength (RS-Ratio) and relative velocity (RS-Momentum) relative to standard baselines like SPY, QQQ, etc.
* [x] **Component-Level Rotation endpoint:** Added `/component-rotation` which:
  1. Resolves constituent tickers for a selected Sector ETF.
  2. Queries daily close price data from QuestDB for all constituents and the Sector baseline.
  3. Integrates live intraday bar estimation via `yfinance` download logic.
  4. Calculates RS-Ratio, RS-Momentum, Hurst exponent, and Net Options GEX relative to the Sector ETF baseline.

---

## Phase 3: Frontend Integration & Views (Complete)
* [x] **Service Layer:** Added `fetchComponentRotation` to [api.ts](file:///Users/kepingbi/20260408/apps/frontend/src/services/api.ts).
* [x] **View Tab Switcher:** Updated [SectorRotation.tsx](file:///Users/kepingbi/20260408/apps/frontend/src/pages/SectorRotation.tsx) to support three tabs:
  - **Vector Map:** Sector-to-market rotation (baseline: SPY, QQQ, etc.).
  - **Component Map:** Component-to-sector rotation (baseline: Sector ETF like XLK, SOXX, etc.).
  - **Sector Registry:** Database overview table listing GICS sector assignments and their active statuses.
* [x] **Vibrant Dynamic Coloring:** Implemented `getSymbolColor(symbol)` with a stable hashing algorithm to assign distinct colors dynamically to any number of constituent nodes on the charts.
* [x] **Viewport & Axis Scaling:** Dynamic RRG coordinates viewport bounding and slightly jittered mappings to prevent overlapping nodes on coordinate grids.

---

## Phase 4: Serialization Stability Fixes (Complete)
* [x] **Rolling Window NaN Filtration:** Added `dropna(subset=['rs_ratio', 'rs_momentum'])` directly to the calculated pandas DataFrames. This removes the leading empty cells resulting from rolling standard deviation/means and diff metrics, eliminating `500 Internal Server Error` serialization crashes caused by out-of-range floats in the FastAPI JSON response.
* [x] **Finite Value Safety Defaults:** Ensured that `hurst` exponent maps to `0.5` and `net_gex` defaults to `0.0` if calculations return non-finite values.

---

## Phase 5: Container Rebuild & Verification (Complete)
* [x] Built the production assets in the frontend container: `docker compose build frontend`.
* [x] Recreated and spun up the frontend service: `docker compose up -d frontend`.
* [x] Restarted the backend service: `docker compose restart api`.
* [x] Verified endpoints end-to-end via `curl` and confirmed correct rendering on browser refresh.

---

## Phase 6: Playback Deck Relocation (Complete)
* [x] **Relocated RRG Playback Controls:** Moved the playback controls deck outside of the aspect-square RRG map container to prevent it from overlaying and hiding symbols or vector trails in the bottom quadrants (Lagging and Weakening).
* [x] **Styling Alignment:** Redesigned the container as a standalone sibling element using `bg-surface-container-low px-6 py-4 rounded-[1.5rem] border border-outline-variant/10 shadow-xl` to ensure consistent premium dark-mode styling without absolute overlay requirements.

---

## Phase 7: State Persistence (Complete)
* [x] **State Persistence Logic:** Persisted user selections of active tabs (`activeTab`) and baselines (`baseline`, `sectorBaseline`) using browser `localStorage`.
* [x] **Lazy Initialization:** Configured state hooks to retrieve stored settings on initial mount, fallback defaulting to `'rrg'`, `'SPY'`, and `'XLK'` respectively to prevent session resetting upon browser reload.
