# Institutional Audit & Discovery System Specification [v4.5]

## 1. Overview
The **Institutional Audit & Discovery System** is a high-fidelity automation layer within QuantEdge Studio designed to reduce manual trade verification friction. It bridges real-time market data (QuestDB) and institutional options flow (DuckDB) to identify, score, and track trade setups through a magnitude-aware diagnostic framework.

## 2. Core Detection Library
The system tracks the following "High Conviction" long-side patterns:

### Technical Archetypes (QuestDB Source)
*   **SMA20 Rebound**: Price interaction with the 20-period Simple Moving Average on the daily interval.
*   **9/21 EMA Cross**: Exponential Moving Average crossover tracking (Bullish Momentum Acceleration).
*   **VCP (Volatility Contraction)**: Identifying tightening price action following a strong uptrend.
*   **UpTrend Regime**: Structural health verification (higher highs/higher lows).
*   **ORB Breakout**: Opening Range Breakout (Intraday verification).
*   **VWAP Reclaim**: Price successfully reclaiming and holding the VWAP.
*   **Relative Strength (RS)**: Comparing symbol performance against SPY/Sector over a trailing 20-day window.

### Institutional Flow (DuckDB Source)
*   **GEX (Gamma Exposure)**: Positive GEX concentration below current market; acts as an institutional price floor.
*   **Volume Expansion**: Significant increase in trading volume accompanying price move.

## 3. Magnitude-Aware Diagnostics
Unlike binary indicators, the v4.5 audit engine exposes raw metrics to determine "Setup Strength":
*   **GEX Notional ($M)**: Real-world dollar value of dealer hedging support (Pulsing high-intensity badge for >$10M GEX).
*   **Volume Intensity (Ratio)**: Current volume relative to 20-day average (e.g., 1.5x VOL).
*   **RS Alpha (%)**: Exact percentage of outperformance relative to SPY (e.g., +2.3% RS).

## 4. Automated Scoring Logic
Every target is assigned a **Setup Quality Score (1-5)**:
*   **Score Calculation**: `+1` for every confirmed pattern.
*   **Institutional Filter**: Setups are promoted to the "Discovery Pulse" only if they contain at least one technical archetype AND one institutional flow marker (GEX/Vol Expansion).

### 3.4. Dual-Phase Audit Pipeline (v4.6 Update)
To eliminate the 14-hour latency between market close and morning options settlement, the system utilizes a two-phase audit architecture:

*   **Phase 1: Technical Preview (PREVIEW)**:
    *   **Trigger**: 4:15 PM EST (Post-Close).
    *   **Scope**: High-fidelity price-action signatures (QuestDB).
    *   **Status**: `PREVIEW` (Amber Badge in UI).
    *   **Goal**: Immediate visibility into technical breakouts before institutional settlement.
*   **Phase 2: Institutional Settlement (FINAL)**:
    *   **Trigger**: 7:30 AM EST (Next Day).
    *   **Scope**: Price + Institutional GEX/OI Flow (DuckDB).
    *   **Status**: `FINAL` (Green Badge in UI).
    *   **Goal**: "Hardening" the technical signals with settled dealer positioning data.

**Upsert Logic**: The `discovery-settlement-sweep` uses an `ON CONFLICT` strategy to upgrade existing `PREVIEW` candidates to `FINAL` status, ensuring a single source of truth for each `scan_date`.

## 6. Layout Architecture & Interaction Standards
The UI follows a "Combat Cockpit" philosophy, ensuring critical diagnostics are always in view without obscuring the active registry.

*   **Push-Pane Workbench**: The Target Intelligence Audit is a persistent side-panel that **pushes** the main dashboard to the left when open, rather than overlaying it.
*   **Operational Modes**:
    *   **View Mode (ReadOnly)**: Default locked state for browsing targets.
    *   **Edit Mode (Engagement)**: Unlocked state via "Edit Diagnostic" trigger for manual checklist updates and tactical thesis revision.
*   **Interaction Persistence**: LocalStorage tracking for `isPanelOpen` and `isDiscoveryMinimized` ensures layout continuity across sessions.
*   **Unified Selection**: Row-level click listeners synchronize the side-pane with the selected target instantly.
*   **Non-Blocking Governance**: Custom "Commit-to-Delete" state-based flows replace disruptive browser alerts to maintain UI thread stability.

## 7. Performance Ledger: Realized P&L
A surgical tracking module for historical trade auditing.
*   **Accounting Logic**: **FIFO (First-In, First-Out)** matching.
*   **KPIs Tracked**: Realized P&L, Institutional Win Rate, and Average Holding Duration.
