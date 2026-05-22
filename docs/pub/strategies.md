# QuantEdge Studio: Institutional Strategy Library

This document outlines the core algorithmic strategies active in the QuantEdge Studio Research Lab. Each engine is designed to capture specific institutional market regimes, from aggressive breakouts to conservative trend following.

> **Meta-Governor:** All strategies in this library are governed by the **MRA Regime Classifier**. This Multi-Resolution Analysis engine dynamically suppresses Trend/Aggressive strategies in Choppy regimes, and Mean Reverting strategies in Trending regimes.

### MRA Regime Surface Area
The regime classification is surfaced across the entire institutional pipeline:

| Surface | Location | Rendering |
|---|---|---|
| **Watchlist Dashboard** | Tactical Symbols grid, `MRA Regime` column | Color-coded badge per symbol |
| **Target Intelligence Audit** | Institutional Verification panel header | `MRA: TRENDING` label next to Auto-Audit button |
| **Daily Audit Browser** | Strategy Breakdown section | Regime tag alongside confidence scores |
| **Nightly Discovery Sweeps** | `discovery_candidates.metadata` (Postgres) | Badge on each candidate card |

---

## 1. Aggressive Strategies
*Designed for high-velocity environments and explosive volatility expansion.*

### **Minervini VCP (Volatility Contraction Pattern) [Swing]**
- **Logic**: Implements Mark Minervini’s core SEPA logic. It scans for "tightening" price action where the standard deviation of returns decreases sequentially (20-day > 10-day > 5-day vol).
- **Significance**: A high-conviction **Swing** engine that identifies institutional accumulation. It detects the moment supply is exhausted, allowing even small buying pressure to trigger a massive breakout.
- **Key Indicators**: SMA 150/200 Trend Template, Relative Volatility, Volume Dry-up.

### **Institutional Gap [Swing]**
- **Logic**: Scans for "Change of Character" gaps—price increases of 4%+ on volume exceeding 300% of the 20-day average.
- **Significance**: A powerful **Swing** engine identifying where "Big Money" has aggressively entered a stock. This captures the start of Post-Earnings Announcement Drift (PEAD).
- **Key Indicators**: Gap %, Volume Multiplier, Intraday Fade/Hold check.

### **Swing - Momentum Breakout**
- **Logic**: Targets "Coiling" ranges where the price stays within a 12% corridor for 20+ days. Triggers on a range breakout with confirmed volume.
- **Significance**: Captures the first leg of a momentum move after a long consolidation. Includes a "Parabolic Exit" trigger if RSI exceeds 85.
- **Key Indicators**: T-Line (8 EMA), Bollinger Squeeze, RSI.

### **Guru Wavelet Crossover**
- **Logic**: A zero-lag tactical engine utilizing a 3-level MODWT decomposition. It reconstructs a "true" price line ($S_3$ and $D_3$) while eliminating $D_1$ and $D_2$ noise.
- **Significance**: By filtering out microstructure static, it generates extremely precise entry/exit crossover signals against raw price action, preserving sharp breakouts without moving-average lag.
- **Key Indicators**: MODWT Causal Filter, Trailing ATR Stop-Loss.

### **Bollinger Squeeze**
- **Logic**: Based on the concept of volatility clustering. It identifies when the Bollinger Bandwidth reaches a 6-month low.
- **Significance**: Volatility always follows a squeeze. This engine bets on the direction of the expansion, typically leading to explosive multi-day runs.
- **Key Indicators**: Bollinger Bandwidth, SMA 20.

---

## 2. Trend Following Strategies
*Designed for stable, high-probability growth in established market regimes.*

### **RRG Relative Strength**
- **Logic**: Utilizes Relative Rotation Graph (RRG) math to compare symbols against the SPY. Calculates RS-Ratio (Trend) and RS-Momentum (Acceleration).
- **Significance**: Forces the system to prioritize sector outperformers. It triggers when a stock rotates into the "Leading" quadrant, ensuring capital is only deployed in high-alpha names.
- **Key Indicators**: RS-Ratio, RS-Momentum, SPY Baseline Comparison.

### **Triple SMA Momentum**
- **Logic**: The "Institutional Bread and Butter." Requires price to be above the 20, 50, and 200 SMAs, with all averages trending upwards in alignment.
- **Significance**: Ensures the stock has the wind of institutional "Big Money" at its back. It is the most conservative and reliable signal in the library.
- **Key Indicators**: SMA 20, SMA 50, SMA 200.

### **Swing - Trend Continuation**
- **Logic**: Specifically targets "Pullbacks" or "Dips" within a confirmed uptrend. It looks for price to touch the 20-day EMA and bounce.
- **Significance**: Allows for low-risk entries at structural support. It avoids "chasing the peak" by waiting for a mean-reversion event within a larger bull cycle.
- **Key Indicators**: 20 EMA, Fibonacci Retracements, Bullish Engulfing/Hammer Candlesticks.

---

## 3. Mean Reversion Strategies
*Designed to capture pivot points and structural reversals from extreme conditions.*

### **Mean Reversion Alpha (v2.0)**
- **Logic**: Uses a combination of Bollinger Band pierces and ADX filtering. Triggers when a stock is overextended but the trend strength (ADX) is low.
- **Significance**: Profitable in sideways or choppy markets. It buys the extreme bottom and sells the extreme top of a range.
- **Key Indicators**: Bollinger Bands, ADX, Momentum Divergence.

### **Swing - Reversal Pivot**
- **Logic**: Identifies "Bullish Divergence" where the price makes a lower low but the MACD/RSI makes a higher low.
- **Significance**: One of the highest Risk-to-Reward (R:R) setups. It aims to catch the exact pivot point where selling pressure is exhausted despite falling prices.
- **Key Indicators**: MACD Histogram, RSI Divergence, Bollinger Band Reversion.

### **RSI/MACD Reversion**
- **Logic**: A pure exhaustion play. Triggers when RSI hits extreme levels (< 30 or > 70) while MACD signals a momentum flip.
- **Significance**: Useful for "Knife Catching" in extreme market panic or selling the "Top" during irrational exuberance.
- **Key Indicators**: RSI, MACD.

---

*QuantEdge Studio Strategy Documentation - Last Updated: 2026-05-07*
