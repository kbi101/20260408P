# Research Specification 010: Trending Momentum Archetypes

This document defines the technical logic, detection parameters, and visual signatures for the structural trending patterns in the QuantEdge ecosystem.

---

## 1. The Golden Cross (Structural Pivot)
**Definition:** A definitive momentum shift where a short-term moving average crosses above a long-term moving average.
*   **Primary Signal:** 50-day SMA crosses above 200-day SMA.
*   **Temporal Window:** Detection is active for **5 days** post-cross to capture the "transitional expansion" phase.
*   **Psychology:** Represents the "institutional threshold" where large funds transition from accumulation to mark-up.

![Golden Cross Archetype](/assets/patterns/golden_cross.png)

### Implementation Logic:
```python
def detect_golden_cross(df, short_period=50, long_period=200):
    # Check if a cross occurred within the last 5 periods
    for i in range(1, 6):
        if (df['sma_short'].iloc[-i-1] <= df['sma_long'].iloc[-i-1]) and \
           (df['sma_short'].iloc[-i] > df['sma_long'].iloc[-i]):
            return {"is_match": True, "confidence": ...}
```

---

## 2. Established Uptrend (Structural Expansion)
**Definition:** A high-probability bullish regime where price maintains stability above multi-duration support.
*   **Primary Signal:** Price > 50-day SMA AND 50-day SMA > 200-day SMA.
*   **Psychology:** Clear market consensus. Buyers are consistently absorbing supply above the primary institutional reference points.
*   **UI Signature:** Clean candle stacking above dual ascending SMAs.

![Established Uptrend](/assets/patterns/established_uptrend.png)

---

## 3. Established Downtrend (Structural Exhaustion)
**Definition:** A high-probability bearish regime where price is rejected by multi-duration resistance.
*   **Primary Signal:** Price < 50-day SMA AND 50-day SMA < 200-day SMA.
*   **Psychology:** Market capitulation. Sellers are aggressive, and institutional support has failed.
*   **UI Signature:** Candle cascading below dual descending SMAs.

![Established Downtrend](/assets/patterns/established_downtrend.png)

---

## 4. Stage 2 Markup Breakout (Weinstein Methodology)
**Definition:** Price breaking out of a 6-month+ consolidation period (Stage 1) on exceptional volume.
*   **Primary Signal:** Price > 30-week SMA AND Price > High of previous 30-day range AND Volume > 1.5x of 20-day average.

![Stage 2 Breakout Archetype](/assets/patterns/stage2_breakout.png)

---

## 5. Cup & Handle Continuity
**Definition:** A U-shaped "Cup" followed by a short consolidation "Handle" representing a final shakeout before trend continuation.

![Cup & Handle Archetype](/assets/patterns/cup_and_handle.png)
