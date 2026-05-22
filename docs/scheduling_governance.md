# Scheduling & Queue Governance: QuantEdge Studio

## 📋 Protocol Overview
To prevent "deadlocks," "ghost workflows," and "task queue mismatches," all developers and agentic services must adhere to the following orchestration standards. Failure to follow these rules will result in Temporal workflows being scheduled on queues with no registered workers, leading to permanent "Running" (stuck) states.

---

## 1. Task Queue Partitioning
QuantEdge Studio uses a **Dual-Queue Architecture** for load balancing and resource isolation.

| Workflow Type | Keyword | Target Task Queue | Purpose |
| :--- | :--- | :--- | :--- |
| **Market Data** | `Ingestion*`, `Scan*` | `ingestion-tasks` | CPU-intensive OHLC collection and analysis. |
| **Options Analytics** | `Options*` | `options-tasks` | Memory-intensive Black-Scholes and GEX enrichment. |

### 🚨 Routing Rule
When triggering a workflow via API or Script, always use the following logic:
```python
task_queue = "options-tasks" if "Options" in workflow_name else "ingestion-tasks"
```

---

## 2. Schedule Naming & Convergence
Avoid duplicate schedules. New schedules should be verified against the `baseline` in `apps/api/main.py`.

### Current Standardized Schedules
| ID | Workflow | Frequency | Time (CST) |
| :--- | :--- | :--- | :--- |
| `ingestion-weekly-1w` | `IngestionOrchestrator` | Weekly | Sat 5:00 AM |
| `ingestion-daily-1d` | `IngestionOrchestrator` | Daily (M-F) | 9:00 PM |
| `ingestion-daily-1m` | `IngestionOrchestrator` | Daily (M-F) | 10:00 PM |
| `pattern-scan-daily` | `DailyPatternScanWorkflow` | Daily (M-F) | 11:00 PM |
| `options-snapshot-close`| `OptionsCollectionWorkflow` | Daily (M-F) | 3:15 PM |
| `discovery-preview-sweep`| `NightlyDiscoveryWorkflow` | Daily (M-F) | 4:15 PM |
| `options-settlement-oi` | `OptionsCollectionWorkflow` | Daily (M-F) | 7:30 AM |
| `discovery-settlement-sweep`| `NightlyDiscoveryWorkflow` | Daily (M-F) | 7:35 AM |
| `options-enrichment-daily`| `OptionsEnrichmentWorkflow` | Daily (M-F) | 7:45 AM |

---

## 3. Workflow Implementation Standards
### 3.1 Signature Resilience
Every `run()` method in a Workflow must accept an optional `input_data` dictionary to prevent `TypeError` when triggered by the Temporal Scheduler with default arguments `{}`.

**Correct:**
```python
@workflow.run
async def run(self, input_data: dict = {}) -> bool:
    ...
```

### 3.2 Time Travel & Backfills
The `OptionsEnrichmentWorkflow` must support a `date` key in the input dictionary to allow for manual re-enrichment of historical dates.

---

## 4. Troubleshooting & Auditing
If the Volatility Lab is missing data or tasks appear stuck:

1.  **Audit Schedules**: Verify queues are correct.
    ```bash
    python3 scripts/audit_schedules.py
    ```
2.  **Audit Workflows**: Check for "Running" ghost workflows.
    ```bash
    python3 scripts/audit_temporal.py
    ```
3.  **Clean Slate**: Terminate stuck workflows and restart workers.
    ```bash
    python3 scripts/cleanup_workflows.py
    docker restart quantedge-worker
    ```

---
*Document Version: 1.1.0*
*Last Updated: 2026-04-15*
