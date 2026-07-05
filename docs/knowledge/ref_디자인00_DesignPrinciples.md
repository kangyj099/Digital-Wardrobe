# Design Principles

## Stage 1 — UX Principles

### 1. Definition

UX Principles are the top-level behavioral commitments that govern how the app should *feel* and *respond* to the user across all three core content categories (Closet / Composition / Style Log). They sit above Interaction Principles and Layout Principles in the Design Workflow hierarchy (`UX Principles → Design Principles → Design System → Component Library`) and are derived directly from:

- 공통 규칙 › 디자인 원칙 (ref_기획03)
- Needs doc's "Design implications" split between Utility-oriented (① Closet) and Retention-oriented (③ Style Log) UX tones
- MVP core loop and differentiators (editable compositions, location memo, wear history)

These principles do not define visuals (color, spacing, typography) — that is Design Tokens' job. They define *what kind of decisions* later stages are allowed to make.

### 2. Why it exists

Without a stated UX Principle layer, later stages (Interaction, Layout, Tokens, Components) have no shared filter for resolving trade-offs. Given this project's explicit dual nature — a fast utility tool (Closet) and a reflective engagement tool (Style Log) — a single undifferentiated "make it feel nice" principle would produce inconsistent screen-level decisions. Naming the principles now lets every later stage cite *which* principle justifies a decision instead of relying on aesthetic judgment.

### 3. Rules

**P1. Dual-Mode UX Split (Speed vs. Reflection)**

- Closet (and any "utility path": Add Item, tag search, location lookup) optimizes for **speed and retrieval accuracy**. Fewer taps, minimal confirmation friction, no unnecessary animation delay.
- Style Log (and any "reflection path": viewing composition/style-log history, wear-count displays) optimizes for **satisfaction of revisiting**, i.e., can tolerate slightly more visual richness or motion, but never at the cost of navigation clarity.
- Composition is a hybrid: creation flow behaves like utility (fast placement), but Composition Detail viewing behaves like reflection (history, cross-links).
- This split must not fork the navigation model or component set — same Page Types (Main/Detail/Add-Create/Modal/Utility) apply everywhere; only *pacing and motion emphasis* differ.

**P2. Learning-Cost Minimization**

- Every new interaction pattern must be justified against an existing pattern before being introduced (already codified in 기획03 as "기능 재사용 원칙"). UX Principles inherits this as a top rule, not just a screen-level rule.
- A returning user should never need to relearn a gesture that another screen already taught them (e.g., long-press behavior must stay semantically the same: "enter multi-select" or "enter edit," never repurposed per screen).

**P3. State Continuity Over Confirmation**

- Reflects 상시 저장 (always-save, no draft concept) and 미완성 레코드 표시. The UX default is: *actions persist immediately, are visible immediately, and are reversible* — rather than requiring the user to confirm before an action takes effect. Confirmation modals are reserved for destructive-irreversible actions only (매치: 영구 삭제, 비우기).
- Corollary: "되돌리기(Undo)" and 토스트 patterns are the preferred safety net, not blocking dialogs.

**P4. Cross-Reference as a First-Class Path, Not a Detour**

- Item Detail ↔ Composition Detail ↔ Style Log Viewer bidirectional navigation (기획02) is a core differentiator, not an edge case. UX decisions at every stage must preserve navigation-stack integrity for this chain (Flow D/E) — this rule outranks minor screen-level convenience choices.

**P5. Non-Blocking AI/Processing States**

- Reflects 공통 규칙's AI 처리 실패 상태 policy. Users are never fully blocked by AI processing (background removal, tagging); the UX must always offer a manual fallback path (manual masking, manual tag entry) rather than a dead end.

**P6. Consistent, Restrained Visual Tone**

- 흑백 기피 (avoid pure black/white, prefer a sophisticated/high-sensitivity tone), 폰트/컬러 소수 고정, 다크모드 지원 — carried forward as a UX-level constraint on Tokens, not redefined here.

**P7. Context Return Guarantee**

- Any flow that pulls the user out of their current context (modals, cross-navigation, external reuse of Closet as a picker) must guarantee return to the exact prior state (scroll position, filter state) — this generalizes 기획02's "Navigation stack preserved" note and 기획03's 바인딩 뎁스 제한 into a single UX-level guarantee.

### 4. Real UI Behavior Examples

| Scenario | Principle Applied | Resulting Behavior |
| --- | --- | --- |
| User taps [+] on Closet Main | P1 (speed) | Immediate camera/gallery launch, no intermediate confirmation screen |
| User taps a Style Log card | P1 (reflection) | Slightly more deliberate transition (e.g., card-to-detail motion) acceptable, but load must still be fast |
| User exits mid–"코디 만들기" without saving | P3 | Composition already exists as a record (미완성 배지); no "discard changes?" prompt |
| User deletes a clothing item used in 3 compositions | P3 (reversible unless destructive) + explicit warning per 기획03 cascade rule | Non-blocking move-to-trash, but *does* warn because of downstream cascade impact — this is the documented exception, not a new pattern |
| User taps a linked Style Log from Item Detail, then taps a clothing item inside it | P4 | Full back-stack preserved per Flow D; header dropdown is the only stack-reset action |
| Auto-tagging API times out after retries | P5 | Popup offers manual retry option, never silently fails without a path forward |

### 5. Flutter Implementation Implications

- P1/P2: Navigation and gesture handling should centralize in shared `go_router` route definitions and shared gesture handlers, not per-screen custom logic — prevents accidental divergence between "fast" and "reflective" paths.
- P3: Requires immediate Firestore/local write-on-entry for Add/Create-type screens (already specified in 기획03); UI state should be driven by persisted record state, not local-only form state, to support kill/resume correctly.
- P4: Back-stack behavior should use `go_router`'s stack rather than ad hoc `Navigator.push` chains, so cross-reference chains (Flow D/E) unwind predictably.
- P5: Async processing states (background removal, tagging) need a shared status-handling widget/provider (loading → retry-backoff → failure-popup) reusable across Add Item and multi-add flows, rather than reimplemented per feature.
- P7: Scroll/filter state should survive modal dismissal — implies state should live above the modal route (e.g., in a persistent controller/provider), not be recreated on modal open.

### 6. AI Constraints (what AI must not do in later/related work)

- Do not introduce a different navigation paradigm (e.g., tabs, drawer) for Style Log just because it's "reflective" — Page Type structure stays uniform (P1 corollary).
- Do not add confirmation dialogs to reversible actions to seem "safer" — violates P3 and contradicts explicit trash/undo policy already defined in 기획03.
- Do not break or shortcut the Item Detail ↔ Composition ↔ Style Log back-stack for the sake of a simpler transition animation.
- Do not invent new gesture meanings not already listed in the 제스처 table (기획03) without flagging it as a new pattern requiring PM/Design review.
- Do not silently fail or fully block the UI on AI processing errors.
- Do not skip ahead to Design Tokens, color values, or specific component specs in this stage — UX Principles must remain implementation-agnostic.

---

## Stage 2 — Interaction Principles (Revised)

### 1. Definition

Interaction Principles define the system-wide rules for *how a single user action is interpreted and responded to* — gesture meaning, feedback timing, reversibility mechanics, and cross-screen reuse behavior. They translate UX Principles (Stage 1) into reusable interaction contracts, without specifying visual tokens or implementation detail (reserved for later stages).

Primary sources: 공통 규칙 › 제스처 table, 기능 재사용 원칙, 바인딩 뎁스 제한, 미완성/휴지통 항목은 바인딩 불가, 상시 저장, 삭제 & 휴지통 section, Undo/haptic mentions in 코디 만들기 (ref_기획03).

### 2. Rules

**I1. One Gesture = One Meaning, Project-Wide**

A gesture's meaning is fixed globally; only its *target* changes per screen, never its *intent*.

- Pinch → size/zoom continuum — never repurposed for other actions.
- Long-press → escalate from viewing to acting on an item (multi-select entry, or editor entry) — both are variants of the same underlying intent.
- Drag (item) → reposition; drag-out-of-bounds → delete, with the same feedback contract wherever it appears.
- Swipe (horizontal) → slot/card navigation only; must not double as a destructive action elsewhere.

**I2. Reuse Before Redefine**

Any screen requiring item-selection must invoke the existing Main-type screen as a modal, not a bespoke picker. Affordances inside a reused modal may be *reduced* relative to native entry (per documented 외부 호출 시 제공 기능과 실제 진입 시 기능은 차등 적용) but must never *diverge* in gesture meaning from the native screen.

**I3. Binding Depth Limit Is an Interaction Contract, Not Just a Data Rule**

Any interaction chain that could create nested "select → create → select → create" loops is capped at one level. From within a reused selection modal, the user may create a new record, but that record's own internal selection slots become *selection-only* (no further "create new" affordance). Enforced identically wherever binding modals appear.

**I4. Disabled-but-Visible, Never Hidden**

Incomplete items remain visible-but-non-selectable inside binding modals (grayed, badge shown); tapping redirects to their completion screen. Trashed items are fully excluded from binding modals — distinct from the "disabled" treatment.

**I5. Editor Principle — Single-Step Undo (Generalized)**

**All editors support single-step Undo**, scoped to the immediately preceding action only (not a multi-step history stack), and scoped to that editor's own session. This is distinct from Toast+Undo (below) and must not be conflated with it.

**Reversibility Has Two Distinct Mechanisms — Do Not Conflate**

- **Toast+Undo (session-independent, single step):** used for reversible-state transitions like delete → trash. Action executes immediately; a toast offers a single "실행취소" action within a time-limited window.
- **In-editor Undo (session-scoped, single most-recent step):** per the Editor Principle above, applies to any editor performing direct-manipulation actions (e.g., move/rotate/resize/z-index/add/remove in 코디 만들기).
These two patterns are mechanically distinct and must not be merged into one generic "Undo" component.

**I6. Confirmation Modals Are Reserved for Irreversible Actions Only**

A confirming dialog may only gate an action that (a) is irreversible (영구 삭제, 비우기) or (b) has irreversible *downstream* consequences even though the primary action is reversible (e.g., deleting an item used in Compositions — reversible via trash, but warned due to cascade-cleanup consequences on next edit). No other action introduces a blocking confirm step.

**I7. AI-Processing Interaction Contract**

Any AI-dependent step (auto-mask, auto-tag) follows a single shared interaction pattern: loading indicator → automatic retry with backoff → on exhaustion, a popup stating failure reason + count with a single retry action. No screen may implement a custom variant of this flow. *(Specific retry count/timing values are deferred to the Feedback Pattern / Component stage.)*

**I8. Context-Preserving Interruption**

Opening a modal/sheet or navigating into a bound record must not reset the interaction state of the screen or surface underneath it (e.g., in-progress input, scroll/selection state, or an open transient UI element). This is distinct from Stage 1's UX-level guarantee — here it governs gesture/input state specifically, generalized across any screen with dismissible overlays.

### 3. Real UI Behavior Examples

| Scenario | Rule Applied | Behavior |
| --- | --- | --- |
| User long-presses a Closet item in Closet Main | I1 | Enter multi-select mode |
| User long-presses an item placed on the Composition Artboard | I1 | Enter Composition Editor — same gesture, different escalation target |
| User is in Style Log Viewer linking a Composition, taps [+] to create new | I3 | New Composition opens; if user then tries to link a Style Log from inside it, only "select existing" is offered |
| User taps a grayed-out incomplete item inside a selection modal | I4 | Navigates to that item's completion screen instead of selecting it |
| User deletes a Composition | I5 (toast) | Immediate move-to-trash + toast with single Undo action, no confirm dialog |
| User rotates an item in an editor, then moves another item, then wants to undo the rotate | I5 (editor) | Not possible — only the move (most recent action) can be undone |
| User deletes a clothing item referenced in 2 Compositions | I6 | Reversible action still executes into trash, but a warning popup appears first — exception, not new pattern |
| AI processing fails after configured retries | I7 | Standard retry-then-popup flow, identical across all AI-dependent entry points |
| User opens a selection modal mid-interaction on an underlying screen, then cancels it | I8 | Underlying screen's state is unchanged on return |

### 4. AI Constraints

- Do not assign a new meaning to an existing gesture without flagging it as a new pattern requiring review — violates I1.
- Do not build a standalone picker/selector UI for any new binding feature — must reuse existing Main-type screens per I2.
- Do not allow "create new" affordances at binding depth 2+ — violates I3.
- Do not limit Undo to Composition Editor only — I5 applies to all editors.
- Do not merge Toast+Undo and in-editor Undo into a single generic component — violates I5's explicit distinction.
- Do not add confirmation dialogs to reversible actions — violates I6.
- Do not create a custom AI-failure-handling flow per feature, and do not specify retry count/timing at this stage — violates I7 (deferred to Feedback Pattern/Component stage).
- Do not reset underlying screen/interaction state when a modal or overlay opens or closes — violates I8.

---

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

---

## Stage 4 — Accessibility Rules (English)

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

---

## Stage 5 — Design Tokens (Draft)

### 1. Definition

This stage defines only the **role structure** of design tokens. Actual values (hex, px, font names, etc.) remain placeholders pending the Brand Guide stage. Based on Material 3's role-based token structure, incorporating this project's existing constraints (avoid black/white, dark mode support, limited fixed colors, 3-level density, etc. from Stages 3/4).

### 2. Rules

**T1. Color Roles (Material 3 based, values undefined)**

- `Primary` / `OnPrimary`
- `Secondary` / `OnSecondary` (maps to Accent role)
- `Surface` / `OnSurface`
- `Background` / `OnBackground`
- `Error` / `OnError` (used for destructive-action confirmation, linked to I6)
- Each role has both Light/Dark sets (dark mode principle, Stage 1 P6)
- Values undefined — to be filled by Brand Guide output

**T2. Neutral/Gray Scale Role**

- Defines only a stepped scale role (`Gray50`–`Gray900`, exact step count TBD in Brand Guide)
- Per the avoid-black/white principle (Stage 1 P6), pure `#000000`/`#FFFFFF` are prohibited — this is fixed here as a **constraint rule**, not a value

**T3. Semantic State Color Roles**

- `Disabled` (I4 disabled indication), `Warning` (I6 cascade warning), `Success/Info` (toasts, etc.)
- Roles only, values undefined

**T4. Typography Roles**

- `DisplayLarge/Medium/Small`, `TitleLarge/Medium/Small`, `BodyLarge/Medium/Small`, `LabelLarge/Medium/Small` (Material 3 type scale roles adopted as-is)
- Font family values undefined — the "few fixed fonts" principle (Stage 1 P6) is reflected structurally only: a rule limiting the project to a **maximum of 2 font families** (1 body + optionally 1 emphasis) is fixed now
- To support Dynamic Type (Stage 4 A5), each role must be based on a **scalable unit**, not a fixed px value (exact unit TBD)

**T5. Spacing Scale Role**

- Defines only stepped role names (`Spacing.xxs`–`Spacing.xl`), actual multiplier/base value undefined
- Structural rules like L5 (reserved space for overlay coverage) and L2 (overlay header) will reference this scale

**T6. Density Token (linked to L4)**

- `Density.min / Density.mid / Density.max` — the mapping point where Stage 3 L4's "3-level structure only" gets actual column-count values
- Values (column counts) undefined — only role names fixed here

**T7. Elevation/Overlay Token (linked to L2, L6)**

- `Elevation.overlayHeader`, `Elevation.overlayCanvas`, etc. — roles representing the visual layering order for L2 (overlay header) and L6 (non-displacing secondary region over fixed canvas)
- Values (z-index/blur degree) undefined

**T8. Motion Token (linked to A7)**

- `Motion.standard`, `Motion.reduced` — the point where Stage 4 A7 (reduced motion option) reflects system settings
- Duration/easing values undefined

### 3. AI Constraints

- Do not generate actual values (hex, px, font names) at this stage — pending Brand Guide output
- Do not finalize pure black/white as actual Neutral scale values (only the constraint rule is fixed, T2)
- Do not design more than 2 font families (T4)
- Do not decide concrete numeric values for Density/Elevation/Motion roles at this stage — deferred to Component Strategy or Brand Guide
- Do not invent new color/typography role concepts outside the Material 3 role system (no-redefinition principle)

---

## Stage 6 — Component Strategy (English)

### 1. Definition

This document defines, prior to building the Component Library, **which components are needed and which rules each component is responsible for implementing**. Visual specs (sizes, color values) for the components themselves are filled in at a later stage once Stage 5 tokens are finalized. Items deferred from earlier stages (L7 fixed-slot reorder, I5 in-editor undo scope, I7 retry count/timing) are assigned ownership here.

### 2. Component Inventory — Implements / Depends On

**C1. SelectableGalleryTile**

- Implements: I1 (gesture = selection), I4 (3-state: normal/disabled-incomplete/excluded-trashed), A6 (accessibility label), A10 (hit area), A12 (information retained at high density)

**C2. GroupedGalleryGrid**

- Implements: L3 (Grouped variant), L4/T6 (3-level density), L5 (reserved space for overlay coverage)

**C3. FlatFilterGallery**

- Implements: L3 (Flat+Filter variant), filter chip rules

**C4. OverlayHeader**

- Implements: L2 (structure: non-space-consuming), stacking/scroll-linked behavior defined in Interaction stage

**C5. ArtboardCanvas + ArtboardItem**

- Implements: L6 (fixed canvas), I1 (gestures), A4 (non-gesture alternative), A11 (gesture conflict rule)

**C6. BindingSelectionModal**

- Implements: I2 (reuse principle), I3 (binding depth limit), I4 (3-state display)

**C7. UndoableActionToast (session-independent Undo)**

- Implements: I5 — used for **record-level state transitions** such as delete/trash. State store is global/persistent (based on the deleted-items list) and remains valid within a time window even after screen transitions.

**C8. EditorUndoController (editor session-scoped Undo)**

- Implements: I5 (Editor Principle) — applies only to the **single most recent action** (move/rotate/resize/z-index). State store is scoped to that editor session only, and is discarded once the editor is exited (save/leave).
- **Boundary with C7**: C7 governs "what is undone (record existence)"; C8 governs "what is undone (attribute value change)" — the targets themselves differ, and the two controllers never share state. A single user action never spans both systems (delete → C7 only; edit operations → C8 only, mutually exclusive).

**C9. AiProcessingStatus**

- Implements: I7 (loading → retry → failure-popup structure), A9 (accessibility announcement)
- Reused identically across single-add and multi-add flows
- *(Retry count/timing values: per confirmed direction, these remain deferred to this component/Feedback stage, consistent with the original Stage 2 decision — not specified in this document yet)*

**C10. SequentialSlotCard**

- Implements: L7 (fixed leading slots + reorderable trailing slots), swipe navigation

**C11. DestructiveConfirmModal**

- Implements: I6 (irreversible actions only), T1 Error/Warning roles

**C12. StatusBadge**

- Implements: A13 (text equivalents for all state badges)

### 3. Accessibility Role Separation

- **Stage 4 (Accessibility Rules)**: the **definition** layer — "what must be satisfied"
- **Stage 6 (Component Strategy)**: the **implementation-point** layer — "which component implements that rule"
- This document does not redefine accessibility criteria themselves — only references/maps them

### 4. AI Constraints

- Do not create a new per-screen component for functionality already covered by this inventory — reuse first.
- Do not share state stores between C7 and C8.
- Do not redefine upper-layer rules (e.g., Accessibility) at this stage — only express implements relationships.
- Do not specify algorithmic detail values (e.g., in C9) in this document until their ownership location is finalized.