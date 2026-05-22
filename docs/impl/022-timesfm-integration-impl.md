# Implementation Plan 022: TimesFM 2.5 Predictive Engine Integration

## Phase 1: Bare Metal Environment — ✅ COMPLETED
- [x] Configure Python 3.11 environment on Mac Studio (M2 Ultra/M4 Max).
- [x] Install PyTorch with Metal Performance Shaders (MPS) support.
- [x] Setup `google/timesfm-2.5-200m-pytorch` model weights and dependencies.

## Phase 2: Forecasting Microservice — ✅ COMPLETED
- [x] Create standalone engine in `services/timesfm_engine/main.py`.
- [x] Implement inference logic with 252-bar context and 15-bar horizon.
- [x] Optimize for MPS acceleration (Apple Silicon Native).
- [x] Expose high-performance endpoint on Port 8005.

## Phase 3: API Gateway Orchestration — ✅ COMPLETED
- [x] Add `getTimesFMForecast` service to `apps/frontend/src/services/api.ts`.
- [x] Implement bridge endpoint in `apps/api/research/pattern_detection.py`.
- [x] Orchestrate data flow from QuestDB (252 trailing bars) to the TimesFM microservice.

## Phase 4: Frontend Visualization — ✅ COMPLETED
- [x] Create `TimesFMTab.tsx` or similar component for research visualization.
- [x] Implement interactive chart with 15-day forward projection and quantile corridors.
- [x] Integrate forecasting into the `SwingRecommendationsTab` for predictive auditing.

## Phase 5: Ensemble Intelligence Sync — ✅ PENDING
- [x] Implement Foundation Conviction Multiplier (FCM) in `ensemble_engine.py`.
- [x] Inject T+15 trajectory conditions into ensemble score calculation.
- [x] Verify target price validation against ATR-based stops.

## Phase 6: Operationalization — ✅ COMPLETED
- [x] Implement `nohup` daemonization for persistent engine availability.
- [x] Configure automated health monitoring and log rotation for `timesfm.log`.
