# Event-Driven Day Trading Simulator — Design Specification

## Objective

Build a real-time day trading simulation engine that replays historical 1-minute OHLCV data from QuestDB through Apache Kafka, executes configurable quantitative strategies with risk management, and streams live portfolio updates to a React dashboard via WebSocket. The system supports multiple accounts, adjustable playback speed, and persistent trade/session history in PostgreSQL.

---

## 1. Architecture Overview

The simulator integrates five infrastructure components already present in the QuantEdge platform — QuestDB (historical data), Kafka (message bus), Redis (speed/state control), PostgreSQL (persistence), and the FastAPI API server — into a single event-driven pipeline.

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                              Simulation Pipeline                                 │
│                                                                                  │
│  QuestDB (1m OHLCV)                                                              │
│       │                                                                          │
│       ▼                                                                          │
│  ┌──────────────────────┐    ┌────────────────────────────────────┐               │
│  │  Ingestion Simulator │───▶│ Kafka: simulation-market-data-{id} │              │
│  │  (QuestDB → Kafka)   │    └────────────────┬───────────────────┘               │
│  │  Speed: Redis R/W    │                     │                                  │
│  └──────────────────────┘                     ▼                                  │
│                               ┌──────────────────────────────┐                   │
│                               │     Day Trading Engine       │                   │
│                               │  ┌─────────────────────────┐ │                   │
│                               │  │ Strategy Signal Engine   │ │                   │
│                               │  │ • MACD Crossover         │ │                   │
│                               │  │ • RSI Mean Reversion     │ │                   │
│                               │  │ • EMA 9/21 Crossover     │ │                   │
│                               │  └──────────┬──────────────┘ │                   │
│                               │             ▼                │                   │
│                               │  ┌─────────────────────────┐ │                   │
│                               │  │   Risk Manager          │ │                   │
│                               │  │ • Position Limits       │ │                   │
│                               │  │ • Stop Loss / Take Profit│ │                  │
│                               │  │ • Trade Execution       │ │                   │
│                               │  │ • P&L Tracking          │ │                   │
│                               │  └──────────┬──────────────┘ │                   │
│                               └─────────────┼────────────────┘                   │
│                                             ▼                                    │
│                               ┌─────────────────────────────────┐                │
│                               │ Kafka: simulation-updates-{id}  │                │
│                               └────────────────┬────────────────┘                │
│                                                ▼                                 │
│                               ┌─────────────────────────────┐                    │
│                               │ FastAPI WebSocket Endpoint   │                   │
│                               │ /simulator/sessions/{id}/ws  │                   │
│                               └────────────────┬────────────┘                    │
│                                                ▼                                 │
│                               ┌──────────────────────────┐                       │
│                               │ React Simulation Dashboard│                      │
│                               │ • Live P&L / Equity Curve │                      │
│                               │ • Speed Slider            │                      │
│                               │ • Trade Log               │                      │
│                               └──────────────────────────┘                       │
│                                                                                  │
│  ┌──────────────┐     ┌──────────────┐                                           │
│  │   Redis      │     │  PostgreSQL  │                                           │
│  │ Speed/State  │     │  Sessions,   │                                           │
│  │ Control      │     │  Trades, P&L │                                           │
│  └──────────────┘     └──────────────┘                                           │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Infrastructure Requirements

### Apache Kafka (KRaft Mode)

| Property | Value |
|---|---|
| **Image** | `bitnami/kafka:3.7.0` |
| **Mode** | KRaft (Zookeeper-less) — single-node controller+broker |
| **Memory** | ~500MB — no secondary container needed |
| **Internal Port** | `9092` (inter-container) |
| **External Port** | `9094` (host access) |
| **Volume** | `kafka_data:/bitnami/kafka` (persistent) |

### Dependencies

| Library | Purpose | Installed In |
|---|---|---|
| `aiokafka` | Async Kafka producer/consumer | `api.Dockerfile`, `worker.Dockerfile` |
| `redis` | Speed/state control channel | Already present |

---

## 3. Data Source: QuestDB 1-Minute Bars

The simulator reads from the existing `market_data` table in QuestDB, filtered by:

```sql
SELECT timestamp, open, high, low, close, volume
FROM market_data
WHERE symbol = '{SYMBOL}'
  AND interval = '1m'
  AND timestamp >= '{start_date}'
  AND timestamp <= '{end_date} 23:59:59'
ORDER BY timestamp ASC
```

> **Note:** 1-minute data must already be ingested for the target symbol and date range. The QuantEdge ingestion pipeline (spec 006) populates this data via yfinance.

---

## 4. Kafka Topic Design

Each simulation session creates **two ephemeral topics** scoped to the session UUID:

| Topic | Direction | Payload |
|---|---|---|
| `simulation-market-data-{session_id}` | Ingestor → Engine | OHLCV bar + index + total_bars |
| `simulation-updates-{session_id}` | RiskManager → WebSocket | Trade events, equity snapshots, metrics |

Both topics auto-create on first write. An **EOF sentinel** `{"eof": true}` signals the end of the data stream.

---

## 5. Component Design

### 5.1 Ingestion Simulator (`ingestor.py`)

Reads all 1-minute bars from QuestDB in one batch, then replays them one-by-one to Kafka with configurable throttling.

**Speed Control via Redis:**
- Reads `simulation:{session_id}:speed` before each tick sleep.
- Reads `simulation:{session_id}:state` to support PAUSE/RESUME/STOP.
- Speed values: `0` = paused, `0.1` = fast, `1.0` = real-time (1s/bar), `2.0` = slow.

### 5.2 Day Trading Engine (`engine.py`)

Consumes from the market data topic and evaluates strategy signals on each incoming bar.

**Strategies:**

| Strategy | Signal Logic |
|---|---|
| **EMA Crossover** | BUY when EMA(9) crosses above EMA(21); SELL on cross-below |
| **RSI Mean Reversion** | BUY when RSI(14) drops below 30; SELL when RSI(14) rises above 70 |
| **MACD Crossover** | BUY when MACD line crosses above Signal line; SELL on cross-below |

**Indicator Buffer:** Maintains a rolling window of up to 1,000 close prices. Signals require a minimum of 30 bars before activation.

**Risk Enforcement:** Before any strategy trade executes, the engine checks:
1. **Stop Loss**: Sell if price drops below entry by `stop_loss_pct` (default 2%).
2. **Take Profit**: Sell if price rises above entry by `take_profit_pct` (default 5%).
3. Risk limits are checked before strategy signals on each tick.

**EOF Handling:** On receiving the EOF sentinel, all remaining open positions are liquidated at last price.

### 5.3 Risk Manager (`risk_manager.py`)

Validates trades against risk parameters, executes orders, persists to PostgreSQL, and publishes update events to Kafka.

**Risk Checks:**

| Check | Rule |
|---|---|
| **Cash Sufficiency** | Order value ≤ available cash |
| **Max Position Size** | Post-trade position value ≤ `max_position_size_pct` × equity |
| **Short Sell Prevention** | Sell quantity ≤ current position |

**Trade Execution Flow:**
1. Update in-memory portfolio state (cash, position, avg entry price).
2. Write to `quant.simulation_trades` (PostgreSQL).
3. Track round-trip wins/losses for win rate computation.
4. Publish trade event to `simulation-updates-{session_id}` Kafka topic.

**Session Metrics Published (per tick):**
- `equity`, `cash`, `position`, `unrealized_pnl`
- `net_profit`, `max_drawdown`, `total_trades`, `win_rate`, `sharpe_ratio`
- Current price, timestamp, bar index, total bars

---

## 6. Database Schema

### Migration: `V9__create_simulator_tables.sql`

**`quant.simulation_accounts`** — Virtual brokerage accounts.

| Column | Type | Description |
|---|---|---|
| `account_id` | UUID (PK) | Auto-generated, seeded with default |
| `name` | TEXT | Account label |
| `balance` | DECIMAL | Current balance |
| `initial_balance` | DECIMAL | Starting balance |
| `created_at` | TIMESTAMPTZ | Creation timestamp |

**`quant.simulation_sessions`** — One row per simulation run.

| Column | Type | Description |
|---|---|---|
| `session_id` | UUID (PK) | Unique session identifier |
| `account_id` | UUID (FK) | References `simulation_accounts` |
| `symbol` | TEXT | Traded symbol |
| `strategy_name` | TEXT | Strategy used |
| `start_date` / `end_date` | TIMESTAMPTZ | Date range of historical data |
| `initial_cash` / `current_cash` | DECIMAL | Starting vs. current cash |
| `status` | TEXT | RUNNING, COMPLETED, STOPPED, FAILED |
| `total_trades` | INT | Number of trades executed |
| `win_rate` | DECIMAL | Win rate percentage |
| `net_profit` | DECIMAL | Total P&L |
| `sharpe_ratio` / `max_drawdown` | DECIMAL | Risk-adjusted metrics |

**`quant.simulation_trades`** — Individual trade records.

| Column | Type | Description |
|---|---|---|
| `trade_id` | UUID (PK) | Auto-generated |
| `session_id` | UUID (FK) | References `simulation_sessions` |
| `symbol` | TEXT | Traded symbol |
| `action` | TEXT | BUY or SELL |
| `quantity` / `price` | DECIMAL | Execution details |
| `pnl` | DECIMAL | Realized P&L (SELL trades) |
| `timestamp` | TIMESTAMPTZ | Execution time (simulation time) |
| `reason` | TEXT | Trigger reason (strategy signal, stop loss, take profit) |
| `metadata` | JSONB | Extended attributes |

**Seed Data:** A default account (`00000000-0000-0000-0000-000000000001`) is created on migration with $100,000 balance.

---

## 7. API Endpoints

All endpoints are prefixed under `/api/v1/simulator`.

| Method | Path | Description |
|---|---|---|
| `POST` | `/sessions` | Create and start a new simulation session |
| `GET` | `/sessions/{id}` | Fetch session details and current metrics |
| `POST` | `/sessions/{id}/pause` | Pause the simulation |
| `POST` | `/sessions/{id}/resume` | Resume a paused simulation |
| `POST` | `/sessions/{id}/stop` | Stop and cancel the simulation |
| `POST` | `/sessions/{id}/speed` | Adjust playback speed via Redis |
| `GET` | `/sessions/{id}/trades` | List all trades for a session |
| `GET` | `/accounts` | List all simulation accounts |
| `WebSocket` | `/sessions/{id}/ws` | Real-time stream of simulation updates |

### Session Creation Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `symbol` | string | — | QuestDB symbol (e.g. `SPY`, `AAPL`) |
| `strategy_name` | string | — | `EMA_CROSS`, `RSI_MEAN_REVERSION`, or `MACD_CROSS` |
| `start_date` / `end_date` | string | — | Historical date range (YYYY-MM-DD) |
| `initial_cash` | float | 100,000 | Starting capital |
| `speed` | float | 1.0 | Initial playback speed (seconds/bar) |
| `max_position_size_pct` | float | 1.0 | Maximum portfolio allocation (1.0 = 100%) |
| `stop_loss_pct` | float | 0.02 | Stop loss threshold (2%) |
| `take_profit_pct` | float | 0.05 | Take profit threshold (5%) |

---

## 8. Frontend Dashboard

### Layout

The simulation dashboard (`DayTradingSimulator.tsx`) provides a single-page interface with:

1. **Configuration Panel** — Symbol picker, date range, strategy selector, risk parameters, account selector.
2. **Speed Controller** — Real-time slider (Pause → 0.1x → 1x → 5x → Max) writing to Redis.
3. **Portfolio Card** — Live equity, cash, position value, unrealized P&L.
4. **Metrics Panel** — Net profit, max drawdown, total trades, win rate, Sharpe ratio.
5. **Price Chart** — Streaming candlestick/line chart with trade markers (BUY/SELL arrows).
6. **Trade Log** — Scrollable table of all executed trades with timestamps, prices, P&L, and reasons.
7. **Progress Bar** — Shows simulation progress (current bar / total bars).

### Navigation & Session Persistence

The simulator provides robust session persistence and mount-level auto-reconnection so simulations can run uninterrupted in the background.

- **Sidebar Entry:** **Day Trading Sim** (icon: `monitoring`)
- **Route:** `/simulator`

#### Back-end Execution Persistence
Once started, the ingestion and trading simulation engine runs as a detached background `asyncio` task on the FastAPI API server, persisting its execution state in PostgreSQL and caching performance speed and state variables in Redis. The simulation does not depend on the frontend dashboard remaining open; it continues running in the background until it reaches EOF (completion) or is explicitly stopped.

#### Mount-Level Auto-Reconnection Flow
When the `DayTradingSimulator` dashboard mounts, it performs an automatic reconnection handshake:
1. **URL Query Param Check:** It parses the URL for a `session_id` query parameter (e.g. `/simulator?session_id=<UUID>`). If present, it stores this in `localStorage` under `active_simulator_session_id` and connects.
2. **Backend Active Session Check:** If no query parameter exists, the client requests the API endpoint `GET /api/v1/simulator/sessions/active`. If the backend returns an active running/paused session, the frontend updates the browser URL (via `replaceState` to `/simulator?session_id=<UUID>`), updates `localStorage`, and connects.
3. **LocalStorage Cache Fallback:** If no active session is found on the backend, the client falls back to check `localStorage` for `active_simulator_session_id`. If found, it fetches the session metrics `GET /api/v1/simulator/sessions/<id>`. If the session is valid, it updates the URL via `replaceState` and connects. If the session is no longer active or is invalid, the cached ID is pruned from `localStorage`.
4. **Configuration Form Fallback:** If all checks yield no active session, the dashboard displays the simulation configuration panel to let the user configure and launch a new session.

---

## 9. Real-Time Communication

### WebSocket Protocol

The WebSocket endpoint subscribes to the Kafka `simulation-updates-{session_id}` topic and relays messages to the connected client as JSON text frames.

**Update Payload Schema:**
```json
{
  "type": "tick|trade",
  "session_id": "uuid",
  "symbol": "SPY",
  "timestamp": "2025-11-14T09:30:00Z",
  "price": 595.42,
  "equity": 100245.50,
  "cash": 50123.00,
  "position": 84,
  "unrealized_pnl": 245.50,
  "net_profit": 1250.00,
  "max_drawdown": 0.018,
  "total_trades": 6,
  "win_rate": 66.7,
  "sharpe_ratio": 1.42,
  "index": 120,
  "total_bars": 780,
  "trade": { ... }  // only for type=trade
}
```

### Speed Control Flow

```
UI Slider Change
    │
    ▼
POST /sessions/{id}/speed  { speed: 0.5 }
    │
    ▼
Redis SET simulation:{id}:speed "0.5"
    │
    ▼
Ingestor reads Redis before each tick → adjusts sleep interval immediately
```

---

## 10. Session Lifecycle

```
    ┌────────────────────────────────────────────────┐
    │                                                │
    ▼                                                │
 RUNNING ──▶ PAUSED ──▶ RUNNING ──▶ COMPLETED       │
    │           │                                    │
    │           ▼                                    │
    └────── STOPPED                                  │
    │                                                │
    └────── FAILED ──────────────────────────────────┘
```

- **RUNNING**: Ingestor publishing, Engine consuming, WebSocket streaming.
- **PAUSED**: Ingestor spin-waits on Redis; Engine blocked on Kafka (no new messages).
- **STOPPED**: asyncio task cancelled; Kafka consumers/producers cleaned up.
- **COMPLETED**: All bars replayed; open positions liquidated at EOF.
- **FAILED**: Exception in pipeline; logged to Redis + PostgreSQL.

---

## 11. Ingestion Control & Kinetic Stream Hub Integration

The day trading simulator integrates directly with the **Kinetic Stream Hub** on the **Data Explorer** page (`DataExplorer.tsx`), treating active simulation sessions as real-time ingestion pipelines.

### Pipeline Registration & Status Mapping
Active and past simulation sessions are exposed to the Data Explorer via the pipeline registry endpoint `GET /api/v1/admin/pipelines`. The FastAPI backend dynamically queries PostgreSQL and Redis to map simulation sessions into data pipelines:
- **Registry Integration:** Simulator sessions are converted into ingestion pipeline entries with an ID format of `SIM-{SYMBOL}-{session_id[:8]}`.
- **Status Mapping:** If a session's state is `RUNNING`, it is mapped to a status of `STREAMING` for the UI. Other states (`PAUSED`, `STOPPED`, `COMPLETED`, `FAILED`) are mapped to their respective raw values.
- **Dynamic Throughput:** For `STREAMING` sessions, records per second (`rec_sec`) are dynamically computed based on the playback speed stored in Redis: `rec_sec = round(1.0 / speed)`. Latency is simulated as a random jitter between 5ms and 15ms.

### Ingestion Filter Toggle
The Data Explorer dashboard provides a view toggle to prune the pipeline registry list:
- **"Streaming" (Default):** Filters the displayed pipelines to only show those currently with a status of `STREAMING`.
- **"All":** Shows all pipelines, including completed, paused, stopped, or failed simulation pipelines.
- Static mock pipelines are entirely removed from the registry, leaving only active simulator-driven ingestion pipelines.

### Dynamic Cumulative Flow Metrics
The summary stats panel dynamically aggregates the metrics of all *currently streaming* pipelines:
- **Active Streams Count:** The total number of pipelines with `STREAMING` status.
- **Global Flow Throughput:** The cumulative ingestion rate, calculated dynamically as `SUM(rec_sec)` across all streaming pipelines.

### Gaussian-based Traffic Density Map Telemetry
The Data Explorer maps real-time throughput metrics to a **Traffic Density Map** (composed of 48 temporal telemetry bars) using a Gaussian distribution function to model data load across the pipeline grid:
1. **Centering:** For each streaming pipeline index $j$, a center index in the 48-bar grid is calculated as:
   $$\text{center}_j = \left\lfloor \frac{j + 0.5}{N_{\text{streaming}}} \times 48 \right\rfloor$$
2. **Gaussian Weighting:** For each bar index $i$ ($0 \le i < 48$) and pipeline $j$, the distance is computed as $d = |i - \text{center}_j|$. The throughput contribution of the pipeline is weighted using a Gaussian curve with a fixed variance of $2.5$:
   $$w_{ij} = e^{-\frac{d^2}{2 \times 2.5}}$$
   $$\text{Contribution}_i = \sum_{j} \text{rec\_sec}_j \times w_{ij}$$
3. **Normalization & Visualization:**
   - **Height:** The height of each bar is scaled to range from 8% to 100%: $\text{height}_i = 8\% + \left( \frac{\text{Contribution}_i}{\text{Max Contribution}} \times 92\% \right)$.
   - **Opacity:** If $\text{Contribution}_i > 0.05$, the opacity scale is $0.4 + \left( \frac{\text{Contribution}_i}{\text{Max Contribution}} \times 0.6 \right)$. Otherwise, it defaults to a low idle opacity of $0.15$.
   - **Interactive Telemetry:** Hovering over a bar reveals a tooltip showing the closest active pipeline's name and its throughput (`{name} ({rec_sec} p/s)`). If no active contributions exist, it displays "Idle Telemetry".
