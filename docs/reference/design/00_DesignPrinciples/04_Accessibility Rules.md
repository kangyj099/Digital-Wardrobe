## Stage 4 — Accessibility Rules

### 1. Definition

Minimum accessibility standards applied to this app's specific surfaces (gesture-driven Composition Editor, image-heavy galleries, dark mode, tag/color-based classification). Compared per-item across KRDS, Apple HIG, and WCAG; each rule states its adopted source.

### 2. Rules

**A1. Minimum Touch Target Size**

- HIG: 44×44pt / KRDS: similar minimum touch area recommendation
- **Adopted: HIG (44×44pt)** — roughly equivalent, HIG provides a more specific value
- WCAG not needed (both sources address this)

**A2. Color Must Not Be the Sole Carrier of Information**

- Color-only classifiers (Closet color filter, tag badges) must always pair with text/icon/pattern
- Neither KRDS nor HIG specifies this → **WCAG adopted** (1.4.1 Use of Color)

**A3. Contrast Ratio (including Dark Mode)**

- Minimum contrast for text/background required (must not conflict with 기획03's "avoid black/white, sophisticated tone" principle)
- Sources differ in specificity → **WCAG adopted** (4.5:1 normal text / 3:1 large text, applies equally in dark mode)

**A4. Alternative to Gesture-Only Actions (Composition Editor)**

- Move/rotate/resize/z-index all rely on drag/pinch gestures (기획03)
- HIG: recommends single-tap alternatives for complex gestures / KRDS: similar principle, less specific
- **Adopted: HIG** — more concrete guidance
- Result: each gesture-driven action must have at least one non-gesture alternative (e.g., button/menu)

**A5. Dynamic Type / Text Scaling Support**

- HIG: Dynamic Type support, layout reflow required / KRDS: similar level
- **Adopted: HIG** (more specific layout-adaptation criteria)

**A6. Screen Reader Semantic Structure (Image-Heavy Galleries)**

- Clothing/Composition/Style Log thumbnails need meaningful accessibility labels (e.g., "T-shirt, blue, worn 12 times")
- Both sources general only → **WCAG adopted** (1.1.1 Non-text Content, 4.1.2 Name/Role/Value)

**A7. Reduced Motion Option**

- Must respect system-level "reduce motion" setting (transitions, drag feedback animation, etc.)
- HIG: concrete system-setting integration guidance / KRDS: similar but less specific
- **Adopted: HIG**

**A8. Focus Order and Visibility**

- Logical navigation order required (header dropdown, back navigation, gallery grid, etc.)
- Both sources general only → **WCAG adopted** (2.4.3 Focus Order, 2.4.7 Focus Visible)

**A9. Accessibility Announcement for AI Processing Failure/Retry States**

- The existing I7 (AI processing interaction contract) popup/retry states must be equally conveyed to screen readers
- Not a new concept — adds an accessibility requirement onto existing I7 (no redefinition)
- Both sources silent → **WCAG adopted** (4.1.3 Status Messages)

**A10. Hit Area vs. Visual Size**

- Elements with visual size below the A1 minimum (density-toggle icon, delete X button in Composition Editor, overlap-selection popup items, etc.) must have their hit area expanded to the minimum independently of visual size — preserves visual density (e.g., L4's 4×4 max density) without sacrificing accessibility
- **Adopted: HIG** (same family as A1, consistent with existing adoption priority)

**A11. Gesture Conflict Rule**

- Per I1 (fixed gesture meaning), where multiple gestures (drag/pinch/long-press/rotate in Composition Editor) share overlapping hit areas, each conflicting gesture pair must define a priority or a clear trigger condition (e.g., rotation recognized only after a long-press) — this reinforces I1 for multi-gesture coexistence, not a redefinition
- **Adopted: WCAG (reference)** (analogous to 2.5.4 — prevention of accidental actuation)

**A12. Image Density Accessibility**

- Even at L4's maximum density (4×4), each tile must retain the same A6 (screen reader label) and A10 (hit area) coverage — increased density must not reduce accessible information or touch accuracy; density remains a purely visual-structure concern
- **Adopted: WCAG (reference)** (general principle, applied to this project's specifics)

**A13. State Accessibility Coverage**

- All visually-only state indicators (incomplete badge, trash "N days" label, broken-link badge, I4's grayed-out disabled treatment, etc.) must provide text equivalents to assistive technology, following the same principle as A9 — generalizes A9 from AI-processing states to all badge/state indicators
- **Adopted: WCAG (reference)** (extension of 4.1.2, 4.1.3)

### 3. Guideline Adoption Tally (for future conflict resolution)

| Source | Adoption Count |
| --- | --- |
| HIG | 5 (A1, A4, A5, A7, A10) |
| KRDS | 0 |
| WCAG (supplementary track, excluded from tally per original principle) | 8 (A2, A3, A6, A8, A9, A11, A12, A13) |

→ **HIG is the default adopted guideline** for any future direct-conflict item (HIG outnumbers KRDS among non-conflicting, directly-compared items).

### 4. Real UI Behavior Examples

| Scenario | Rule | Behavior |
| --- | --- | --- |
| Color-based classification tab | A2 | Color swatch paired with color-name text |
| Rotating an item in Composition Editor | A4 | Non-drag alternative (angle input/button) provided alongside drag rotation |
| Tag badge in dark mode | A3 | Maintains ≥4.5:1 contrast against background |
| Screen reader navigating Closet grid | A6 | Each tile exposes type/color/wear-count summary as an accessibility label |
| AI tagging fails 3 times, popup appears | A9 | Status change is announced to screen readers without stealing focus |
| Tapping the small density-toggle icon | A10 | Hit area meets minimum size even though visual icon is smaller |
| Long-press then rotate in Composition Editor | A11 | Rotation gesture only activates after long-press trigger, preventing conflict with drag |
| Max-density (4×4) gallery view | A12 | Labels and hit areas remain intact despite smaller visual tiles |
| Incomplete badge on a Closet item | A13 | Screen reader announces "incomplete" state, not just a visual badge |

### 5. AI Constraints

- Do not create color-only-differentiated UI — must always pair text/icon (A2).
- Do not implement gesture-only actions without a non-gesture alternative (A4).
- Do not relax WCAG-specified numeric values (contrast, etc.) (A3).
- Do not redefine the existing I7 AI-processing contract for accessibility purposes — only augment it (A9).
- Do not shrink hit areas below minimum regardless of visual density (A10).
- Do not leave overlapping gestures without a defined priority/trigger condition (A11).
- Do not let density increases reduce accessible label coverage or hit-area size (A12).
- Do not leave any visual-only state indicator without a text equivalent (A13).
- Do not define implementation-level (widget/code) detail in this document — deferred to Component Strategy.
