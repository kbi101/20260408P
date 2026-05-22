# Design System Strategy: The Kinetic Ledger

## 1. Overview & Creative North Star
**Creative North Star: "The Kinetic Ledger"**

This design system is engineered for the high-stakes world of quantitative research. It rejects the "empty white space" of consumer apps in favor of **Information Density with Intent**. It sits at the intersection of a Bloomberg Terminal's authoritative rigor and a modern IDE’s technical precision. 

The system moves beyond standard layouts by using **Intentional Asymmetry**. Rather than a perfectly centered grid, layouts should prioritize data flow—placing heavy-duty visualization tools in expansive "Primary Stages" while flanking them with high-density "Utility Blades." We avoid the "template" look by using tonal depth to create a sense of physical machinery; the UI should feel less like a website and more like a bespoke cockpit for financial intelligence.

## 2. Colors: Tonal Depth over Linework
The palette is rooted in a "Deep Sea" spectrum of slates and navis, designed to minimize eye strain during 12-hour research sessions.

*   **Primary Surface (`#0b1326`):** The absolute floor. Everything builds up from here.
*   **The "No-Line" Rule:** Designers are prohibited from using 1px solid borders to section off large layout areas. Boundaries must be defined by background color shifts. For example, a "Utility Blade" panel should use `surface_container_low` against the `surface` background. The transition itself creates the "line."
*   **Surface Hierarchy & Nesting:** Treat the UI as a series of physical layers. 
    *   **Level 0 (Background):** `surface`
    *   **Level 1 (Main Content Area):** `surface_container_low`
    *   **Level 2 (Active Cards/Modules):** `surface_container_high`
    *   **Level 3 (Floating Tooltips/Modals):** `surface_container_highest` with 12px Backdrop Blur.
*   **The "Glass & Gradient" Rule:** To signify interactive potency, use a subtle linear gradient on primary CTAs transitioning from `primary` (`#7bd0ff`) to `on_primary_container` (`#008abb`). This provides a "liquid crystal" depth that feels high-end.

## 3. Typography: The Engineering Aesthetic
The typography system balances the geometric modernism of **Space Grotesk** with the neutral, high-legibility of **Inter**.

*   **Display & Headlines (Space Grotesk):** Used for "Hard Data" headers and status titles. Its wide apertures and technical look convey authority and innovation.
*   **Body & Labels (Inter):** Used for all qualitative descriptions. 
*   **The Quantitative Override:** For all numerical data, price points, and code blocks, use a high-legibility monospace font (e.g., JetBrains Mono or SF Mono) set to `label-md`. Data should always be tabularized (monospaced) to ensure that digits align vertically for instant comparison across rows.
*   **Hierarchy via Weight:** In high-density views, use `on_surface_variant` (`#c6c6cd`) for secondary metadata to de-emphasize it, reserving `on_surface` (`#dae2fd`) for primary figures.

## 4. Elevation & Depth: Tonal Layering
In this system, depth is a function of light, not lines.

*   **The Layering Principle:** Stacking `surface_container` tiers creates a natural lift. A card using `surface_container_highest` placed on a `surface_container_low` background creates enough contrast that shadows are often unnecessary.
*   **Ambient Shadows:** For floating elements (modals or pop-overs), use an extra-diffused shadow: `box-shadow: 0 12px 40px rgba(0, 0, 0, 0.4)`. The shadow must never be pure black; it should be a deep navy tint to maintain the "Deep Sea" aesthetic.
*   **The "Ghost Border" Fallback:** If a container requires a border (e.g., an input field), use the `outline_variant` (`#45464d`) at **20% opacity**. It should be a suggestion of a container, not a cage.
*   **Tactile Feedback:** Interactive elements should use a `0.25rem` (DEFAULT) roundedness for a "milled" look—sharp enough to feel professional, but soft enough to feel premium.

## 5. Components

### Buttons
*   **Primary:** High-contrast `primary` background. Use `on_primary_fixed` for text. No border.
*   **Secondary:** `surface_container_highest` background with a `ghost border` fallback.
*   **Tertiary (Emerald/Ruby/Amber):** Reserve these strictly for status-driven actions (e.g., "Execute Buy" uses `tertiary`, "Terminate Session" uses `error`).

### Data Modules (Cards)
*   **Rule:** Forbid divider lines within cards.
*   **Separation:** Use `8px` or `16px` of vertical whitespace. If sub-sections are needed, use a `surface_bright` sub-header background to group content.

### Input Fields
*   **State:** Default state uses `surface_container_highest`. Focus state triggers a 1px `primary` border and a subtle `primary` outer glow (4px blur, 10% opacity).
*   **Typography:** All user input should be rendered in Monospace to ensure character-perfect precision.

### The "Pulse" Indicator (Custom Component)
For real-time data streams, use a 4px circular dot using `tertiary` (`#4edea3`) with a CSS "ripple" animation. This provides a tactile sense of "liveness" without requiring heavy UI updates.

### High-Density Lists
*   **Hover State:** Row background shifts to `surface_container_highest`. 
*   **Spacing:** Use `sm` (0.125rem) or `none` roundedness for list items to allow them to "stack" like a continuous ledger.

## 6. Do's and Don'ts

### Do:
*   **Align to the Pixel:** In a "Modern IDE" aesthetic, misalignment is a failure. Use a strict 4px grid.
*   **Use Color Sparingly:** 90% of the UI should be slates and navis. The vibrant accents (`tertiary`, `error`, `amber`) should only appear where data changes or attention is required.
*   **Embrace Density:** It is okay to have 50+ data points on screen if they are grouped logically via surface shifts.

### Don't:
*   **Don't use 100% Opaque Borders:** This creates "visual noise" that fatigues the researcher.
*   **Don't use Standard Drop Shadows:** They feel "web-like" and cheap. Stick to tonal layering.
*   **Don't use Inter for Numbers:** Proportional fonts make data tables look jagged. Always use Monospace for digits.
*   **Don't use Large Radius Corners:** Stay within the `sm` to `md` range. Large `xl` or `full` roundedness feels too "consumer" and soft for a high-performance studio.