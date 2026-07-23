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

