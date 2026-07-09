## Stage 3 — Layout Principles (Revised v2)

### Moved Out (unchanged from prior revision)

| Item | Moved To |
| --- | --- |
| Density control mechanism, stacking/scroll interaction behavior | Interaction Principles |
| Fixed-slot reorder constraints | Component Strategy |

### Rules (Structure Layer only)

**L1. Page Type Determines Layout Skeleton**
Every screen's base layout inherits from its Page Type (Main / Detail / Add-Create / Modal-Sheet / Utility). Screen-specific layout adds to the skeleton's regions (header zone, content zone, action zone); it does not replace them.

**L2. Overlay Header as a Structural Layer**
Header and classification bar are structural overlay layers positioned so they do not permanently consume layout height from the content zone. Actual stacking behavior (z-index, scroll-linked interaction) is defined in the Interaction Layer.

**L3. Grouped vs. Flat Main Structural Variants**
Main-type screens have exactly two structural variants:

- **Grouped** (Closet, Composition): group-tile drill-down grid.
- **Flat+Filter** (Style Log, Trash): flat gallery, no drill-down.
No third structural variant without a new Page Type definition.

**L4. Three-Level Density Structure (Grouped Main only)**
Grouped Main grids support exactly 3 discrete density levels as structural states only. Numeric mapping (column counts, breakpoints) must be defined in Design Tokens, not here.

**L5. Reserved Space for Overlay Coverage**
Content zones covered by an overlay layer (header, floating button) must account for that coverage by reserving corresponding space. How that space is revealed, animated, or adjusted at runtime is Interaction Layer responsibility.

**L6. Anchored Primary Canvas / Non-Displacing Secondary Region**
Add/Create-type editing screens with a primary canvas define that canvas as a fixed structural region; the secondary supporting region is a non-displacing structural layer. Positioning behavior under scroll/drag interaction belongs to the Interaction Layer.

**L8. Standardized Detail-Type Regional Order**
Detail-type screens share a default structural order: primary media zone → primary metadata zone → cross-reference/history zone. This is the standard structure across screens; content varies within zones, and screen-specific exceptions to this default may be defined at the screen-spec level where justified.

**L9. Utility-Type List-Row Structure**
Utility-type screens use a single-column list-row structure.

### AI Constraints

- Do not define Interaction behavior (gestures, scroll dynamics, stacking/timing) in Layout.
- Do not define Component rules (slot behavior, reorder logic, internal states) in Layout.
- Do not define spacing, sizing, or numeric token values in Layout.
- Layout defines structure only — not behavior, not data rules.
