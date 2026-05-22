# Research Spec 023: HMM Tactical Regime Integration

## Objective
Implement Hidden Markov Model (HMM) regime detection as a primary tactical filter for the QuantEdge Ensemble Engine. This integration ensures that trade recommendations are only promoted if they align with the 21-day market environment.

## 1. Tactical Filter Logic
The Ensemble Engine will now perform a dual-layered environment check:
- **MRA (Multi-Resolution Analysis)**: Directional bias (Trend vs. Chop).
- **HMM (Hidden Markov Model)**: Structural environment (Low Vol Bull, High Vol Bear, Sideways).

### Score Modifiers (Cumulative)
| HMM State | Impact on BUY Signals | Impact on SELL Signals | Tactical Action |
|-----------|-----------------------|-------------------------|-----------------|
| **LOW_VOL_BULL** | +1.5 Score Bonus | -0.5 Score Penalty | Aggressive Momentum |
| **HIGH_VOL_BEAR** | -2.0 Score Penalty | +1.5 Score Bonus | Tail-Hedging / Exit |
| **SIDEWAYS** | -1.0 Score Penalty | +1.0 Score Bonus | Mean-Reversion Only |

## 2. Confidence Thresholding
Recommendations will now include an `hmm_confidence` metric. Signals generated with HMM confidence below **60%** will be flagged as "TRANSITION" and will have their `ensemble_score` throttled by 50% to prevent over-trading during regime shifts.

## 3. Implementation Blueprint
### Backend (Ensemble Engine)
1.  **HMM Injection**: Instantiate `MarketRegimeHMM` within `scan_symbol`.
2.  **Feature Synchronization**: Use the same 500-day OHLCV history as the trigger strategies.
3.  **Metadata Persistence**: Inject `hmm_regime` and `hmm_confidence` into the terminal recommendation object.

### Frontend (Watchlist/Audit)
1.  **Environment Badging**: Display the HMM state as a color-coded chip in the Tactical Grid.
2.  **Audit Panel**: Include the HMM Tactical Directive in the "Target Intelligence Audit" side panel.

## 4. Performance Benchmarking
- **Success Metric**: Reduction in "Chop Losses" by >15% through regime-aware throttling.
- **Audit Requirement**: Every `watchlist` entry must persist the HMM state at the time of promotion.
