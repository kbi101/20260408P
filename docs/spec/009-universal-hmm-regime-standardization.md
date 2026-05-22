# Requirements Spec 009: Standardizing Universal HMM Regime Pipeline

## Objective
Standardize the institutional Hidden Markov Model (HMM) regime detection pipeline across the full platform universe to guarantee high-fidelity state telemetry, strict cross-platform execution parity between real-time API layers and background batch processing layers, and seamless client interface accessibility.

## Goals & Functional Specifications

### 1. Hardened Pipeline & Parity
- **Temporal Window Synchronization**: Unify the HMM calculation lookback horizon to exactly **126 days** (semi-annual window) across all database ingestion engines, live web inference layers, and nightly sweep routines.
- **Source Prioritization Engine**: Enforce absolute data source precedence within API evaluation layers (`regime_models.py`) by querying dedicated high-fidelity interval tables (`sp500_daily_bars`) prior to standard ingestion fallbacks, ensuring output coherence with batch historical ledgers.
- **Convergence Fallbacks**: Embed non-constrained standard Gaussian inference routines inside Baum-Welch state sequence handlers to ensure **100% convergence probability** across diverse cross-asset structures and low-variance instruments.

### 2. Universal Processing Scope
- **Constituent Sweeps**: Expand background discovery scheduling routines to natively extract and evaluate both S&P 500 benchmark indices and broader non-indexed tickers inside the centralized `quant.stock` relation.
- **Automated Deduplication**: Apply non-colliding deterministic set operators during automated universe extraction loops to guarantee clean, zero-duplication execution vectors.

### 3. Historical Telemetry Integrity
- **Continuous State Ledger**: Maintain a fully populated continuous audit trail spanning the historical lookback profile within the high-performance time-series metric matrix (`hmm_metrics` in QuestDB).
- **Matrix Ledger Archival**: Capture all 23-point transition properties, stationary emission distributions, and active forward lookahead tags for full institutional visual integration.

### 4. Client Presentation & Performance Hardening
- **Interactive Scoping Controllers**: Integrate localized client storage (`localStorage`) memory controllers within visual interface widgets (`RegimeForecastingTab.tsx`), permitting persistent selection of programmatic backtest bounds (15-day, 30-day, 90-day profiles).
- **Embedded HUD Searches**: Equip sidebar registries across both **Strategic Arsenal** script explorers and **Pattern Detection** target lists with real-time text input matching elements, instantaneously pruning lists down to targeted sub-groups.
- **Sub-Millisecond Engine Synchronization**: Re-architect database join expressions inside internal analytics compute modules (`enricher.py`) via pre-aggregation patterns to avert high-magnitude row expansion (Cross Join explosions) and insulate client components from un-dated network polling deadlocks.
