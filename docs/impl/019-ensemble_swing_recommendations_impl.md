# Implementation Notes 019: Ensemble Swing Trade Recommendations

## Design Decisions

### Answers to Open Questions (User Feedback — 2026-05-08)
1. **Scan Universe**: Watch list symbols only (`quant.watchlist`), not the full `quant.stock` registry.
2. **Caching Strategy**: Option B — persist per day in a new `quant.ensemble_recommendations` table. Needed for historical success rate verification and backtest calibration.
3. **Score Threshold**: Default 3.0, but must be calibrated via backtest once enough historical data is accumulated.
4. **Risk Parameters**: Configurable in the UI — user can set account risk % for position sizing.
5. **Sell Recommendations**: Calculate both BUY and SELL, persist both in the DB table. SELL signals surface in the Portfolio tab (not the Recommendations tab).

---

## Phase 1: Ensemble Engine (Backend Core Logic) — ✅ Complete

**Goal:** Create the unified recommendation engine that runs all strategies and patterns against watchlist symbols.

### File: `libs/shared/ensemble_engine.py` (CREATE)

- [ ] Import and instantiate all 11 strategy classes:
  - **Triggers (7)**: `SwingMomentumBreakoutStrategy`, `SwingTrendContinuationStrategy`, `SwingReversalPivotStrategy`, `MinerviniVCPStrategy`, `InstitutionalGapStrategy`, `Strategy` (Bollinger Squeeze), `GuruWaveletCrossoverStrategy`
  - **Confirmations (4)**: `Strategy` (Triple SMA Momentum), `RRGRelativeStrengthStrategy`, `MeanReversionStrategy`, `Strategy` (RSI/MACD Reversion)
- [ ] Import `analyze_patterns` from `shared.patterns`
- [ ] Import `WaveletFilter` from `shared.quantitative.wavelets`
- [ ] Implement `EnsembleRecommendationEngine` class with:
  - `scan_symbol(symbol: str, df: pd.DataFrame) -> dict | None`
    - Run each trigger strategy: `calculate_indicators()` → `generate_signals()`
    - Run each confirmation strategy: same flow
    - Run `analyze_patterns(df, interval="1d")` for pattern-based triggers/confirmations
    - Run `WaveletFilter.get_mra_energy_distribution()` for MRA regime
    - Fetch Options Context (from `db/options_analytics.db` via DuckDB):
      - Compute `max_pain`, `gamma_flip`, `call_wall`, and `oi_pcr`.
    - Compute ensemble score using the weighted formula (including Option Sentiment confirmation).
    - Compute risk profile (ATR, stop, target, R:R)
    - Return structured recommendation dict if qualifies, else None
  - `scan_all(symbols: list[str]) -> list[dict]`
    - For each symbol: fetch 500 daily bars from QuestDB, call `scan_symbol()`
    - Return sorted by `ensemble_score` descending
  - `fetch_ohlcv(symbol: str) -> pd.DataFrame`
    - Query QuestDB for trailing 500 daily bars

### Key Conventions
- All strategy classes use different naming: some use `Strategy` (generic), some use full names. Must handle import aliases carefully.
- `generate_signals()` returns `tuple[str, float]` → `(signal, confidence)` for all strategies.
- Pattern detectors return `{"is_match": bool, "confidence": float, "data": dict}`.
- Strategy classes that need QuestDB (e.g., RRG) access it via `httpx` internally. Ensure `QUESTDB_HOST` env is available.
- Wrap each strategy in try/except to prevent one failure from killing the entire scan.

### Risk Profile Calculation & Institutional Rationale

The engine computes a standardized risk profile for every recommendation to ensure consistent trade sizing and expectation management.

```python
# 1. ATR (Average True Range) - Volatility Measurement
# Using 14-period standard to capture the 'heartbeat' of the asset.
df['tr'] = np.maximum(df['high'] - df['low'], 
                     np.maximum(abs(df['high'] - df['close'].shift(1)), 
                               abs(df['low'] - df['close'].shift(1))))
atr_14 = df['tr'].rolling(14).mean().iloc[-1]

# 2. Stop Loss (1.5x ATR)
# Rationale: 1.5x ATR is the 'noise threshold'. A move beyond this indicates 
# a structural failure of the immediate trade thesis rather than simple volatility.
stop_loss = last_price - (1.5 * atr_14)

# 3. Target Price (20-bar Swing High)
# Rationale: For swing trades, the primary objective is a retest of recent 
# structural resistance. 20 trading days (1 month) identifies the most 
# relevant recent ceiling.
target_price = df['high'].rolling(20).max().iloc[-1]

# 4. Risk/Reward Ratio (R:R)
# Rationale: We only prioritize 'asymmetric' opportunities. 
# Ideal trades exhibit R:R > 2.0.
risk_reward = (target_price - last_price) / (last_price - stop_loss) if last_price > stop_loss else 0
```

*   **ATR Calculation**: Uses the True Range (TR) which accounts for overnight gaps, ensuring the stop is not placed too tight in gapping stocks.
*   **Stop Logic**: By using a volatility-adjusted stop (ATR), we ensure that high-beta stocks (like NVDA) are given more "breathing room" than low-volatility assets (like KO).
*   **Target Logic**: The 20-bar rolling maximum provides a conservative but realistic profit target based on documented historical resistance levels.

---

## Phase 2: Database Schema & API Endpoint — ✅ Complete

### Schema Migration
- [ ] Create table `quant.ensemble_recommendations` (see spec Section 6.1)
- [ ] Auto-create via `CREATE TABLE IF NOT EXISTS` in the activity (following existing pattern from discovery_candidates)

### File: `apps/api/research/pattern_detection.py` (MODIFY)

- [ ] Add endpoint: `GET /api/v1/research/recommendations`
  - Query params: `min_score` (float, default 3.0), `max_results` (int, default 20), `scan_date` (optional, default today)
  - Logic: Query `quant.ensemble_recommendations` for the given scan_date where side='BUY' and score >= min_score
  - Return JSON with `generated_at`, `threshold`, `recommendations[]`
  - Fallback: if no cached results for today, return empty list with a `status: "pending"` message

- [ ] Add endpoint: `POST /api/v1/research/recommendations/generate`
  - Manual trigger for the ensemble scan (for development/testing)
  - Runs the engine synchronously against watchlist symbols
  - Persists results to `quant.ensemble_recommendations`
  - Returns the generated recommendations

### File: `apps/api/main.py` (MODIFY — if separate router needed)
- [ ] If adding to existing pattern_detection router, no main.py changes needed
- [ ] Otherwise: register new router with prefix `/api/v1/research`

---

## Phase 3: Temporal Workflow & Activity — ✅ Complete

### File: `libs/shared/activities.py` (MODIFY)

- [ ] Add new activity class or method to `DiscoveryActivities`:
  ```python
  @activity.defn
  async def run_ensemble_recommendations(self, input_data: dict = {}) -> dict:
      # 1. Fetch watchlist symbols from quant.watchlist
      # 2. Instantiate EnsembleRecommendationEngine
      # 3. Run scan_all()
      # 4. Persist to quant.ensemble_recommendations (BUY + SELL)
      # 5. Audit outcomes for T-5 recommendations
      # 6. Return summary
  ```

### File: `libs/shared/workflows.py` (MODIFY)

- [ ] Add `EnsembleRecommendationWorkflow` class:
  ```python
  @workflow.defn
  class EnsembleRecommendationWorkflow:
      @workflow.run
      async def run(self, input_data: dict = {}) -> dict:
          return await workflow.execute_activity(
              DiscoveryActivities.run_ensemble_recommendations,
              input_data,
              start_to_close_timeout=timedelta(minutes=10)
          )
  ```

### File: `services/worker/main.py` (MODIFY)

- [ ] Import `EnsembleRecommendationWorkflow`
- [ ] Register in `ingestion-tasks` worker workflows list
- [ ] Register `run_ensemble_recommendations` activity

### File: `apps/api/main.py` (MODIFY — schedule registration)

- [ ] Add to `sync_baseline_schedules()`:
  ```python
  {"id": "ensemble-daily-recommendations", 
   "workflow": "EnsembleRecommendationWorkflow",
   "params": {},
   "task_queue": "ingestion-tasks",
   "cron": ScheduleCalendarSpec(
       day_of_week=[ScheduleRange(start=1, end=5)],
       hour=[ScheduleRange(start=16)],
       minute=[ScheduleRange(start=20)]
   )}
  ```

---

## Phase 4: Frontend Implementation — ✅ Complete

### File: `apps/frontend/src/services/api.ts` (MODIFY)

- [ ] Add `fetchRecommendations(minScore?: number, scanDate?: string)` function
- [ ] Add `triggerRecommendationScan()` function (calls POST generate endpoint)

### File: `apps/frontend/src/components/LiveTrading/SwingRecommendationsTab.tsx` (CREATE)

- [ ] State management: `recommendations[]`, `loading`, `minScore`, `regimeFilter`, `riskPercent`
- [ ] `useEffect` → `fetchRecommendations(minScore)`
- [ ] Card grid layout (sorted by ensemble_score descending)
- [ ] Each card:
  - Header: Symbol icon, name, score badge (color by tier), MRA regime tag, price + %change
  - Triggers section (left column): Red dots, strategy name, confidence %
  - Confirmations section (right column): Green checks / gray unchecked, name, confidence %
  - Risk bar: Stop loss | Target | R:R | ATR | Position size (computed from `riskPercent`)
  - Action row: Research link, Add to Watch List button, Copy Thesis button
- [ ] Filter controls bar:
  - Min score slider (range 1–10, step 0.5)
  - Regime dropdown (ALL / TRENDING only)
  - Risk % input (default 1%)
  - Date picker for historical browsing
  - Refresh / Manual scan button
- [ ] Loading skeleton shimmer cards
- [ ] Empty state with explanation when no recommendations qualify
- [ ] Follow "Scholar Ledger" aesthetic: glassmorphism cards, Material Symbols, gradient accents, micro-animations

### File: `apps/frontend/src/pages/LiveTrading.tsx` (MODIFY)

- [ ] Add `'recommendations'` to the tab union type
- [ ] Add tab entry after watchlist:
  ```typescript
  { id: 'recommendations', label: 'Recommendations' }
  ```
- [ ] Import and render `<SwingRecommendationsTab />`
- [ ] Position the tab immediately after "Watch List" in the tab array

---

## File Change Summary

| File | Action | Phase |
|---|---|---|
| `libs/shared/ensemble_engine.py` | **CREATE** | 1 |
| `apps/api/research/pattern_detection.py` | **MODIFY** | 2 |
| `libs/shared/activities.py` | **MODIFY** | 3 |
| `libs/shared/workflows.py` | **MODIFY** | 3 |
| `services/worker/main.py` | **MODIFY** | 3 |
| `apps/api/main.py` | **MODIFY** | 3 |
| `apps/frontend/src/services/api.ts` | **MODIFY** | 4 |
| `apps/frontend/src/components/LiveTrading/SwingRecommendationsTab.tsx` | **CREATE** | 4 |
| `apps/frontend/src/pages/LiveTrading.tsx` | **MODIFY** | 4 |

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Some strategies require 200+ bars; watchlist symbols may have insufficient data | Skip symbol gracefully, log warning |
| RRG strategy fetches SPY from QuestDB internally; may fail if SPY not ingested | Pre-fetch SPY data once and pass as parameter instead of per-symbol fetch |
| Endpoint is compute-heavy for many watchlist symbols | Daily Temporal persistence; API reads from cache table, not live compute |
| Strategy class naming inconsistency (`Strategy` vs `MinerviniVCPStrategy`) | Use explicit import aliases |
| `generate_signals()` may throw on edge-case data (NaN, insufficient length) | Wrap each strategy call in try/except, default to HOLD/0.0 |

## Appendix: Scoring Policy (Institutional Weights)
- **Primary Trigger (2.0)**: Discrete entry/exit events (Breakouts, VCP).
- **Confirmation (1.0)**: Structural context (RSI, Options Sentiment).
- **MRA Bonus (1.5)**: Regime-aligned trend boost.
- **Conviction Breakdown (Case Study: CMG @ 12.1)**:
    - 5 Triggers @ 2.0 = 10.0
    - 1 Confirmation @ 1.0 = 1.0
    - 1 Institutional Context Signal @ 1.1
    - **Total: 12.1**
