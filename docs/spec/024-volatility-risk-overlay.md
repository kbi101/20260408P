# Research Spec 024: High-Volatility Risk & Mean Reversion Overlay

## Objective
Implement institutional-grade predictive models for high-volatility assets. The goal is to identify precise mean-reversion exit points (OU Process) and dynamic, volatility-adjusted stop-losses (GARCH) for 21-day tactical swings.

## 1. Ornstein-Uhlenbeck (OU) Mean Reversion
The OU Process is used to model the "rubber band" effect in oversold/overbought conditions.
- **Model**: $dX_t = \theta (\mu - X_t)dt + \sigma dW_t$
- **Target**: Predicted time and price for return to the 50-day Moving Average (Mean).
- **Metric**: Half-life of Mean Reversion (days to equilibrium).

## 2. GARCH (Volatility Clusters)
Generalized Autoregressive Conditional Heteroskedasticity (GARCH) predicts the "stickiness" of volatility.
- **Model**: GARCH(1,1) for conditional variance forecasting.
- **Application**: 3-week (15-bar) forward volatility projection.
- **Risk Overlay**: If GARCH predicts volatility expansion, stop-losses are widened (e.g., 2.5x ATR). If it predicts contraction, stops are tightened (e.g., 1.5x ATR) to lock in gains.

## 3. Implementation Requirements
- **Feature Window**: 252-bar (1-year) daily data for model calibration.
- **Library**: `arch` for GARCH modeling; `scipy.optimize` for OU parameter estimation.
- **Integration**:
  - **Ensemble Engine**: GARCH-based stop-loss calculation replaces static ATR stops for high-volatility clusters.
  - **Research Lab**: New "Volatility & Exit Audit" tab for visual trade protection.

## 4. Success Metrics
- **Risk Reduction**: Decrease in "Premature Stop-Outs" during low-volatility drifts by 20%.
- **Exit Precision**: Improvement in "Realized Alpha" by exiting within 5% of predicted OU mean-reversion targets.

## Full Universe Audit (2026-05-11)
- **Universe**: 86 symbols (quant.stock)
- **Lookback**: 90 Days
- **Parallelization**: 15 ThreadPool Workers
- **Risk Hardening**: GARCH dynamic stops & OU mean-reversion equilibrium enforced.
- **Progress Reporting**: Granular bar-level atomic increments.
