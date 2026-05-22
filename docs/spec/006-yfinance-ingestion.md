# Guide 006: High-Performance yFinance Ingestion & Migration

This document outlines the architecture and implementation of the historical data ingestion and backfill pipeline using yFinance, QuestDB, and Temporal.

## 1. Summary of Work (2026-04-10)

We have refactored the ingestion pipeline from a simple forward-only fetcher to a robust, bi-directional backfilling engine.

### Key Achievements:
- **Bi-Directional Gap Filling**: Implemented a "Dual-Pass" state check that identifies both historical gaps (pre-existing data) and forward gaps (catch-up data).
- **Deep Historical Hydration**: Established default ingestion horizons: **2 Years** (Daily), **5 Years** (Weekly), and **7 Days** (1-Minute).
- **Automated Target Boarding**: New investment targets now trigger an immediate multi-resolution ingestion workflow upon registry addition.
- **Manual Deep Refresh**: Integrated a "Refresh Data" API and UI capability for on-demand historical population.

## 2. Technical Architecture

### Database Schema (QuestDB)
The `market_data` table uses Write-Ahead Logging (WAL) and Deduplication to ensure ledger integrity during high-frequency backfills.

```sql
CREATE TABLE market_data (
    symbol SYMBOL,
    timestamp TIMESTAMP,
    open DOUBLE, high DOUBLE, low DOUBLE, close DOUBLE, volume DOUBLE,
    interval SYMBOL,
    session SYMBOL,
    provider SYMBOL
) timestamp(timestamp) PARTITION BY YEAR WAL DEDUP UPSERT KEYS(timestamp, symbol, interval);
```

### Ingestion Logic: Bi-Directional "Dual-Pass"
The ingestion activity (`ingest_market_data`) follows this protocol:
1. **Historical Pass**: Query `min(timestamp)` and `max(timestamp)` for the symbol/interval in QuestDB.
2. **Gap 1 (History)**: If `min(timestamp)` is later than the requested historical start (e.g., 2 years ago), trigger a **Historical Backfill** for the missing "pre-history" window.
3. **Gap 2 (Forward)**: If `max(timestamp)` is earlier than today, trigger a **Catch-up Infill** for the most recent activity.
4. **Stitching**: yFinance data is stitched together and streamed to QuestDB. QuestDB's `DEDUP UPSERT` logic handles overlaps automatically, ensuring no duplicate bars are stored.

## 3. Operations & Triggers

### Automated Boarding
When a symbol is added to the PostgreSQL registry, the API triggers three concurrent Temporal workflows:
*   `refresh-<SYMBOL>-1m`
*   `refresh-<SYMBOL>-1d`
*   `refresh-<SYMBOL>-1w`

### Manual Overwrite/Refresh
The `/api/v1/ingestion/refresh/{symbol}` endpoint enables a full-force historical audit. This bypasses normal smart-fill constraints to ensure the ledger matches the requested deep-history horizons.
