# Implementation Plan 021: Live Trade Simulation Ledger

## Phase 1: Database Schema — ✅ Pending
- [ ] Create table `quant.simulated_trades` in PostgreSQL.
  ```sql
  CREATE TABLE IF NOT EXISTS quant.simulated_trades (
      id SERIAL PRIMARY KEY,
      symbol VARCHAR(10) NOT NULL,
      entry_date DATE NOT NULL,
      entry_price DECIMAL(18,4) NOT NULL,
      shares INTEGER DEFAULT 100,
      exit_date DATE,
      exit_price DECIMAL(18,4),
      status VARCHAR(10) DEFAULT 'OPEN',
      pnl_percent DECIMAL(8,4),
      notes TEXT,
      recommendation_id INTEGER,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  ```

## Phase 2: Backend API (FastAPI) — ✅ Pending
- [ ] **File:** `apps/api/research/pattern_detection.py` (Add new routes)
  - `POST /simulations/open`:
    - Payload: `{ recommendation_id: int }`
    - Logic: Fetch recommendation, insert into `simulated_trades`.
  - `GET /simulations`:
    - Logic: Return all records, sorted by status (OPEN first) then date.
  - `PATCH /simulations/close/{id}`:
    - Payload: `{ exit_price: float, notes: str }`
    - Logic: Update record, set status='CLOSED', calculate pnl_percent.

## Phase 3: Frontend Development — ✅ Pending
- [ ] **File:** `apps/frontend/src/services/api.ts`
  - Add service functions for simulation endpoints.
- [ ] **File:** `apps/frontend/src/components/LiveTrading/SwingRecommendationsTab.tsx`
  - Add "Simulate Trade" button to recommendation cards.
- [ ] **File:** `apps/frontend/src/components/LiveTrading/LiveTradeSimulationTab.tsx` (CREATE)
  - Implement the simulation ledger view.
  - Professional table with Monospace numbers.
  - "Close" dialog/modal for entering exit price and notes.
- [ ] **File:** `apps/frontend/src/pages/LiveTrading.tsx`
  - Register the new tab.

## Phase 4: Integration & Verification — ✅ Pending
- [ ] Validate end-to-end flow from recommendation to ledger.
- [ ] Ensure P/L math is accurate.
- [ ] Perform full container rebuild.
