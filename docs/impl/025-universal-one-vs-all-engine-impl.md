# Implementation Specification 025: Universal "One vs. All" Alpha Engine Architecture

**Status:** IMPLEMENTATION BLUEPRINT  
**Target Core Components:** Temporal Orchestration Layer / QuestDB Storage Isolation / TimesFM Microservice Gateway  

---

## 1. Class Architecture & Interface Protocols

### 1.1 UniversalGatingEngine
The execution controller module responsible for evaluating candidate streams against unified global boundaries before dispatching target orders.

```python
class UniversalGatingEngine:
    def __init__(self, candidate_symbol: str, anchor_metric: str = 'VWAP'):
        self.symbol = candidate_symbol.upper()
        self.anchor_metric = anchor_metric
        self.db_pool = get_db_pool()
        
    async def authorize_candidate_swing(self) -> dict:
        """Executes the complete 4-Layer validation funnel."""
        # Layer 1: Verify Core Macro HMM State != State 2
        l1_state = await self._query_macro_state()
        if l1_state == 2:
            return {"authorized": False, "reason": "Systemic Macro Block (State 2)"}
            
        # Layer 2: Resolve Target Group & RS-Ratio Advance
        l2_status = await self._evaluate_vector_flow()
        if not l2_status['advancing']:
            return {"authorized": False, "reason": f"Weakening Sector Flow: {l2_status['assigned_sector']}"}
            
        # Layer 3: Query $O(1)$ TimesFM Ranking Ledger
        l3_rank = await self._query_timesfm_rank()
        if l3_rank['rank_index'] > 25: # Universal Top 5% boundary
            return {"authorized": False, "reason": f"Insufficient Universal Conviction (Rank {l3_rank['rank_index']})"}
            
        # Layer 4: Compute Local Anchor Z-Score Ignition
        l4_metrics = await self._compute_local_ignition()
        if not l4_metrics['triggered']:
            return {"authorized": False, "reason": f"Local Breakout Condition Unmet (Z={l4_metrics['z_score']:.2f})"}
            
        return {
            "authorized": True,
            "target": self.symbol,
            "metrics": {
                "macro_state": l1_state,
                "sector": l2_status['assigned_sector'],
                "universal_ev": l3_rank['expected_return'],
                "local_z": l4_metrics['z_score']
            }
        }
```

---

## 2. Temporal Orchestration Routing

To preserve processing bandwidth and prevent task queue deadlocks, the entire database caching pipeline is encapsulated inside a specialized ingestion workflow running on the CPU-intensive task queue.

### 2.1 Workflow Registration
```python
# target queue: ingestion-tasks
@workflow.defn(name="UniversalTimesFMSweepWorkflow")
class UniversalTimesFMSweepWorkflow:
    @workflow.run
    async def run(self, input_data: dict = {}) -> bool:
        # Step 1: Execute Stateful Batched Ingestion Activity
        ingested = await workflow.execute_activity(
            execute_batched_ingestion_activity,
            input_data,
            start_to_close_timeout=timedelta(hours=1),
            retry_policy=RetryPolicy(maximum_attempts=3)
        )
        
        # Step 2: Immediately Cascade into Vectorized Inference
        if ingested:
            await workflow.execute_activity(
                cascade_timesfm_inference_activity,
                input_data,
                start_to_close_timeout=timedelta(minutes=30)
            )
        return True
```

---

## 3. Database Isolation Schema Implementation

### 3.1 Parallel Relational Symbol Map (`quant.sp500_symbol`)
Executed during core repository initialization to track genuine index allocations in PostgreSQL:
```sql
CREATE TABLE IF NOT EXISTS quant.sp500_symbol (
    symbol VARCHAR(10) PRIMARY KEY,
    company_name VARCHAR(100),
    sector VARCHAR(50),
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3.2 Separate Time-Series Storage Definition (`sp500_daily_bars`)
Executed during core repository initialization to decouple global benchmark volume from targeted strategy data:
```sql
CREATE TABLE IF NOT EXISTS sp500_daily_bars (
    symbol SYMBOL capacity 1024 nocache,
    timestamp TIMESTAMP,
    open DOUBLE,
    high DOUBLE,
    low DOUBLE,
    close DOUBLE,
    volume DOUBLE
) TIMESTAMP(timestamp) PARTITION BY YEAR WAL;
```

### 3.2 Metrics Cache Table (`timesfm_metrics`)
```sql
CREATE TABLE IF NOT EXISTS timesfm_metrics (
    timestamp TIMESTAMP,
    symbol SYMBOL capacity 1024 nocache,
    expected_return DOUBLE,
    rank_index INT
) TIMESTAMP(timestamp) PARTITION BY MONTH WAL;
```

---

## 4. Resilience & Ingestion Delta Mechanics

### 4.1 Activity Implementation Hooks
```python
@activity.defn(name="execute_batched_ingestion")
async def execute_batched_ingestion_activity(config: dict) -> bool:
    symbols = await fetch_sp500_symbols_list()
    batches = [symbols[i:i + 50] for i in range(0, len(symbols), 50)]
    
    for batch in batches:
        # Check local DB coverage state to verify cold-start vs delta mode
        local_bars = query_local_bar_depth(batch[0])
        fetch_period = "5y" if local_bars < 20 else "2d"
        
        try:
            df = yf.download(batch, period=fetch_period, interval="1d", group_by="ticker", threads=True)
            # Validate complete sequence arrival
            if df.empty or df.isnull().all().all():
                raise GatewayTimeoutError("Empty sub-array download payload")
        except Exception as e:
            # Strict Gap-Prevention Resilience Hook
            await asyncio.sleep(2.0) # Exponential backoff
            df = yf.download(batch, period=fetch_period, interval="1d", group_by="ticker", threads=False)
            if df.empty:
                raise RuntimeError(f"Permanent payload omission in subset: {batch[:3]}...")
                
        # Bulk commit successful chunk inline to prevent table-lock contention
        commit_to_questdb_bulk(df, table="sp500_daily_bars")
    return True
```

---

## 5. Frontend UI Component Mapping

### 5.1 Universal Component Implementation Protocol
To map backend controller output seamlessly into the client interface, the presentation tier injects dedicated states tracking layer logic:
```tsx
// Active Interface File: apps/frontend/src/components/LiveTrading/UniversalAlphaEngineTab.tsx
export interface UniversalCandidateState {
  symbol: string;
  macroState: number;       // Layer 1 Interception Boundary
  rsSlope: string;          // Layer 2 Vector Output
  expectedReturn15d: number;// Layer 3 Global Model EV
  rankIndex: number;        // Redis Cache Sub-Query Lookup
  localZScore: number;      // Layer 4 Dynamic Output
  status: string;           // Router Gating Status String
}
```
* **Top-Level Routing Mapping**: Mapped via static state variables inside `LiveTrading.tsx` under the `'universal'` active storage token.

---
*Specification Linkage: Maps directly to Core Spec `docs/research/025-universal-one-vs-all-engine.md`*
