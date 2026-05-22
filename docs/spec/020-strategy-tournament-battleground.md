# 020: Strategy Tournament & Battleground Dashboard

## Status: FINALIZED / DEPLOYED
**Owner:** QuantEdge Engineering
**Context:** Institutional Research Lab Optimization

## 1. Executive Summary
The "Strategy Battleground" is a high-fidelity comparative analysis module designed to evaluate multiple algorithmic candidates against a shared ticker universe and time-series window. It transforms the single-strategy simulation sandbox into a competitive "Tournament" environment, enabling rapid identification of alpha-generating algorithms.

## 2. Core Features

### 2.1 Strategic Arsenal (Sidebar)
*   **Multi-Select Registry:** Allows users to enlist multiple Python-based strategies from the institutional library.
*   **Bulk Actions:** Integrated "Select All" and "Deselect All" capabilities for rapid tournament orchestration.
*   **Sync Logic:** Automatically enlists the primary strategy currently being edited in "Deep Dive" mode.

### 2.2 Battleground Workspace (Main Dashboard)
*   **Dual Combat Modes:** 
    *   **Strategy Comparison (Tournament):** Benchmarks multiple algorithms against a shared stock basket.
    *   **Stock Selection (Battleground):** Benchmarks a single algorithm across multiple individual tickers to find the "best fit" asset.
*   **Competitive Leaderboard:** A data-dense matrix ranking combatants (Strategies or Tickers) by Total Return, Alpha, Sharpe Ratio, Max Drawdown, and Win Rate.
*   **Dynamic Labeling:** Matrix headers automatically shift between "Strategy Candidate" and "Ticker Candidate" based on the active battle mode.
*   **Ranking Badges:** Distinct neon badges (#1, #2, etc.) for instant hierarchy identification.
*   **Tournament Chart:** Multi-line equity growth overlap using distinct color tokens (`STRATEGY_COLORS`).

### 2.3 Visualizer HUD (Side Panel)
*   **Rolling Horizon:** Defaults to a dynamic 6-month backtest window for real-time relevance.
*   **Quick Universe Presets:** 
    *   **`+ Include ETFs`**: Dynamic discovery of "X" series sector ETFs (XLK, XLE, etc.) while filtering out test artifacts (`XYZ`).
    *   **`Clear`**: Instant field reset for rapid universe iteration.
*   **Performance Cards:** Real-time extraction of "Top Performer," "Alpha King," and "Risk Adjusted" winners.

## 3. User Workflow
1.  **Arena Selection:** User toggles between "Strategy Comparison" or "Stock Selection" in the Battleground header.
2.  **Enlistment:** User selects strategies from the sidebar and populates the "Ticker Universe" (using ETF presets if needed).
3.  **Deployment:** User clicks "Commence Battle." The engine calculates 6-months of rolling historical data.
4.  **Auditing:** System executes batch backtests and renders the competitive matrix with performance ranking.

## 4. Design Guidelines
*   **Aesthetics:** High-contrast dark mode using `surface-container` tokens.
*   **Responsive:** Vertically scrollable metrics matrix with sticky headers and collapsible logs to maximize real estate.
*   **Interactive:** Glassmorphic transitions and hover-state highlights on tournament trajectories.
