# 020-IMPL: Strategy Tournament Engineering Specification

## Architecture Overview
The Strategy Tournament engine utilizes a batch-processing pattern to execute multiple independent backtests in a single logical transaction. It leverages the existing single-strategy runner by wrapping it in a coordination loop.

## 1. Backend Engine (`api/research/backtest_engine.py`)

### 1.1 Data Models
*   **`BatchBacktestRequest`**: Includes a `mode` field (`strategy-tournament` | `stock-battleground`).
*   **`PortfolioBacktestRequest`**: Reused for sub-task execution.

### 1.2 `run_batch_backtest` Logic
*   **Mode-Aware Routing**:
    *   **Strategy Tournament**: Iterates through `strategies`, executing each against the full symbol list.
    *   **Stock Battleground**: Iterates through `symbols`, executing the primary strategy against each ticker individually. The response object is re-labeled with `res["strategy"] = symbol` to support unified UI rendering.
*   **Resilience Pattern:** Uses a `try-except` block per sub-task.

## 2. Frontend Implementation (`frontend/src/components/Research/StrategyBrowser.tsx`)

### 2.1 State Management
*   **`battleMode`**: State hook (`'strategy'` | `'stock'`) controlling the API request payload and UI labeling.
*   **`startDate`**: Rolling horizon initialized via `new Date().setMonth(d.getMonth() - 6)`.
*   **`isLogsCollapsed`**: Stateful boolean for height transitions in `ResearchLab.tsx`.

### 2.2 Data Visualization & Logic
*   **Dynamic Universe Discovery**: The `+ Include ETFs` action maps the `targets` prop, filtering for `symbol.startsWith('X')` while excluding `XYZ`.
*   **Legend & Matrix Sync**: Both components utilize a `[...results].sort()` pattern to ensure performance-based ranking is consistent across the trajectories and the table.
*   **Contextual HUD**: The "Run Simulation" button is conditionally hidden in battleground mode to ensure "Commence Battle" remains the primary CTA.

## 3. Deployment & Scalability
*   **Parallelism:** Future optimization involves migrating the batch loop to `asyncio.gather` with a semaphore to control QuestDB connection pool saturation.
*   **Persistence:** Tournament results are cleared on new simulation initiation to ensure visual data integrity.
