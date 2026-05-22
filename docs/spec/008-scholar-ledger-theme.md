# Design System Document: The Curated Archive

## 1. Overview & Creative North Star: "The Digital Curator"
This design system rejects the clinical, sterile nature of modern SaaS in favor of a "Digital Curator" aesthetic. It is inspired by the meticulous organization of 19th-century research ledgers and the tactile warmth of archival parchment. 

The goal is to move beyond a "vintage theme" into a high-end editorial experience. We achieve this through **intentional asymmetry**, **extreme typographic contrast**, and **tonal depth**. The interface should feel less like software and more like a bespoke, living document—where data is not just displayed, but "scribed."

### The Creative Pillars:
*   **Archival Structure:** A layout that feels bound and sequenced, using rigid, sharp edges to imply discipline.
*   **Typographic Authority:** Using massive scale shifts between serif headlines and functional sans-serif metadata.
*   **Tactile Atmosphere:** Replacing flat UI with "layered history" using paper textures and tonal shifts.

---

## 2. Colors: Ink & Parchment
The palette is rooted in natural, organic pigments—iron-gall ink, tanned leather, and sun-bleached paper.

### Surface Hierarchy & Nesting
We do not use drop shadows to create depth. Instead, we use **Tonal Layering**. The UI is treated as a stack of fine paper sheets.
*   **The "No-Line" Rule:** Standard 1px solid borders for sectioning are prohibited. Boundaries must be defined by background shifts. For example, a `surface-container-low` section sitting on a `surface` background creates a natural, soft boundary.
*   **The Nesting Principle:** To highlight a specific module, place a `surface-container-highest` card within a `surface-container` section. This creates "inward" depth rather than "outward" elevation.

### Signature Accents
*   **Primary Actions:** Use `primary` (#051125) for high-intent actions, mimicking the weight of fresh ink.
*   **The "Glass & Texture" Rule:** To avoid a flat "template" look, use a subtle noise texture overlay (2-3% opacity) on all `surface` levels. For floating menus, use **Glassmorphism**: a semi-transparent `surface-container-lowest` with a `backdrop-filter: blur(12px)` to allow the "parchment" color to bleed through the glass.

---

## 3. Typography: The Editorial Scale
We pair the intellectual weight of **Noto Serif** with the utilitarian precision of **Work Sans**.

*   **Display & Headlines (Noto Serif):** These are the "Titles of the Work." Use `display-lg` (3.5rem) with tight letter-spacing (-0.02em) to create a sense of authoritative legacy.
*   **Body & Data (Work Sans):** These are the "Annotations." This sans-serif provides the modern legibility required for long-form reading and data entry.
*   **Labels (Work Sans Mono/Caps):** Use `label-md` in all caps with wide letter-spacing (+0.1em) to mimic the stamped headings of a library filing system.

---

## 4. Elevation & Depth: Tonal Sophistication
Traditional Material Design shadows feel too "digital." We utilize organic elevation.

*   **The Layering Principle:** Depth is achieved by "stacking" surface-container tiers. 
    *   Base Layer: `surface` (#fff9ee)
    *   Content Sections: `surface-container-low` (#fbf3df)
    *   Interactive Cards: `surface-container-highest` (#eae2ce)
*   **Ambient Shadows:** If an element must float (like a dropdown), use a shadow tinted with `on-surface` (#1f1c0f) at 4% opacity with a 32px blur. It should look like a soft glow of light, not a black smudge.
*   **The "Ghost Border":** For essential accessibility, use `outline-variant` at 15% opacity. It should be felt, not seen—a "whisper" of a line.

---

## 5. Components: Scribed Elements

### Buttons (The "Stamp" Style)
*   **General:** All corners must be **0px (Sharp)**. This system forbids rounded corners to maintain the "bound book" aesthetic.
*   **Primary:** Background: `primary_container` (#1b263b); Text: `on_primary`. 
*   **Secondary:** No background. A `Ghost Border` (15% opacity `outline`) with `secondary` text.
*   **States:** On hover, primary buttons shift to `primary` (#051125) with a subtle horizontal "slide" transition to imply the movement of a pen.

### Inputs & Text Areas
*   **Styling:** Inputs are never boxes. They are underlined fields using `outline-variant` at 40% opacity. 
*   **Focus State:** The underline becomes `primary` and thickens to 2px, mimicking a bold underline in a diary.

### Cards & Lists
*   **Forbidden:** Horizontal divider lines.
*   **Alternative:** Use **Vertical White Space** (32px or 48px) to separate items. For lists, use a 2-tone background shift: every second item uses `surface-container-low`.

### Chips (The "Annotation")
*   Small, rectangular boxes with 0px radius. Use `secondary_container` (#f1dcc6) with `on_secondary_container` text. These should look like small slips of paper tucked into a page.

### Analytical Toolbars (Glassmorphic Scribes)
*   **Aesthetic:** For interactive analytical controls (SMA/EMA toggles, deep archival scans), use a semi-transparent glassmorphic bar.
*   **Styling:** `bg-surface-container-high/60` with `backdrop-filter: blur(12px)` and a `Ghost Border` (15% opacity `outline-variant`).
*   **Interactive Toggles:** Buttons within the toolbar should be sharp-edged (0px radius). Active states use `bg-primary` for trend overlays and `bg-tertiary` for momentum oscillators to distinguish between "Structural" and "Momentum" diagnostics.

### Multi-Pane Visualization (The Research Stack)
*   **Layout:** Secondary indicators (RSI, MACD, ADX) are rendered as recursively managed sub-panes beneath the primary price action.
*   **Hierarchy:** The primary chart occupies the "Sovereign" space (height: 400px+), while sub-panes are "Annotations" (height: 150px approx). Both share the same tonal container to imply they are part of the same archival pulse.

---

## 6. Do's and Don'ts

### Do:
*   **Embrace White Space:** Treat the screen like a premium book margin. Generous padding is the "luxury" of this system.
*   **Use Intentional Asymmetry:** Align headings to the left while pushing metadata to the far right to create an editorial layout.
*   **Layer with Texture:** Always ensure a subtle paper grain is present on `surface` backgrounds to prevent a "flat hex" feel.

### Don't:
*   **No Rounded Corners:** Never use `border-radius`. Everything is cut sharp, like hand-trimmed paper.
*   **No Vibrant Colors:** Avoid any color not found in the token set. No "digital" greens or blues; use `error` (#ba1a1a) for alerts, which mimics red archival ink.
*   **No High-Contrast Dividers:** Never use a #000 1px line. Use tonal shifts or the "Ghost Border" fallback only.

### Accessibility Note
While we use soft tonal shifts, ensure that all text (on-surface) maintains at least a 4.5:1 contrast ratio against its respective surface container. The `primary` on `surface` exceeds 10:1, providing excellent legibility for research-heavy environments.