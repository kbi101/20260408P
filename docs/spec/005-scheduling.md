
## Feature Specification: Independent Dynamic Ingestion Engine (v2.0)

**Status:** Final Design | **Architecture:** Decoupled Microservice | **Orchestration:** [Temporal.io](file:///Users/kepingbi/20260408/docs/scheduling_governance.md)
> [!IMPORTANT]
> All modifications to schedules and task queues must comply with the [Scheduling & Queue Governance](file:///Users/kepingbi/20260408/docs/scheduling_governance.md) protocol.


### 1. Architectural Mandate: "Isolation by Design"
The Ingestion Engine shall exist as a standalone Docker container (`quantedge-worker`). It must remain decoupled from the `quantedge-api` and `quantedge-ui` to ensure that data collection persists regardless of the state of the management interfaces.

---

### 2. Functional Requirements

#### 2.1 Decoupled Task Execution
* **Independent Runtime:** The worker container shall maintain its own Python environment, allowing it to scale CPU/RAM resources independently of the API.
* **Stateless Operation:** Workers do not store script files. They must pull the "Task Payload" (code + parameters) from the central State Store at the moment of execution.
* **Sandbox importlib:** Use a dedicated class loader to execute `yfinance` logic in a clean namespace, preventing global variable leakage between different ingestion tasks.

#### 2.2 Resilient Scheduling & Retries
* **Temporal-Driven Workflows:** Use Temporal.io to manage the "State Machine" of each ingestion. If a Docker container restarts mid-task, Temporal must re-assign the task to a new container.
* **Smart Backoff:** Specific handling for `yfinance` rate limits (HTTP 429). The engine must pause the specific task while allowing other non-yfinance tasks to proceed.

#### 2.3 Persistent "Black Box" Observability
* **Log Sink (Redis Streams):** Workers must pipe all `stdout/stderr` to a Redis Stream indexed by `run_id`.
* **UI-Independent Buffering:** Logs must accumulate in Redis even if no UI client is connected. 
* **Log Replay API:** The Backend must provide a "Replay" endpoint that fetches the last $N$ lines from Redis to sync the UI when it comes back online.

---

### 3. Technical Implementation Details

#### 3.1 The Docker Environment
The worker shall be built on `python:3.11-slim` with the following key components:
* **Entrypoint:** A Temporal worker process listening on the `ingestion` task queue.
* **Volumes:** Read-only access to `/libs/quant-core` to ensure shared math/logic is available without duplication.
* **Healthchecks:** A GRPC health probe to ensure the worker is connected to the Temporal cluster.

#### 3.2 Sequence of Operations (The "Hot-Load" Cycle)
1. **Trigger:** Temporal Cluster signals the independent Docker Worker.
2. **Fetch:** Worker queries the API/DB for the latest version of the `yfinance_ingest.py` script.
3. **Execute:** The script is loaded into memory via `importlib.util`.
4. **Pipe:** Logs are sent to **Redis**; Data is sent to **QuestDB**.
5. **Finalize:** Upon completion, the Worker signals "Success" to Temporal and closes the log stream.

---

### 4. UI Component Updates (The "Observer")
The Studio UI must implement the following logic to handle the independent nature of the engine:

| UI Feature | Behavior |
| :--- | :--- |
| **Sync Status** | Indicator showing if the UI is "Live" or "Catching up" with the Worker logs. |
| **Execution History** | A searchable list of past Docker runs, allowing users to view logs of tasks that ran while the computer was off. |
| **Remote Kill Switch** | A command sent from UI $\rightarrow$ API $\rightarrow$ Temporal to terminate a specific Dockerized task thread. |

---

### 5. Antigravity IDE Prompt (Finalized for "Independent Engine")

> "Generate a standalone Dockerized service for QuantEdge Studio. The service must act as a Temporal.io worker. Implement a dynamic module loader that fetches Python code from a PostgreSQL database via an internal API. All logging within the dynamic module must be redirected to a Redis Stream to allow for persistent observability and UI log-replay. Ensure the `yfinance` library is pre-installed in the Docker image. Follow the 'Independent Engine' feature spec for error handling and retries."
---
6. Infrastructure Implementation Log (Session 2026-04-08)

### 6.1 Orchestration Infrastructure
* **Orchestrator:** Successfully deployed `temporalio/auto-setup:1.24.3`.
* **Database Mapping:** Integrated with `crystal_db` (Postgres) using isolated schemas:
    * `temporal`: Execution and shard state.
    * `temporal_visibility`: Workflow search and visibility tracking.
* **Driver Configuration:** Standardized on `postgres12` driver with `BIND_ON_IP=0.0.0.0` for container-to-container connectivity.

### 6.2 Observability & Management
* **Web Management:** Temporal UI deployed on port **3104**, proxying to the internal `temporal:7233` gRPC endpoint.
* **Routing Fix:** Implemented custom Nginx fallback in `frontend.Dockerfile` to support SPA deep-linking (e.g., `/containers` and `/explorer`).
* **Connection Logic:** Fixed Python backend connection persistence using `options='-c search_path=quant'` to maintain schema isolation while allowing cross-schema Temporal access.

### 6.3 State of Registry
* **Namespace Registry:** `default` namespace successfully initialized and cached.
* **Infrastructure HUD:** Registry verified as "Online" for the Orchestration tier.
