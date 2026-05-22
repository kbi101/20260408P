# 026 - Investment Targets Metadata Hydration

## 1. Overview
This document specifies the updates made to the Investment Targets module, aimed at enriching the target registry with high-fidelity asset metadata (company name, valuation, and supply).

## 2. Schema Enhancements
The `quant.stock` table in PostgreSQL has been expanded to include:
- `name` (VARCHAR): The official company or fund name.

## 3. API & Ingestion Logic
- **`InvestmentTarget` Pydantic Model**: Upgraded to handle the `name` field.
- **YFinance Enrichment**: 
  - The `/api/v1/targets` POST endpoint now extracts `shortName` or `longName` during standard ingestion and saves it to the database.
  - Market Valuation (`marketCap`) and Supply (`sharesOutstanding`) are automatically backfilled via `yfinance` API scripts for all previously registered assets.

## 4. UI Rendering
The frontend "Investment Targets" cards and detailed modals now intelligently substitute the raw ticker symbol with the fully-qualified company name for maximum readability.
- **Deduplicated Headers**: The ticker symbol is retained strictly in the card icon box, while the primary header proudly displays the full asset name (e.g., "Apple Inc." instead of "AAPL").
- **Financial Formatting**: 
  - **Market Cap**: Divided by 1,000,000,000 and displayed with a `B` suffix (e.g., `$3300.00B`).
  - **Supply**: Divided by 1,000,000 and displayed with an `M` suffix (e.g., `14687.36M`).
- **Graceful Fallback**: If the company name is unavailable or pending fetch, the UI seamlessly falls back to displaying the ticker symbol to maintain structural integrity.
