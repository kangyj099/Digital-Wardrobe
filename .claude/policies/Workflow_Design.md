# Design Workflow

> Version 1.0
>
> Purpose: A design workflow policy for efficiently collaborating with AI on Flutter-based mobile app design.

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

> Scope: Applies to ALL Design Sessions
> Type: System-level governance rule (non-optional)

---

## 1. Purpose

This rule prevents overlap between design layers and ensures
each layer maintains a single responsibility.

All design decisions MUST be assigned to exactly one layer.

---

## 2. Core Principle

Each concept belongs to ONE layer only.

Duplicate definitions across layers are NOT allowed.

---

## 3. Layer Responsibilities

### 3.1 UX Principles (Decision Layer)

#### Role
Defines *why* design decisions exist.

#### Includes
- Experience philosophy
- Behavioral principles
- Trade-off guidelines
- User decision reasoning

#### Must NOT include
- UI structure
- Layout rules
- Gestures
- Component design

---

### 3.2 Layout Principles (Structure Layer)

#### Role
Defines spatial structure and visual organization.

#### Includes
- Screen structure
- Section hierarchy
- Content flow
- Spatial relationships

#### Must NOT include
- Gestures
- State changes
- Animations
- Component behavior
- Data rules

---

### 3.3 Interaction Principles (Behavior Layer)

#### Role
Defines how users interact with the system.

#### Includes
- Gestures and input meaning
- State transitions
- Feedback rules
- Undo / Redo behavior

#### Must NOT include
- Layout structure
- UI spacing / color rules
- Component definitions
- Page structure

---

### 3.4 Component System (UI Unit Layer)

#### Role
Defines reusable UI building blocks.

#### Includes
- Buttons, Cards, Inputs, etc.
- Internal component states
- Reusable UI behavior

#### Must NOT include
- Page structure
- UX philosophy
- Layout rules
- Navigation flow

---

## 4. Rule Enforcement

### R4.1 Single Ownership Rule

Each concept MUST belong to only one layer.

Example:
- Undo behavior → Interaction ONLY
- Card structure → Component ONLY
- Screen layout → Layout ONLY

---

### R4.2 Decision Rule (Critical)

If uncertain, classify using this rule:

- Does it define HOW the UI behaves? → Interaction
- Does it define HOW UI is arranged? → Layout
- Does it define a reusable UI unit? → Component
- Otherwise → UX Principles

---

## 5. Golden Question

When classifying any rule:

> "If this rule did not exist, would the UI behavior be undefined?"

- YES → Interaction
- YES (structural) → Layout
- YES (UI unit) → Component
- NO → UX Principles

---

## 6. Enforcement Priority

This rule overrides all ambiguous classification cases.

If conflict occurs between layers:
→ This rule has higher priority than local definitions.

---

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

---

# 3. Unit of Work

Each session performs only one design task.

---

# 4. Page Type First

Before designing a new screen, first determine its Page Type.

Define shared rules in the Page Type specification, and document only screen-specific behavior in individual screen specifications.

Each screen should contain only its unique characteristics.

---

# 5. Design Freeze

The representative High-Fidelity Sample is the visual baseline of the project.

After the Design Tokens are finalized, changes to layout structure or visual language should be avoided.

If structural changes are required after Design Tokens are approved, the representative High-Fidelity Sample must be reviewed and updated first.
---

# 6. Design Review

Review is not the stage for making the design more visually appealing—it is the stage for identifying problems.

**Review Areas**

* UX
* Visual Hierarchy
* Accessibility
* Consistency
* Design System
* Component Reuse
* Material 3
* Flutter implementation feasibility

## Visual Review

Visual Review is performed after the representative High-Fidelity Sample.

Its purpose is to validate the overall visual direction before creating Design Tokens.

Review Areas

- Typography scale
- Color harmony
- Spacing rhythm
- Corner radius
- Icon size
- Visual hierarchy
- Overall consistency

No new features or interaction changes should be introduced during this review.
---

# 7. Design Audit

Reviews the project's overall design.

Audit does not make direct modifications. It creates tasks for the PM.

**Review Areas**

* Cross-screen consistency
* Design System conflicts
* Duplicate components
* UX flow
* Accessibility

---

# 8. Design System Updates

The Design System is established after Design Tokens are finalized.

Whenever shared visual rules or Tokens change, update the Design System accordingly.
---

# 9. Component Library Updates

Whenever reusable shared components are added or modified, update the Component Library.

---

# 10. Change Impact

Evaluate the Change Impact before making any design changes.

---

# 11. Definition of Done

□ Review feedback has been incorporated

□ Design Freeze status has been verified

□ Design System update has been verified

□ Component Library update has been verified

□ Developer impact has been reviewed

□ Decision has been documented

□ Design Debt has been documented

---

# 12. Core Operating Principles

1. The Design System takes precedence over individual screens.
2. Shared rules are defined in the Page Type specification.
3. Individual screens contain only their unique characteristics.
4. Review identifies problems.
5. Audit evaluates the project as a whole.
6. The Design System is always kept up to date.
7. Prioritize component reusability.
8. Always consider Flutter implementation feasibility.
9. Always evaluate the Change Impact before making changes.
10. Design is inseparable from development.
