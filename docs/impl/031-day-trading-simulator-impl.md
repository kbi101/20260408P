# 031 Day Trading Simulator — Implementation Plan

## Status
- [x] V9 Flyway migration (DDL for `simulation_accounts`, `simulation_sessions`, `simulation_trades`)
- [x] Kafka service in `docker-compose.yml` (KRaft mode, Bitnami 3.7.0)
- [x] `aiokafka` added to `api.Dockerfile` pip install
- [x] `apps/api/research/simulator/ingestor.py` — QuestDB → Kafka ingestion loop
- [x] `apps/api/research/simulator/engine.py` — Strategy engine with MACD, RSI, EMA
- [x] `apps/api/research/simulator/risk_manager.py` — Risk checks, trade execution, Kafka updates
- [x] `apps/api/research/simulator_api.py` — REST + WebSocket endpoints
- [x] Router registration in `apps/api/main.py`
- [x] `apps/frontend/src/pages/DayTradingSimulator.tsx` — Full simulation dashboard
- [x] Sidebar + App.tsx route registration
- [ ] End-to-end pipeline verification with live data
- [ ] Historical session replay and comparison features

---

## Implementation Details

### 1. Infrastructure: Kafka in KRaft Mode
**File:** `docker-compose.yml`
- [x] Added `kafka` service using `bitnami/kafka:3.7.0`.
- [x] Configured KRaft mode (no Zookeeper):
  - `KAFKA_CFG_NODE_ID=0`
  - `KAFKA_CFG_PROCESS_ROLES=controller,broker`
  - `KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka:9093`
  - `KAFKA_KRAFT_CLUSTER_ID` auto-generated.
- [x] Listener configuration:
  - `PLAINTEXT://kafka:9092` (inter-container)
  - `EXTERNAL://localhost:9094` (host access)
- [x] Persistent volume: `kafka_data:/bitnami/kafka`.
- [x] Added `kafka` to `depends_on` for `api` service.

**File:** `api.Dockerfile`
- [x] Added `aiokafka` to the pip install command alongside existing packages.

### 2. Database Migration
**File:** `sql/postgres/migrations/V9__create_simulator_tables.sql`
- [x] Created `quant.simulation_accounts`:
  - UUID primary key, name, balance, initial_balance, created_at.
- [x] Created `quant.simulation_sessions`:
  - UUID primary key, FK to accounts, symbol, strategy, dates, cash tracking.
  - Status tracking (RUNNING/COMPLETED/STOPPED/FAILED).
  - Summary metrics: total_trades, win_rate, net_profit, sharpe_ratio, max_drawdown.
- [x] Created `quant.simulation_trades`:
  - UUID primary key, FK to sessions, symbol, action, quantity, price, pnl.
  - Reason text for trade trigger context (strategy signal, stop loss, etc.).
  - JSONB metadata column for extensibility.
- [x] Seeded default account: `00000000-0000-0000-0000-000000000001` with $100,000.

### 3. Ingestion Simulator
**File:** `apps/api/research/simulator/ingestor.py`

**Class: `IngestionSimulator`**
- [x] Constructor initializes Redis client and sets initial speed/state keys.
- [x] `fetch_data()`: Queries QuestDB HTTP API (`/exec`) for 1-minute OHLCV bars filtered by symbol, interval, and date range. Returns list of dicts.
- [x] `run()`: Main loop iterates over fetched bars:
  - Checks `simulation:{session_id}:state` from Redis — spin-waits on PAUSED, breaks on STOPPED.
  - Reads `simulation:{session_id}:speed` for dynamic throttle.
  - Publishes each bar as JSON to `simulation-market-data-{session_id}` topic.
  - Sends EOF sentinel `{"eof": true}` when all bars are published or loop breaks.
- [x] `send_eof()`: Standalone EOF publisher for empty dataset edge case.
- [x] Error handling: Sets Redis state to `FAILED` on unhandled exceptions.

### 4. Day Trading Engine
**File:** `apps/api/research/simulator/engine.py`

**Class: `DayTradingEngine`**
- [x] Consumes from `simulation-market-data-{session_id}` Kafka topic (`auto_offset_reset=earliest`).
- [x] Maintains rolling close price buffer (max 1,000 entries) + timestamps.
- [x] Technical indicator implementations:
  - `calculate_rsi(prices, period=14)`: Wilder's smoothing RSI.
  - `calculate_ema(prices, period)`: Standard exponential moving average.
  - `get_macd(prices)`: Returns (MACD line, Signal line) using EMA(12), EMA(26), Signal EMA(9).
- [x] `generate_signal(price)`: Returns BUY/SELL/HOLD based on active strategy:
  - **EMA_CROSS**: EMA(9) vs EMA(21) crossover detection.
  - **RSI_MEAN_REVERSION**: RSI crossing 30 (buy) / 70 (sell) boundaries.
  - **MACD_CROSS**: MACD line vs Signal line crossover.
  - Requires minimum 30 bars before emitting any signal.
- [x] Risk enforcement per tick (before strategy):
  - Stop loss check: Price ≤ entry × (1 − stop_loss_pct).
  - Take profit check: Price ≥ entry × (1 + take_profit_pct).
- [x] EOF handling: Liquidates remaining open positions at last price.
- [x] Capital allocation: Computes order quantity as `floor(allocation / price)` where allocation = `min(cash, equity × max_position_size_pct)`.

### 5. Risk Manager
**File:** `apps/api/research/simulator/risk_manager.py`

**Class: `RiskManager`**
- [x] In-memory portfolio tracking: cash, position, avg_entry_price, peak_value, max_drawdown.
- [x] `check_limits(action, price, quantity, max_position_size_pct)`:
  - BUY: Validates cash sufficiency + position size limit.
  - SELL: Validates quantity ≤ current position (no short selling).
- [x] `execute_trade(action, price, quantity, timestamp, reason)`:
  - Updates in-memory state (cash, position, average entry price).
  - Writes to `quant.simulation_trades` in PostgreSQL.
  - Tracks round-trip wins for win rate computation.
  - Publishes trade event to `simulation-updates-{session_id}` Kafka topic.
- [x] `update_session_metrics(current_price, timestamp)`:
  - Computes equity, unrealized P&L, max drawdown, Sharpe ratio.
  - Updates `quant.simulation_sessions` with latest metrics.
  - Publishes tick update to Kafka.
- [x] Sharpe ratio calculation: Uses equity history return series with `np.std` annualization.
- [x] Kafka producer lifecycle managed via `start()` / `stop()` methods.

### 6. Simulator API
**File:** `apps/api/research/simulator_api.py`

**Endpoints:**
- [x] `POST /sessions`: Creates session in PostgreSQL, instantiates pipeline components, spawns `asyncio.create_task(run_pipeline())`.
  - Pipeline runs `engine.run()` and `ingestor.run()` concurrently via `asyncio.gather`.
  - On completion: sets state to COMPLETED. On exception: sets FAILED.
  - Cleanup: stops Kafka producer, removes from `active_simulations` dict.
- [x] `GET /sessions/{id}`: Fetches session from PostgreSQL, overlays live Redis state.
- [x] `POST /sessions/{id}/pause`: Sets Redis state to PAUSED, updates PostgreSQL.
- [x] `POST /sessions/{id}/resume`: Sets Redis state to RUNNING, updates PostgreSQL.
- [x] `POST /sessions/{id}/stop`: Sets Redis state to STOPPED, cancels asyncio task.
- [x] `POST /sessions/{id}/speed`: Writes speed value to Redis.
- [x] `GET /sessions/{id}/trades`: Reads from `quant.simulation_trades` ordered by timestamp.
- [x] `GET /accounts`: Lists all simulation accounts.
- [x] `WebSocket /sessions/{id}/ws`: Consumes from `simulation-updates-{session_id}` Kafka topic, relays JSON messages to connected WebSocket client.

**File:** `apps/api/main.py`
- [x] Imported and included `simulator_router` with prefix `/api/v1/simulator`.

### 7. Frontend Dashboard
**File:** `apps/frontend/src/pages/DayTradingSimulator.tsx`

- [x] **Configuration Panel**: Symbol input, strategy dropdown (EMA Cross, RSI Mean Reversion, MACD Cross), date range pickers, risk parameter inputs (initial cash, max position %, stop loss %, take profit %).
- [x] **Account Selector**: Dropdown of existing simulation accounts from `/accounts` endpoint.
- [x] **Speed Controller**: Slider with labeled stops (Pause, 0.1x, 0.5x, 1x, 2x, 5x, Max) posting to `/speed` endpoint.
- [x] **Portfolio Card**: Live equity, cash, position value, unrealized P&L — updated per WebSocket tick.
- [x] **Metrics Panel**: Net profit, max drawdown, total trades, win rate, Sharpe ratio — color-coded (green=positive, red=negative).
- [x] **Price Chart Area**: Current price display with simulation time.
- [x] **Trade Log Table**: Scrollable log of executed trades with timestamp, action, quantity, price, P&L, and reason.
- [x] **Progress Bar**: Bar index / total bars with percentage completion.
- [x] **Session Controls**: Start, Pause/Resume, Stop buttons with appropriate state management.

**File:** `apps/frontend/src/components/Layout/Sidebar.tsx`
- [x] Added sidebar entry: `{ to: '/simulator', icon: 'monitoring', label: 'Day Trading Sim' }`.

**File:** `apps/frontend/src/App.tsx`
- [x] Registered route `/simulator` → `DayTradingSimulator` component.

---

## Testing & Validation

### Infrastructure Verification
- [x] Kafka container running in KRaft mode — verified via `docker compose ps`.
- [x] V9 migration applied — tables exist in `quant` schema.
- [x] Redis speed/state keys read/write working.
- [x] Session creation via `POST /sessions` returns valid UUID.
- [x] WebSocket connection established at `/sessions/{id}/ws`.

### Pipeline Verification (In Progress)
- [ ] Ingestor reads from QuestDB and publishes to Kafka topic.
- [ ] Engine consumes market data and generates strategy signals.
- [ ] Risk Manager validates and executes trades.
- [ ] WebSocket receives and relays update messages to frontend.
- [ ] End-to-end test: Start simulation → see live ticks + trades on dashboard.

### Known Issues
1. **Topic Auto-Creation Timing**: Kafka topics are not pre-created; the consumer starts before the producer publishes, causing initial "Topic not found in cluster metadata" warnings. This is a timing race — topics auto-create on first produce but the consumer polls before that happens.
2. **QuestDB 1-Minute Data Availability**: The simulator requires pre-ingested 1-minute data. For symbols/dates without data, the ingestor returns empty bars and sends immediate EOF.

---

## File Manifest

| File | Type | Description |
|---|---|---|
| `docker-compose.yml` | Modified | Added Kafka service + dependency |
| `api.Dockerfile` | Modified | Added `aiokafka` |
| `sql/postgres/migrations/V9__create_simulator_tables.sql` | New | DDL for accounts, sessions, trades |
| `apps/api/research/simulator/__init__.py` | New | Package init |
| `apps/api/research/simulator/ingestor.py` | New | QuestDB → Kafka ingestion loop |
| `apps/api/research/simulator/engine.py` | New | Strategy engine + indicator calculations |
| `apps/api/research/simulator/risk_manager.py` | New | Risk validation + trade execution + P&L |
| `apps/api/research/simulator_api.py` | New | REST + WebSocket API router |
| `apps/api/main.py` | Modified | Registered simulator router |
| `apps/frontend/src/pages/DayTradingSimulator.tsx` | New | Simulation dashboard UI |
| `apps/frontend/src/components/Layout/Sidebar.tsx` | Modified | Added nav entry |
| `apps/frontend/src/App.tsx` | Modified | Added `/simulator` route |
