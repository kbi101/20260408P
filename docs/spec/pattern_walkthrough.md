# Walkthrough: Structural Archetype Auditing

The QuantEdge Diagnostic Suite now incorporates a sophisticated pattern detection engine for structural market analysis. This walkthrough details the workflow for performing high-fidelity structural audits.

## 1. Navigating the Diagnostic Workspace
*   **Select a Ticker**: Choose any symbol from your active target registry in the left sidebar.
*   **Refresh Strategy**: If the chart lacks sufficient historical context (e.g., 200 SMA is flat), click **REFRESH DATA**. This triggers a bi-directional backfill, providing up to 2 years of Price-Ink history.
*   **Structural Toggling**: Use the **Analytical Toolbar** within the Price Chart to toggle SMA50, SMA200 (Trend), or VOL (Participation) overlays.

## 2. The Archetype Registry
The system automatically monitors three primary market regimes:

### Trending Archetypes (Expansion)
Verify the structural "stacking" of price relative to the 50/200 SMAs. Look for **Golden Crosses** within their 5-day transitional expansion window.

### Reversal Archetypes (Inflection)
Key for identifying major trend exhaustion. Use the **HS Top** (Distribution) and **V-Bottom** (Capitulation) cards to audit sudden sentiment shifts.

### Sideways Archetypes (Equilibrium)
Monitor for **Bollinger Squeezes**. These represent coiled energy; a squeeze matched with a volumeless Darvas Box signifies a major impending expansion.

## 4. Multi-Resolution Auditing Workflow
The Diagnostic Suite now supports seamless resolution transitions with automated depth scaling:
1.  **Select Resolution**: Toggle between **Swing** (1d, 1w, 4h, 1h) and **Day** (15m, 5m, 1m) tabs.
2.  **Automated Zoom Baseline**: The system automatically applies resolution-proportional zoom depths (e.g., 2 full sessions for 1m, 1 year for 1d).
3.  **Visual Session Pacing**: For high-frequency resolutions (sub-hour), look for **dashed vertical dividers** marking each new session transition.

## 5. Session-Aware Auditing (Extended Hours)
Isolate regular market structure from pre/post-market volatility:
*   **Toggle Ext Hours**: Use the "EXT HOURS" switch to instantly filter the archival ledger.
*   **Regular Session Only (Default)**: Strategic for identifying institutional order flow and core structural support/resistance without "ghost prints."
*   **Full Pulse View**: Activate Extended Hours for high-fidelity auditing of overnight sentiment shifts and gap-fill trajectories.

## 6. Nano-Scale Scannability
The **Nano-Scale Workspace** is designed for extreme information density:
*   **Atomic Pattern Grid**: View up to 5 archetype categories horizontally.
*   **Signal Status**: Pattern cards collapse to their atomic baseline unless a **MATCH** is confirmed (>80% confidence), in which case high-conviction structural metadata is dynamically expanded.

## 7. Transitioning to Streaming Signals
Once a structural hypothesis is validated via the Research Lab, it can be engaged for real-time monitoring:
*   **Streaming Logic**: See [013-streaming-strategy-signals.md](file:///Users/kepingbi/20260408/docs/research/013-streaming-strategy-signals.md) for technical specifications on streaming tick-by-tick auditing and automated signal generation.
