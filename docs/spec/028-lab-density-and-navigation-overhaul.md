# Research & Volatility Lab Density Overhaul

## Objective
Enhance analytical throughput and institutional auditing speed by optimizing interface density, expanding temporal context, and streamlining cross-lab navigation.

## Key Enhancements

### 1. Volatility Lab: High-Density GEX Profiling
*   **Structural Grid**: Transitioned from vertical stacking to a side-by-side `lg:grid-cols-2` layout for the Gamma Exposure Matrix and Temporal Settlement Ladder.
*   **Vertical Compression**:
    *   Reduced header padding from `py-6` to `py-3`.
    *   Slashed panel margins (`mb-12` -> `mb-6`) and global container spacing.
    *   Locked GEX plot aspect ratio to `21:9` for maximum "above the fold" visibility.
*   **Temporal Expansion**: Updated the backend `enricher.py` to increase the Max Pain/GEX lookahead from 3 to **6 expirations**, doubling the forward-dated settlement context.

### 2. Research Lab: Streamlined Pattern Auditing
*   **Navigation Pivot**: Replaced the legacy side-panel symbol registry with a high-density searchable dropdown in the top command bar.
*   **Intelligence Integration**: 
    *   Added a "Deep Dive" trigger for the modeless `TargetSnapshot` dialog.
    *   Allows analysts to audit institutional fundamentals and pattern logic without leaving the research context.
*   **Decommissioning**: Removed the "Observe Archetypes" entry point to reduce UI clutter and focus on real-time signal detection.

### 3. Application Architecture: Collapsible Navigation
*   **Dynamic Sidebar**: Implemented a collapsible main sidebar with persistent state memory (`localStorage`).
*   **Adaptive UI**: Navigation morphs between a full descriptive menu and an ultra-lean icon-only dashboard to maximize charting real estate across all lab environments.

## Technical Implementation Notes
*   **State Persistence**: Standardized the use of `localStorage` for symbol focus and UI state to ensure institutional research continuity across sessions.
*   **Backend Scaling**: Increased query `LIMIT` in `calculate_max_pain` to surface additional temporal settlement data.
*   **Type Safety**: Hardened the sidebar navigation with a unified `NavItem` interface to support optional styling and dynamic icons.
