# 004 - Infrastructure Microservice & Persistent Tier Management

## 1. Overview
This document defines the architecture for QuantEdge Studio's persistent layer and infrastructure monitoring. The system has evolved from a single PostgreSQL instance to a specialized dual-database tier to handle both application metadata and high-frequency time-series market data.

## 2. Infrastructure Microservice
- **Path**: `services/infra/main.py`
- **Responsibility**:
    - **Operational Oracle**: Serves as the source of truth for all registered containers and services.
    - **Telemetry Engine**: Discovers live metrics from database engines (storage footprint, active connections).
    - **Persistence management**: Directly manages the `quant.infra_registry` table.
- **Backend Tech**: FastAPI, Uvicorn, Psycopg (v3+).

## 3. Multi-Database & Orchestration Strategy
The Studio utilizes specialized data storage and coordination engines managed as a unified infrastructure fleet.

### 3.1 PostgreSQL Engine (System Tier)
- **Role**: Registry, system metadata, configuration, strategy configurations, and state coordination.
- **Database**: `crystal_db`
- **Schema**: `quant`
- **Telemetry Discovered**: Finalized paths for Homebrew (`/opt/homebrew/var/postgresql@17`), live DB size, and connection saturated monitoring.

### 3.2 QuestDB Engine (Market Tier)
- **Role**: High-speed ingestion of market ticks and time-series analytics.
- **Interface**: PostgreSQL-wire protocol (Port 8812) and Web Console (Port 9000).
- **Optimization**: Daily partitioning, SYMBOL-based metadata compression, and WAL-enabled tables.

### 3.3 Redis Cache & KV Store (Ingestion Tier)
- **Role**: Distributed caching, real-time message stream queueing, and key-value store.
- **Interface**: TCP Port 6379, standard DB indices.

### 3.4 Temporal Orchestrator (Workflows Tier)
- **Role**: High-reliability stateful workflow orchestration and daily settlement discovery execution queue.
- **Interface**: gRPC endpoint (Port 7233) and Web UI Console (Port 3104).

### 3.5 DuckDB Engine (OLAP Analytics Tier)
- **Role**: Embedded, in-process columnar database for high-speed options audits, options gravity, and GEX volatility profile modeling.
- **Database File**: `db/options_analytics.db`
- **Optimization**: In-process vectorized analytic execution directly inside the Volatility Lab API.

### 3.6 Kafka Message Hub (Event-Driven Streaming Tier)
- **Role**: Real-time event log, day trading strategy signal broker, and telemetry stream pipeline.
- **Interface**: TCP Port 9092 (Internal cluster communication), TCP Port 9094 (External host access).
- **Optimization**: KRaft (Zookeeper-less) controller and broker process co-located on a single metadata log.

## 4. Extensible Infrastructure Registry
All infrastructure components are registered in the `quant.infra_registry` table to enable dynamic UI rendering and operational management.

### Schema Expansion
- **`config` (JSONB)**: Includes `web_console` URL for one-click access to dashboards, namespacing configs, and database connection details.
- **`metadata` (JSONB)**: Added custom context keys like `notes`, `installation`, and `logs`.

### Supported Providers
- PostgreSQL (`postgres`), Redis (`redis`), QuestDB (`questdb`), Temporal (`temporal`), DuckDB (`duckdb`), Kafka (`kafka`), and Generic Docker containers (`docker`).

### UI Layout & Grid Tiers
- **Core Infrastructure (Tier 1)**: Elevates all Databases, Caches, and Orchestrators to premium, highly detailed cards. Rendered in a **compact responsive dual-column grid (`grid-cols-1 xl:grid-cols-2 gap-6`)** to maximize screen real estate and HUD density.
- **Adaptive Column Spans**: Inside Tier-1 cards, the interior uses a highly responsive grid layout (`grid-cols-1 md:grid-cols-3 xl:grid-cols-2 2xl:grid-cols-3`) that dynamically stretches the Performance Snapshot across the bottom row (`xl:col-span-2 2xl:col-span-1`) on dual-column card displays.
- **Operational Components (Tier 2)**: Statically rendered in a high-density 3-column grid (`grid-cols-1 md:grid-cols-2 xl:grid-cols-3`) for compute services, generic docker nodes, and background compute tasks.

## 5. Schema Migration & Versioning (Flyway)
The Studio uses namespaced Flyway migrations to maintain independent schema lifecycles.

### Directory Structure
- `sql/postgres/migrations/`: Definitions for the App Registry and coordination tables.
- `sql/questdb/migrations/`: Definitions for market data tables (e.g., `market_ticks`).

### Versioning Requirements
- **PostgreSQL**: Standard Flyway v10+ compatibility.
- **QuestDB**: Requires **Flyway v12+** to handle QuestDB-specific metadata query semantics and avoid `EXISTS(CURSOR)` incompatibilities.

## 6. Real-World Discovery (Ground Truth)
Infrastructure is no longer mocked. The `infra` service performs a "Live Audit" of the local machine to discover:
- Actual Homebrew installation paths.
- Active process IDs for path resolution.
- Dynamic storage metrics queried directly from the local filesystem and engine catalogs.
