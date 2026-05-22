# 022: TimesFM 2.5 Predictive Engine Integration

## Status: OPERATIONAL
**Owner:** QuantEdge Engineering
**Context:** Time-Series Foundation Models (TSFM)
**Version:** 2.5 (High-Fidelity Transformer)

## 1. Executive Summary
Integration of Google's **TimesFM 2.5** foundation model into the QuantEdge ecosystem. This module provides institutional-grade forecasting by leveraging a transformer-based architecture pre-trained on 100B+ time-points. The engine is tuned for **Momentum Responsiveness** using a 252-bar context window.

## 2. Hardware Specification (Bare Metal)
To maximize the throughput of the Mac Studio (M2 Ultra/M4 Max), the engine is deployed natively to ensure direct access to the **Unified Memory Architecture** and **GPU (MPS)**.

| Component | Specification |
| :--- | :--- |
| **Backend** | PyTorch + Metal Performance Shaders (MPS) |
| **Environment** | Python 3.11 (Native) |
| **Model** | `google/timesfm-2.5-200m-pytorch` |
| **Precision** | Float32 (Optimized for MPS stability) |
| **Acceleration** | Native Apple Silicon (Bare Metal) |

## 3. Institutional Resolution
The engine is compiled and optimized for the following research standard:

*   **Transformer Context**: 252 trailing daily bars (1 Trading Year).
*   **Forecast Horizon**: 15-bar (3-week) forward projection.
*   **Quantile Mapping**: 10th and 90th percentiles for uncertainty corridors.
*   **Normalization**: Reversible Instance Normalization (RevIn) enabled for price scaling.

## 4. Integration Architecture
The engine operates as a standalone microservice (`timesfm_engine`) on Port **8005**.

### 4.1 Data Flow
1.  **Ingestion**: `EnsembleEngine` or `ResearchLab` fetches 252 trailing daily bars from QuestDB.
2.  **Orchestration**: API Gateway (`pattern_detection.py`) bridges the request to the bare-metal service.
3.  **Inference**: `timesfm_engine` performs a zero-shot forecast on the Mac Studio GPU.
4.  **Return**: Service returns a 15-bar trajectory with point forecasts and confidence corridors.

## 5. API Interface (Gateway)
*   **Endpoint**: `POST /api/research/timesfm/forecast`
*   **Payload**: `{"symbol": "SPY", "horizon": 15}`
*   **Key Returns**:
    *   `predictions`: Array of 15 median price points.
    *   `upper_bound`: 90th percentile corridor.
    *   `lower_bound`: 10th percentile corridor.
    *   `history`: 252-bar context for visualization alignment.

## 6. Recommendation Engine Integration (Proposal)
The **Foundation Conviction Multiplier (FCM)** will be injected into the `EnsembleRecommendationEngine`:

| Signal | Trajectory Condition | Score Modifier |
| :--- | :--- | :--- |
| **Bullish Conviction** | T+15 Price > 2% from Spot | +1.5 Score Bonus |
| **Bearish Warning** | T+15 Price < -2% from Spot | +1.5 Sell Bonus |
| **High Uncertainty** | Quantile Spread > 10% of Spot | -1.0 Score Penalty |
| **Target Validation** | FCM Target < ATR Target | Use FCM for Conservative PT |

## 7. Deployment & Auto-Start Instructions

To ensure the TimesFM microservice runs reliably across system reboots, it is registered as a macOS **Launch Agent**. Running it as a Launch Agent allows it to run inside the user's graphical login session, which is required to access the GPU/MPS hardware acceleration.

### A. Plist Configuration: [com.quantedge.timesfm.plist](file:///Users/kepingbi/20260408/services/timesfm_engine/com.quantedge.timesfm.plist)
The Launch Agent is registered at `~/Library/LaunchAgents/com.quantedge.timesfm.plist` and configured to run on startup/login and auto-restart on crashes (`KeepAlive`).

### B. Setup & Bootstrapping
1. Copy the plist configuration to the user agents directory:
   ```bash
   cp /Users/kepingbi/20260408/services/timesfm_engine/com.quantedge.timesfm.plist ~/Library/LaunchAgents/com.quantedge.timesfm.plist
   ```
2. Free up port 8005 if a manual instance is running:
   ```bash
   lsof -ti:8005 | xargs kill -9 || true
   ```
3. Load and start the service daemon:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.quantedge.timesfm.plist
   ```

### C. Useful Commands
* **Start Service**: `launchctl start com.quantedge.timesfm`
* **Stop Service**: `launchctl stop com.quantedge.timesfm`
* **Unload/Disable Service**: `launchctl unload ~/Library/LaunchAgents/com.quantedge.timesfm.plist`
* **Check Logs**: `tail -f /Users/kepingbi/20260408/services/timesfm_engine/timesfm.log`

