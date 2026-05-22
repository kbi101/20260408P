# Ensemble Swing Trade Recommendations Specification [v1.0]

## 1. Overview
The **Ensemble Swing Recommendation Engine** is a signal aggregation layer that synthesizes all 11 trading strategies and 15 structural pattern detectors into a unified scoring framework. Rather than evaluating each strategy in isolation, it classifies signals as **Triggers** (discrete, actionable entry events) or **Confirmations** (structural conditions that raise conviction), producing ranked swing trade entry recommendations with full audit trails and risk profiles.

The system persists all recommendations (both BUY and SELL) to a dedicated database table daily, enabling long-term backtesting and success rate verification.

## 2. Signal Architecture

### 2.1 Classification Taxonomy

Every signal in the QuantEdge arsenal is classified into one of two roles:

**TRIGGER (Primary Entry Signal)** — A discrete, time-bound event that constitutes the *reason* to enter a trade. At least one must fire for a recommendation to qualify.

**CONFIRMATION (Structural Context)** — A background condition that validates the trade thesis. Increases conviction but is not actionable on its own.

### 2.2 Trigger Signals (Weight: 2.0 × confidence)

| Signal | Source Module | Entry Event |
|---|---|---|
| Swing – Momentum Breakout `BUY` | `Swing-MomentumBreakout.py` | Vol-Dry breakout or T-Line (8/21 EMA) crossover on volume spike |
| Swing – Trend Continuation `BUY` | `Swing-TrendContinuation.py` | 20-EMA touch + RSI reset (45–55) + bullish candle + volume confirmation |
| Swing – Reversal Pivot `BUY` | `Swing-ReversalPivot.py` | Bullish divergence (price Lower Low, MACD Higher Low) or Bollinger Band reversion |
| Minervini VCP `BUY` | `minervini_vcp.py` | Sequential volatility contraction (vol5 < vol10 < vol20) + volume dry-up at pivot |
| Institutional Gap `BUY` | `institutional_gap.py` | ≥4% gap on ≥300% average volume, unfaded intraday |
| Bollinger Squeeze `BUY` | `bollinger_squeeze.py` | Bandwidth at historical low + price breaks upper band |
| Guru Wavelet Crossover `BUY` | `Guru-WaveletCrossover.py` | Raw price crosses above MODWT-reconstructed (s3+d3) denoised line |
| EMA 9/21 Cross Up | `patterns.py::detect_ema_cross_up` | 9-period EMA crosses above 21-period EMA (hardened: was below for ≥2 bars) |
| Golden Cross (50/200) | `patterns.py::detect_golden_cross` | 50-day SMA crosses above 200-day SMA |

### 2.3 Confirmation Signals (Weight: 1.0 × confidence)

| Signal | Source Module | Structural Context |
|---|---|---|
| Triple SMA Momentum `BUY` | `triple_sma_momentum.py` | Perfect alignment: 20 > 50 > 200 SMA, price above 20 SMA |
| RRG Relative Strength (Leading) | `rrg_relative_strength.py` | Symbol in Leading quadrant (RS-Ratio > 100, RS-Momentum > 100) vs SPY |
| Mean Reversion Alpha `BUY` | `mean_reversion_v2.py` | Price pierced lower Bollinger Band in range-bound market (ADX < 20) |
| RSI/MACD Reversion `BUY` | `rsi_macd_reversion.py` | RSI < 35 (oversold) + MACD histogram curling up |
| Uptrend Regime | `patterns.py::detect_uptrend` | Price > 50 SMA > 200 SMA |
| Stage 2 Breakout | `patterns.py::detect_stage2_breakout` | Weinstein Stage 2 markup on volume surge |
| VCP Contraction | `patterns.py::detect_vcp` | Trend template passed + sequential vol contraction + volume dry-up |
| Cup & Handle | `patterns.py::detect_cup_and_handle` | U-shaped base (15–40% depth) + tight handle near left peak |
| BB Squeeze | `patterns.py::detect_bb_squeeze` | Bandwidth within 15% of 65-day historical minimum |
| SMA20 Rebound | `patterns.py::detect_sma20_rebound` | Price bouncing off 20-day SMA with bullish candle |
| Darvas Box | `patterns.py::detect_darvas_box` | Tight horizontal consolidation (< 5% range) |
| V-Bottom / Double Bottom | `patterns.py` | Base formation evidence (capitulation recovery or W-shape) |
| MRA Regime = TRENDING | `wavelets.py::WaveletFilter` | MODWT energy distribution classifies regime as favorable for trend trades |
| **Institutional Option Sentiment** | `volatility_lab.py` | Cross-chain analysis confirming bullish positioning (see 2.3.1) |

#### 2.3.1 Option Analytics Context
When options data is available, the engine extracts structural markers to confirm the institutional "footprint":

*   **Max Pain Magnet**: `BUY` confirmation if `Last Price < Max Pain` (Price often gravitates towards Max Pain at expiration).
*   **PCR Floor**: `BUY` confirmation if `OI P/C Ratio < 0.85` (Indicating call dominance and bullish sentiment).
*   **Gamma Squeeze Potential**: `BUY` confirmation if `Last Price > Call Wall` (Breaking above the largest gamma cluster often leads to a delta-hedging surge).
*   **Regime Parity**: `BUY` confirmation if `Last Price > Gamma Flip` (Indicating the symbol is in a "Positive Gamma" regime, favorable for long-only mean reversion or trend stability).

### 2.4 SELL-Side Signals

The engine also detects SELL signals from all strategies that emit `"SELL"`. These are persisted alongside BUY recommendations for portfolio-level exit auditing but are **not** surfaced in the Recommendations tab. SELL signals will be consumed by the **Portfolio Tab** for position management.

| Signal | Source | Exit Event |
|---|---|---|
| Swing – Momentum Breakout `SELL` | `Swing-MomentumBreakout.py` | Parabolic RSI ≥ 85, Fib extension hit, or ATR stop-loss |
| Swing – Trend Continuation `SELL` | `Swing-TrendContinuation.py` | 2-day close below 20 EMA, or ATR trailing stop |
| Swing – Reversal Pivot `SELL` | `Swing-ReversalPivot.py` | Middle Bollinger Band target hit, MACD bearish cross, or ATR stop |
| Minervini VCP `SELL` | `minervini_vcp.py` | Close below 50 SMA |
| Institutional Gap `SELL` | `institutional_gap.py` | Gap fill (close below previous day's close) |
| EMA 9/21 Cross Down | `patterns.py` | Bearish EMA cross |

## 3. Ensemble Scoring Formula

```
Ensemble Score = Σ(Trigger_weight × confidence) + Σ(Confirmation_weight × confidence) + Regime_modifier

Where:
  Trigger fires BUY:         weight = 2.0
  Confirmation fires BUY:    weight = 1.0
  MRA Regime TRENDING:       modifier = +1.5
  MRA Regime CHOPPY:         modifier = -1.0
  MRA Regime TRANSITION:     modifier = +0.0

Qualification Gate:
  ✓ At least 1 TRIGGER must fire BUY
  ✓ At least 1 CONFIRMATION must be active
  ✓ Ensemble Score >= configurable threshold (default: 3.0, subject to backtest calibration)
```

### 3.1 Score Calibration
The default threshold of 3.0 is an initial estimate. The persisted daily recommendations table enables **retrospective backtesting** against actual price movement to determine the optimal threshold that maximizes the hit rate while minimizing false signals. This calibration will be performed as a separate research task using the accumulated data.

## 4. Risk Context Module
Each qualifying recommendation includes computed risk parameters:

| Metric | Calculation |
|---|---|
| **ATR(14)** | 14-period Average True Range |
| **Stop Loss** | `Entry Price - 1.5 × ATR(14)` |
| **Target Price** | Recent 20-bar swing high |
| **Risk/Reward Ratio** | `(Target - Entry) / (Entry - Stop)` |
| **Position Size** | `(Account Risk %) / (Entry - Stop)` — configurable risk % in UI |

## 5. Data Sources & Scan Universe
*   **Scan Universe**: `quant.watchlist` symbols only (active monitoring targets).
*   **Price Data**: QuestDB `market_data` table (daily OHLCV, 500 trailing bars).
*   **Baseline Data**: SPY daily closes for RRG relative strength calculation.
*   **MRA Regime**: Computed via `WaveletFilter.get_mra_energy_distribution()`.

## 6. Persistence & Audit Trail

### 6.1 Database Schema
```sql
CREATE TABLE quant.ensemble_recommendations (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(10) NOT NULL,
    scan_date DATE DEFAULT CURRENT_DATE,
    side VARCHAR(4) NOT NULL,          -- 'BUY' or 'SELL'
    ensemble_score DECIMAL(6,2),
    triggers JSONB,                     -- [{name, signal, confidence, detail}]
    confirmations JSONB,                -- [{name, active, confidence}]
    risk_profile JSONB,                 -- {stop_loss, target_price, rr_ratio, atr}
    last_price DECIMAL(18,4),
    mra_regime VARCHAR(20),
    outcome_price DECIMAL(18,4),        -- Filled T+5 for success tracking
    outcome_pct DECIMAL(8,4),           -- % change at T+5
    is_successful BOOLEAN,              -- Did price move in predicted direction by T+5?
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(symbol, scan_date, side)
);
```

### 6.2 Temporal Schedule
A new Temporal schedule generates recommendations daily via the existing `ingestion-tasks` queue:

| Schedule ID | Workflow | Queue | Timing (EST) |
|---|---|---|---|
| `ensemble-daily-recommendations` | `EnsembleRecommendationWorkflow` | ingestion-tasks | Mon–Fri 4:20 PM |

### 6.3 Outcome Auditing
A separate daily job (or inline check during the next scan) fills `outcome_price`, `outcome_pct`, and `is_successful` for recommendations older than 5 trading days, enabling automated success rate tracking.

## 7. UI Specification

### 7.1 Tab Location
New tab in the Live Trading page, positioned **immediately after** the "Watch List" tab:
```
Watch List | Recommendations | Transactions | Portfolio | P&L | ...
```

### 7.2 Layout Architecture
Score-sorted card grid with glassmorphic styling. Each card contains:
*   **Header**: Symbol, ensemble score badge, MRA regime tag, last price with % change.
*   **Two-Column Body**: Left = Triggers Fired (red accent), Right = Confirmations (green checks / gray unchecked).
*   **Risk Bar**: Stop loss, target, R:R ratio, ATR value.
*   **Action Buttons**: Research (→ `/research?symbol=X`), Add to Watch List, Copy Thesis.

### 7.3 Conviction Tiers (Color Coding)
| Tier | Score Range | Accent |
|---|---|---|
| 🟢 High Conviction | ≥ 7.0 | Tertiary/green glow |
| 🟡 Moderate | 5.0 – 6.9 | Amber accent |
| 🔵 Developing | 3.0 – 4.9 | Primary/blue accent |

### 7.4 Filter Controls
*   **Min Score Slider**: Adjustable threshold (default from backtest calibration).
*   **Regime Filter**: TRENDING only / ALL.
*   **Risk % Input**: Configurable account risk percentage for position sizing.
*   **Historical Date Picker**: Browse past recommendations by scan_date.

## 8. Success Rate Tracking
Because all recommendations are persisted daily with outcome tracking:
*   **Win Rate**: `COUNT(is_successful=true) / COUNT(*)` over configurable lookback.
*   **Average Score of Winners vs Losers**: Enables threshold optimization.
*   **Per-Strategy Attribution**: Which triggers/confirmations have the highest predictive value.
*   This data will be surfaced in a future "Recommendation Performance" dashboard.
