## Stage 6 — Component Strategy

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
