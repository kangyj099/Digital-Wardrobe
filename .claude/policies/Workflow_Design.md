# Design Workflow

> Version 3.1
>
> Purpose: A design workflow policy for efficiently collaborating with AI on Flutter-based mobile app design. Single consolidated document (former `workflow_design/` subfiles merged back into this file on 2026-07-22 for reading convenience — see `docs/history/Decision.md`).

---

# 1. Core Principles

Design is the process of building a consistent Design System.

All screens follow the structure below.

```text
Design Principles
↓
Design System
↓
Component Library
```

## Layer Boundary Rule (Design System Governance Rule)
→ Skill: `uiux-design-conventions` (`.claude/skills/uiux-design-conventions/SKILL.md`) — invoke before making a Decision-stage design call.

# 2. Design Process

Design work follows the sequence below.

```text
Brand Guide
↓
UX Principles
↓
Interaction Principles
↓
Layout Principles
↓
High-Fidelity Sample (3–5 representative screens)
↓
Visual Review
↓
Design Tokens
↓
Design System
↓
Component Library
↓
Remaining High-Fidelity Screens
↓
Review
↓
Developer Handoff
```

## 2.1 Cross-Workflow Trigger: Hi-Fi Sample Delivered via Development Track

The representative High-Fidelity Sample (3–5 screens) is sometimes built as Frontend Implementation tasks in the Development pipeline (Layer=UI/Screen, Stage=Implementation) rather than as standalone design deliverables — this is what happened with this project's Flutter Hi-Fi sprint.

When that happens, passing Development Review and Tester does **not** substitute for Visual Review — Development Review checks code/functionality, not typography/color/spacing/visual hierarchy. Once the representative sample screens are done on the Development track, PM must explicitly trigger Visual Review before treating that Design Process milestone as complete, and Design Tokens stay provisional (not frozen per §5) until that review happens.

# 3. Unit of Work

Each session performs only one design task.

# 4. Page Type First

Before designing a new screen, first determine its Page Type.

Define shared rules in the Page Type specification, and document only screen-specific behavior in individual screen specifications.

Each screen should contain only its unique characteristics.

# 5. Design Freeze

The representative High-Fidelity Sample is the visual baseline of the project.

After the Design Tokens are finalized, changes to layout structure or visual language should be avoided.

If structural changes are required after Design Tokens are approved, the representative High-Fidelity Sample must be reviewed and updated first.

# 6. Design Review
→ Skill: `uiux-design-conventions` (`.claude/skills/uiux-design-conventions/SKILL.md`) — Design Review / Visual Review checklists live here.

# 7. Design Audit
→ `Workflow_Project.md` §2 Feature Audit 참고(Read-only, PM에게 태스크만 제안). Design 도메인 Review Areas:

* Cross-screen consistency
* Design System conflicts
* Duplicate components
* UX flow
* Accessibility

# 8. Design System Updates

The Design System is established after Design Tokens are finalized.

Whenever shared visual rules or Tokens change, update the Design System accordingly.

# 9. Component Library Updates

Whenever reusable shared components are added or modified, update the Component Library.

# 10. Change Impact

Evaluate the Change Impact before making any design changes.

# 11. Definition of Done

□ Review feedback has been incorporated

□ Design Freeze status has been verified

□ Design System update has been verified

□ Component Library update has been verified

□ Developer impact has been reviewed

□ Decision has been documented

□ Design Debt has been documented

# 12. Core Operating Principles

1. The Design System takes precedence over individual screens.
2. Shared rules are defined in the Page Type specification.
3. Individual screens contain only their unique characteristics.
4. Review/Audit 범위 원칙 → `Workflow_Project.md` §11 참고.
5. The Design System is always kept up to date.
6. Prioritize component reusability.
7. Always consider Flutter implementation feasibility.
8. Always evaluate the Change Impact before making changes.
9. Design is inseparable from development.
