# Spec 018: Wavelet Denoising Integration for QuantEdge Studio

## 1. Rationale & Objective
Minute-level data is plagued by micro-structure noise (bid-ask bounce, HFT pinging). Traditional smoothing techniques like Simple Moving Averages (SMA) or Exponential Moving Averages (EMA) introduce unacceptable lag and "blur" critical price jumps. 

Wavelet denoising acts as an adaptive, zero-lag filter. It mathematically separates pure noise from genuine trend impulses, allowing us to preserve sharp corners (breakouts) while flattening high-frequency static. This aligns perfectly with the QuantEdge "Clean Data First" philosophy and will significantly reduce false-positive triggers across the algorithmic portfolio.

## 2. Technical Architecture
To ensure institutional-grade reliability and parity between backtesting and live execution, the following constraints must be strictly adhered to:

### Transform Method
We will utilize the **Maximal Overlap Discrete Wavelet Transform (MODWT)**. Unlike standard DWT, MODWT is shift-invariant and handles arbitrary data lengths without requiring a power-of-2 input size.

### The Causality Constraint (CRITICAL)
Standard wavelet libraries (e.g., `PyWavelets`) utilize centered filters that peek into the future, introducing look-ahead bias. The implementation **must** enforce **Causal Wavelet Filtering**, guaranteeing that the denoised value at $T_0$ relies exclusively on historical data ($T \le 0$).

### Thresholding Logic
Thresholds will be calculated using the Universal Threshold formula: $\lambda = \sigma \sqrt{2 \ln(n)}$, where $\sigma$ is estimated via Median Absolute Deviation (MAD).
* **Hard Thresholding:** Applied to Aggressive engines to preserve sharp breakout spikes.
* **Soft Thresholding:** Applied to Trend-Following engines to produce smoother, continuous signals.

### Mother Wavelets
* **Daubechies (`db4` or `db8`)**: Default for general equity price action due to good frequency localization.
* **Haar**: Specialized for detecting gap/stair-step regime shifts.

## 3. Portfolio Integration & Applications
Wavelet filtering will act as a foundational utility layer in `libs/quant-core` applied across three distinct domains:

### A. Supercharging Existing Strategies
* **Aggressive Breakouts (Minervini VCP, Momentum):** Triggers will execute against the MODWT reconstructed price rather than raw 1-minute prints, preventing "faked out" entries from algorithmic pinging at resistance levels.
* **Mean Reversion Alpha:** Denoised signals will clarify true exhaustion points during Bollinger Band pierces, eliminating early false signals.

### B. ML Engine Feature Extraction (Noise-to-Trend Ratio)
By decomposing the signal, we can evaluate the ratio of energy in the $d_1$ coefficient (highest frequency noise) against the $d_4$ coefficient (underlying trend). A sudden spike in $d_1$ with a flat $d_4$ is a strong indicator of a "fake" mean-reverting move. This **Noise-to-Trend Ratio** will be piped into PostgreSQL as a high-value feature for the ML prediction ensemble.

### C. New "Guru" Crossover Engine
Introduction of a specialized intraday/swing strategy based on a 3-level MODWT decomposition:
* Reconstruct a "true" price line using only the $s_3$ (Smooth) and $d_3$ (Trend Detail) coefficients.
* Zero out the $d_1$ and $d_2$ (Noise) coefficients.
* Generate buy/sell signals based on crossovers between this zero-lag reconstructed line and the raw noisy price.

### E. Structural Wick Compression (v4.6 Feature)
To maintain visual and structural integrity when viewing denoised candles, the system implements **Structural Wick Compression**:
*   **Logic**: Instead of denoising High/Low independently (which creates "ghost wicks" that don't touch the body), we denoise the absolute volatility range ($High - Low$) and then **reconstructive-center** it around the denoised Price ($s_4$).
*   **OHLC Consistency**: The final candle is forced into structural consistency: $High \ge \max(Open, Close)$ and $Low \le \min(Open, Close)$.
*   **Outcome**: The resulting "Wavelet Candles" reflect the structural volatility of the underlying regime, effectively denoising the wick noise without breaking the physical candle structure.

## 4. Implementation Roadmap
1. **Phase 1: Validation (Scratchpad)**
   Set up a Python research notebook to evaluate `PyWavelets` and `modwt` libraries. Validate causal filtering math against a volatile ticker (e.g., TSLA, BABA) to ensure absolute zero look-ahead bias.
2. **Phase 2: Core Utility Development**
   Build a vectorized `WaveletFilter` class in `libs/quant-core` that ingests raw Pandas/Numpy price arrays and outputs causally denoised series.
4. **Phase 4: API & UI Integration**
   Deploy the causal denoising filter to the FastAPI layer and expose it as a toggleable overlay in the React charting interface.
5. **Phase 5: MRA Regime Classifier**
   Develop `get_mra_energy_distribution` to calculate variance across all subbands and implement a regime classifier that acts as a meta-governor for the trading pipeline.
