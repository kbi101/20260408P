# Research Diagnostic Engine: Archival Technical Visualization

## 1. Overview
The Research Diagnostic Engine is a high-fidelity visualization suite designed to correlate structural price archetypes with participation (volume) and momentum (oscillators). It emphasizes archival clarity over real-time noise, enabling researchers to perform multi-pane structural audits within a unified workspace.

## 2. Component: PriceChart
The `PriceChart` is the primary instrument of the diagnostic suite. It is a self-contained component that manages technical indicator logic, sub-pane rendering, and interactive depth controls.

### Key Capabilities:
*   **Structural Overlays:** Support for SMA (50, 200) and EMA (9, 21) trends.
*   **Participation Overlay:** Integrated Volume (VOL) diagnostics rendered as semi-transparent profile bars at the base of the price action.
*   **Recursive Momentum Panes:** Autonomous management of secondary oscillator panes for RSI, MACD, and ADX.
*   **Dynamic Scaling:** Auto-adaptive Y-axis scaling for momentum panes, isolating volatility shifts from absolute price levels.
*   **Archival Depth Control:** Interactive adjustment of the archival pulse view (sample depth) directly within the chart area.

## 3. Indicator Specifications

### Structural Trends (Overlays)
| Indicator | Logic | Color | Usage |
|-----------|-------|-------|-------|
| SMA 50 | 50-Day Simple Average | #3B82F6 | Intermediate Trend Analysis |
| SMA 200 | 200-Day Simple Average | #F59E0B | Macro Trend/Cycle Identification |
| EMA 9 | 9-Day Exponential | #10B981 | Near-term Volatility Assessment |
| EMA 21 | 21-Day Exponential | #8B5CF6 | structural Momentum Pivot Analysis |

### Participation (Volume)
*   **Rendering:** Vertical profile bars at 20% height.
*   **Color Logic:** Synchronized with price action (Green: Accumulation, Red: Distribution).
*   **Performance:** $O(N)$ archival peak calculation for high-conviction participation correlation.

### Momentum (Oscillators)
*   **RSI:** Relative Strength Index (0-100 range).
*   **MACD:** Moving Average Convergence Divergence. Support for MACD line, Signal line, and specialized Bar Histogram rendering for momentum expansion analysis.
*   **ADX:** Average Directional Index (0-100 range) for trend strength diagnostics.

## 4. Design Integration
The engine adheres to the **QuantEdge** design system, utilizing tonal layering (`surface-container-low`) for archival canvases and high-contrast structural highlighting for signal validation.

## 5. Structural Pattern Registry
The diagnostic engine maintains a comprehensive registry of archetypal patterns, categorized by market regime:

### A. Trending Archetypes (Expansion)
*   **Established Uptrend**: $Price > SMA50 > SMA200$. Bullish structural stack.
*   **Established Downtrend**: $Price < SMA50 < SMA200$. Bearish structural cascade.
*   **Golden Cross**: 50-day SMA crossing above 200-day SMA. Active for 5-day transitional window.
*   **Stage 2 Breakout**: High-volume expansion from multi-month consolidation.

### B. Reversal Archetypes (Inflection)
*   **V-Bottom**: Sharp capitulation followed by aggressive recovery.
*   **Double Bottom**: Structural W-shape base and support retest.
*   **Head & Shoulders (Top/Inverse)**: Professional exhaustion and accumulation models.
*   **Island Reversal**: Gap-separated isolation signaling sudden trend shifts.

### C. Sideways Archetypes (Equilibrium)
*   **Bollinger Squeeze**: Extreme volatility contraction signaled by band narrowing.
*   **Darvas Box**: Rigidity within horizontal support/resistance boundaries.
*   **Low ADX**: Trend exhaustion regime where $ADX < 20$.

## 6. Nano-Scale Multi-Resolution Auditing

The engine has been evolved into a "Nano-Scale" auditing environment, capable of maintaining total structural fidelity across resolution shifts from 1-minute high-frequency pulses to multi-year weekly macro views.

### A. High-Intensity Data Sanitization
To maintain archival clarity during low-liquidity sessions (Extended Hours), the engine implements a robust **Sanitization Protocol**:
*   **Outlier Suppression**: A Hampel-inspired 20-bar rolling filter automatically identifies and neutralizes "ghost prints" (bad exchange data) using a 4-sigma threshold.
*   **Liquidity-Weighted Repair**: For zero-volume bars (common in post-market), the sanitizer aggressively clips price spikes to the statistical median.
*   **Structural Reconstruction**: Artifacts identified as "barbed wire" (extreme wicks with no volume) are completely reconstructed to match the local price baseline.

### B. On-The-Fly Resampling Engine
Derivative resolutions (`5m`, `15m`, `1h`, `4h`) are generated dynamically from the primary **1-minute high-fidelity ledger** in QuestDB. This ensures that every resolution captures the same liquidity pulse without the drift associated with multiple external API calls.

### C. Visual Pacing & Normalization
*   **Eastern Time (ET) Normalization**: All X-axis coordinates are forced to `America/New_York` normalization (09:30–16:00 ET), providing a consistent temporal context for US market session audits.
*   **Session Vertical Dividers**: High-frequency charts (`1m`, `5m`, `15m`) automatically render dashed vertical lines at every daily transition to provide clear visual pacing.
*   **Nano-Density Workspace**: The UI utilizes an ultra-high-density 5-column grid with nano-scale pattern cards to maximize the volume of structural archetypes visible on a single display.
