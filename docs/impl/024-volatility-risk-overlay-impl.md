# Implementation Plan 024: Volatility & Exit Intelligence Lab

## Phase 1: Mathematical Core — ✅ PENDING
- [ ] Create `libs/shared/risk_engine.py`.
- [ ] Implement `OUProcess` class for mean-reversion parameter estimation (theta, mu, sigma).
- [ ] Implement `GARCHForecaster` class using the `arch` library for GARCH(1,1) volatility projections.
- [ ] Develop `DynamicRiskOverlay` to translate GARCH forecasts into ATR-multiplier stop-losses.

## Phase 2: Backend API Integration — ✅ PENDING
- [ ] Create `apps/api/research/risk_models.py` (New Router).
- [ ] Add `POST /research/risk/analyze` endpoint:
  - Input: `symbol`, `horizon`.
  - Output: OU mean-reversion target, GARCH 15-day volatility forecast, and suggested dynamic stop-loss.

## Phase 3: Ensemble Engine Hardening — ✅ PENDING
- [ ] Update `libs/shared/ensemble_engine.py` to optionally use GARCH stop-losses for symbols with high volatility clusters.
- [ ] Inject OU mean-reversion targets as "Secondary Profit Targets" in recommendation objects.

## Phase 4: Frontend Development — ✅ PENDING
- [ ] Create `VolatilityRiskTab.tsx` in `apps/frontend/src/components/Predictions/`.
- [ ] Implement "Risk-Adjusted Exit" visualizer:
  - Half-life countdown (OU Mean Reversion).
  - Volatility Corridor (GARCH Forecast).
- [ ] Register new tab in `Predictions.tsx`.

## Phase 5: Verification — ✅ PENDING
- [ ] Validate GARCH convergence on high-volatility symbols (AFRM, APLD).
- [ ] Compare OU targets against historical 50-day SMA reversions.
- [ ] Rebuild and deploy containers.
