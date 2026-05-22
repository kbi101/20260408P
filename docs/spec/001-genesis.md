The evolution of banking technology has moved from the monolithic mainframes of the 1960s to the distributed, event-driven architectures of today. For **QuantEdge Studio**, we aren't just building an app; we are building a "Quant Factory." 

To satisfy the **Antigravity IDE** and ensure high-velocity AI-assisted generation, we need a design that emphasizes **strong typing** and **decoupled logic**.

---

## 1. System Architecture Overview
The system follows a **Hexagonal Architecture** (Ports and Adapters) pattern within a monorepo. This ensures that the core quantitative logic is isolated from external data providers or UI frameworks.



### Repository Structure (Monorepo)
```text
/quantedge-studio
├── /apps
│   ├── /frontend          # React + Vite + Tailwind
│   └── /api               # FastAPI Gateway
├── /services
│   ├── /ingestor          # Data ingestion microservice
│   ├── /backtester        # Vectorized testing engine
│   └── /executor          # Low-latency execution service
├── /libs
│   ├── /quant-core        # Shared math and pattern logic
│   └── /schema            # Protobuf definitions (.proto files)
└── /docker-compose.yml
```

---

## 2. Technical Specification for IDE Ingestion

### A. Communication Layer (Protobuf)
To maximize AI code generation, we define the "Source of Truth" in `.proto` files. This allows the IDE to generate Python Pydantic models and TypeScript interfaces automatically.

```protobuf
syntax = "proto3";

message MarketData {
  string symbol = 1;
  double price = 2;
  uint64 timestamp = 3;
}

message Pattern {
  string pattern_id = 1;
  float confidence_score = 2;
  map<string, string> metadata = 3;
}
```

### B. Backend: FastAPI + Graph-Based Microservices
The backend uses a **Dependency Injection** (DI) container to manage the "Graph" of services. This makes it easy for an AI to swap a `HistoricalDataProvider` with a `LiveStreamProvider`.

* **Concurrency:** Utilizes `asyncio` for non-blocking I/O during data ingestion.
* **Vectorization:** Quantitative logic leverages `NumPy` and `Pandas` for $O(n)$ or $O(1)$ operations during backtesting.

---

## 3. Functional Module Breakdown

### I. Data Explorer (The Ingestor)
* **Sanitization Pipeline:** Implements a Z-score outlier detection to flag "dirty" market data.
* **Normalization:** Converts disparate vendor formats (JSON, CSV, FIX) into a unified internal `QuantFrame`.

### II. Research Workbench (The Brain)
* **Pattern Discovery:** Implements unsupervised learning (Clustering/PCA) to find non-obvious market regimes.
* **Definition:** Uses a Domain Specific Language (DSL) so users can define patterns as logic: 
    * *Example:* `IF (RSI < 30) AND (Volume > 2MA) THEN Pattern = "Oversold_Surge"`

### III. Backtesting & Live Execution
* **The "Shadow" Mode:** A critical banking requirement. Strategies run in a simulated environment using live data (Paper Trading) before the "Live" toggle is enabled.
* **Risk Engine:** A hard-coded circuit breaker that prevents execution if a strategy exceeds a $Var$ (Value at Risk) threshold.

---

## 4. Implementation Design (JSON Blueprint)
Copy this into your `instruction.json` for the Antigravity IDE:

```json
{
  "project": "QuantEdge Studio",
  "tech_stack": {
    "frontend": "React/Vite/TypeScript",
    "backend": "Python 3.11/FastAPI",
    "communication": "gRPC/Protobuf",
    "database": "QuestDB (Time-series) + PostgreSQL"
  },
  "ai_generation_directives": [
    "Use specification-driven development: Protobuf first.",
    "Implement vectorized backtesting logic for performance.",
    "Ensure all FastAPI endpoints have Pydantic schemas for auto-doc generation.",
    "Strict adherence to Monorepo structure with shared /libs/quant-core."
  ]
}
```

## 5. The Expert's Edge: Banking Modernization Tip
In the 1970s, we struggled with "Data Silos." Today, your greatest risk is **Data Drift**. Ensure your **Research Workbench** includes a "Consistency Monitor" that compares the historical data used for training against the live data arriving in the **Data Explorer**. If the statistical distribution shifts significantly, the system should automatically trigger a "Model Retrain" alert.

Would you like me to expand on the specific Protobuf definitions for the Pattern Recognition engine?