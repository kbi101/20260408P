# 016 - ML Production Specification: "Ironclad Static"

## 1. Engine Core
- **Framework**: LightGBM (LGBMRegressor)
- **Growth Strategy**: Leaf-wise (best for non-linear macro spikes)
- **Version**: 4.6.0+

## 2. Training Strategy
- **Topology**: Static Ensemble
- **Mandatory Cutoff**: `2023-01-01` (Note: Moving this to 2025 causes a 4% performance drop due to recency bias).
- **Training Samples**: ~19,000 pooled rows across SPY, QQQ, and DIA (to capture "Institutional Gravity")
- **Validation**: 50-day Walk-Forward Audit (Minimum threshold: 80% Directional Acc)

## 3. Feature Matrix (The "Dirty Dozen")
| Category | Feature | Logic |
| :--- | :--- | :--- |
| **Momentum** | `target_lag_1,2,3` | Captured 3-day trend persistence |
| **Technical** | `rsi` | Relative strength (overbought/oversold) |
| **Technical** | `dist_sma_20` | Mean reversion boundary |
| **Volatility** | `intraday_range` | Daily High-Low volatility intensity |
| **Volatility** | `volatility_std` | 20-day price stability |
| **Risk** | `vix` | Absolute Fear Level |
| **Panic** | `vix_ratio` | VIX / 20-day Moving Average |
| **Fear Velocity**| `vix_delta` | Daily Change in Fear |
| **Macro** | `tnx` | 10-Year Treasury Yield (Interest Rate Gravity) |
| **Macro Velocity**| `tnx_delta` | Daily Change in Bond Yields |

## 4. Hyper-Parameters
```json
{
    "n_estimators": 200,
    "learning_rate": 0.05,
    "max_depth": 0,
    "num_leaves": 31,
    "feature_fraction": 0.8,
    "verbosity": 0
}
```

## 5. Performance Baseline
- **Directional Accuracy**: 84.00%
- **Hypothetical P&L**: $4,146.00 (Last 50 Trading Days)
## 6. Production Implementation
- **Orchestration**: Temporal.io `MLPredictionWorkflow` on `ingestion-tasks` queue.
- **Schedule**: Daily **16:45 ET** (Scheduled Pulse).
- **Audit Logic**: Automated "Post-Hoc" backfill. Every run audits "Yesterday's" prediction for the current day's settlement.
- **Persistence Layer**: PostgreSQL `daily_predictions` table.
- **ML Engine Logic**: Internal `GBMModel` wrapper supporting both Scikit-learn and native LightGBM Booster formats.
- **Container Hardening**: Build `v4.2.2-STABLE` includes pre-baked `lightgbm` and `scikit-learn` dependencies.

## 7. Operational Recovery
- **Manual Trigger**: `POST /api/v1/ingestion/trigger` with `{"workflow_name": "MLPredictionWorkflow"}`.
- **Weight Vault**: Model weights stored in `/app/data/models/spy_gbm_weights_YYYMMDD.json` (Native Booster Format).
- **Governance**: Every prediction must include a `targeted_accuracy` signature (currently 84.00%).

## 8. Future Roadmap (The "Quantum" Leap)
- [ ] **Advanced Time-Series Architecture**: Implement LSTM (Long Short-Term Memory) and Transformer-based models for capturing long-range future price dependencies.
- [ ] **Linear Baseline Models**: Implement Ridge and Lasso regression models to provide a stable linear prediction framework and prevent over-fitting in the ensemble.
- [ ] **Ensemble Integration**: Develop a meta-learner (Ensemble Model) to aggregate predictions from GBM, LSTM, Transformers, and Linear models into a single, high-confidence signal.
