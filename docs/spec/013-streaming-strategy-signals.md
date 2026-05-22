# Streaming Strategy Signals: Real-time Algorithmic Processing

This document outlines the architectural requirements for transitioning strategies from static backtesting to real-time signal generation using streaming data feeds.

## 1. The Streaming Hypothesis
For a strategy to generate signals live, it must be able to process an incoming "Pulse" (a single price update or tick) and determine its state relative to historical context instantly.

### Signal Frequency
*   **Bar-Driven Signals**: Strategies wait for a full interval (e.g., 1 minute) to close before evaluating. This is the "Stable" mode.
*   **Pulse-Driven Signals (Intra-bar)**: Strategies evaluate every incoming tick. This is essential for Mean Reversion to catch Bollinger Band piercings exactly as they occur.

## 2. Stateful Strategy Architecture
To handle streaming data, strategies must evolve from **Batch-Oriented** (Pandas DataFrames) to **State-Oriented** (Event Loops).

### Internal Buffering
*   Strategies should maintain an internal "Tail Buffer" of the last $N$ periods (e.g., the last 20 periods for a 20-SMA).
*   **Warm-up Step**: When a streaming session starts, the strategy fetches historical context from **QuestDB** to populate its buffer before the first tick arrives.

## 3. The Signal Packet
Instead of "Order Routing," the focus is on generating valid **Match Packets** that can be observed in the Research Lab or sent to a monitor.

```json
{
  "strategy": "MeanReversion_v2",
  "symbol": "META",
  "signal": "BUY",
  "confidence": 0.85,
  "metrics": {
    "price": 498.42,
    "lower_band": 499.10,
    "pierce_depth": 0.68
  },
  "timestamp": "2026-04-13T11:20:00Z"
}
```

## 4. Signal-Stream Analytics
Streaming signals allows for the calculation of:
*   **Signal Latency**: Time between the price tick and the generation of the match.
*   **Signal Decay**: How long a "BUY" match remains valid as new ticks arrive.
*   **Drift Check**: Comparing the streaming signal results against the static backtester to ensure mathematical parity between real-time and archival logic.
