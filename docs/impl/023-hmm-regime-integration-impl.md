# Implementation Plan 023: HMM Tactical Regime Integration

## Phase 1: Engine Hardening — ✅ COMPLETED
- [x] Create shared HMM engine in `libs/shared/hmm_regime.py`.
- [x] Implement Z-score normalization and real-world tactical profiling.
- [x] Verify state labeling heuristics (Bull, Bear, Sideways).

## Phase 2: Database Schema & Persistence — ✅ COMPLETED
- [x] Alter `quant.ensemble_recommendations` table to include:
  - `hmm_regime` (VARCHAR)
  - `hmm_confidence` (DECIMAL)
  - `hmm_tactical_directive` (VARCHAR)
- [x] Update `pattern_detection.py` to persist HMM metadata during scans.

## Phase 3: Ensemble Intelligence Sync — ✅ COMPLETED
- [x] Inject `MarketRegimeHMM` into `ensemble_engine.py`.
- [x] Implement score modifiers (+1.5 for Bull, -2.0 for Bear).
- [x] Add confidence-based score throttling (50% throttle if < 60% confidence).

## Phase 4: API & UI Visibility — ✅ COMPLETED
- [x] Refactor `get_watchlist` API to join with latest HMM recommendations.
- [x] Add dynamic HMM Environment badges to `WatchListTab.tsx`.
- [x] Add HMM Intelligence Audit side panel in `WatchListTab.tsx`.
- [x] Add "Regime (HMM)" column and tactical audit to `EnsembleAudit.tsx`.

## Phase 5: Verification & Deployment — ✅ COMPLETED
- [x] Validate symbol-specific profiling (SPY vs QQQ vs BTC).
- [x] Resolve "0% returns" bug in engine data flow.
- [x] Rebuild and deploy frontend/api containers.
