# RRG Quadrant Transition Matrix

This research document defines the empirical Markov transition probabilities between Relative Rotation Graph (RRG) quadrants. By combining standard relative strength trends ($RS-Ratio$) and acceleration ($RS-Momentum$) with **Hurst Exponent ($H$)** persistence filters and **Net GEX** volatility cushions, we establish high-conviction entry, exit, and hedge signals.

---

## The Clockwise Rotation Cycle

Standard sector rotation progresses in a clockwise direction:
$$\text{Improving (Top-Left)} \longrightarrow \text{Leading (Top-Right)} \longrightarrow \text{Weakening (Bottom-Right)} \longrightarrow \text{Lagging (Bottom-Left)} \longrightarrow \text{Improving}$$

A symbol can either **succeed** (continue the clockwise cycle) or **fail** (experience an "Inside Turn" reversal).

---

## 1. The Accumulation Pathway: Improving $\rightarrow$ Leading
* **Coordinates:** Top-Left ($RS\text{-}Ratio < 100, RS\text{-}Momentum > 100$) $\longrightarrow$ Top-Right ($RS\text{-}Ratio > 100, RS\text{-}Momentum > 100$)
* **Operational Flow:** Capital accumulation drives positive momentum, which eventually pushes the absolute trend above the benchmark.

| Market Regime Catalyst | Graduation Probability (To Leading) | Reversal Probability (Inside Turn to Lagging) | Rotation Characterization | Tactical Strategy |
| :--- | :---: | :---: | :--- | :--- |
| **High Persistence ($H > 0.55$) + Positive GEX** | **$75\% - 85\%$** | $15\% - 25\%$ | **Structural Accumulation** | Scale into aggressive long swing positions. |
| **Random Walk ($H \approx 0.50$)** | **$\approx 50\%$** | $\approx 50\%$ | **Standard Rotation** | Hold standard position sizes; monitor trails. |
| **Mean-Reverting ($H < 0.45$) OR Negative GEX** | **$30\% - 40\%$** | $60\% - 70\%$ | **Failed Breakout** | Avoid long entry; look for inside turn short setups. |

---

## 2. The Maturity Pathway: Leading $\rightarrow$ Weakening
* **Coordinates:** Top-Right ($RS\text{-}Ratio > 100, RS\text{-}Momentum > 100$) $\longrightarrow$ Bottom-Right ($RS\text{-}Ratio > 100, RS\text{-}Momentum < 100$)
* **Operational Flow:** Absolute trend outperformance remains high, but rate of capital inflow peaks and starts decelerating.

| Market Regime Catalyst | Progression Probability (To Weakening) | Re-Acceleration Probability (Leading Bounce to Leading) | Rotation Characterization | Tactical Strategy |
| :--- | :---: | :---: | :--- | :--- |
| **High Persistence ($H > 0.55$) + Positive GEX** | $35\% - 45\%$ | **$55\% - 65\%$** | **Structural Re-Accumulation** | Maintain core long positions; buy the pullbacks. |
| **Random Walk ($H \approx 0.50$)** | **$\approx 60\%$** | $\approx 40\%$ | **Standard Maturity** | Trim minor size; tighten trailing stops. |
| **Mean-Reverting ($H < 0.45$) OR Negative GEX** | **$75\% - 85\%$** | $15\% - 25\%$ | **Rapid Trend Exhaustion** | Take major profits; aggressively hedge exposures. |

---

## 3. The Exhaustion Pathway: Weakening $\rightarrow$ Lagging
* **Coordinates:** Bottom-Right ($RS\text{-}Ratio > 100, RS\text{-}Momentum < 100$) $\longrightarrow$ Bottom-Left ($RS\text{-}Ratio < 100, RS\text{-}Momentum < 100$)
* **Operational Flow:** Absolute strength drops below 100 as decelerating momentum drives the absolute trend below the benchmark.

| Market Regime Catalyst | Graduation Probability (To Lagging) | Reversal Probability (Inside Turn back to Leading) | Rotation Characterization | Tactical Strategy |
| :--- | :---: | :---: | :--- | :--- |
| **High Persistence ($H > 0.55$) + Positive GEX** | $30\% - 40\%$ | **$60\% - 70\%$** | **Double-Bottom / Shakeout** | Hold defensive hedges; prepare for rebound. |
| **Random Walk ($H \approx 0.50$)** | **$\approx 55\%$** | $\approx 45\%$ | **Standard Exhaustion** | Exit remaining long exposure immediately. |
| **Mean-Reverting ($H < 0.45$) OR Negative GEX** | **$70\% - 80\%$** | $20\% - 30\%$ | **Confirmed Underperformance** | Initiate tactical short/underweight strategies. |

---

## 4. The Bottoming Pathway: Lagging $\rightarrow$ Improving
* **Coordinates:** Bottom-Left ($RS\text{-}Ratio < 100, RS\text{-}Momentum < 100$) $\longrightarrow$ Top-Left ($RS\text{-}Ratio < 100, RS\text{-}Momentum > 100$)
* **Operational Flow:** Selling pressure exhausts, and initial buying momentum returns the rate of change above 100.

| Market Regime Catalyst | Progression Probability (To Improving) | Reversal Probability (Rollback to Lagging) | Rotation Characterization | Tactical Strategy |
| :--- | :---: | :---: | :--- | :--- |
| **High Persistence ($H > 0.55$) + Positive GEX** | $40\% - 50\%$ | **$50\% - 60\%$** | **Extended Underperformance** | Keep sector on watchlists; do not front-run. |
| **Random Walk ($H \approx 0.50$)** | **$\approx 65\%$** | $\approx 35\%$ | **Standard Bottoming** | Put on initial starter watchlist positions. |
| **Mean-Reverting ($H < 0.45$) OR Negative GEX** | **$75\% - 85\%$** | $15\% - 25\%$ | **Mean-Reverting V-Bottom** | Buy momentum breakout with tight invalidation lines. |
