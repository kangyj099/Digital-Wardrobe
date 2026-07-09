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
