---
name: uiux-design-conventions
description: Methodology for making and implementing UI/design decisions in this project — the Layer Boundary Rule (which of UX/Layout/Interaction/Component a decision belongs to) and the Design/Visual Review checklists. Invoke before making a Decision-stage design call, or before/during a Design Review or Visual Review.
---

# UIUX Design Conventions

## 이 스킬을 언제 쓰나

디자인 Decision-stage 판단을 내리기 전, 또는 Design Review/Visual Review를 수행하기 전에 호출한다.

## Layer Boundary Rule (Design System Governance Rule)

> Scope: Applies to ALL Design Sessions
> Type: System-level governance rule (non-optional)

### 1. Purpose

This rule prevents overlap between design layers and ensures each layer maintains a single responsibility.

All design decisions MUST be assigned to exactly one layer.

### 2. Core Principle

Each concept belongs to ONE layer only. Duplicate definitions across layers are NOT allowed.

### 3. Layer Responsibilities

**3.1 UX Principles (Decision Layer)** — Role: Defines *why* design decisions exist.
- Includes: Experience philosophy, Behavioral principles, Trade-off guidelines, User decision reasoning
- Must NOT include: UI structure, Layout rules, Gestures, Component design

**3.2 Layout Principles (Structure Layer)** — Role: Defines spatial structure and visual organization.
- Includes: Screen structure, Section hierarchy, Content flow, Spatial relationships
- Must NOT include: Gestures, State changes, Animations, Component behavior, Data rules

**3.3 Interaction Principles (Behavior Layer)** — Role: Defines how users interact with the system.
- Includes: Gestures and input meaning, State transitions, Feedback rules, Undo/Redo behavior
- Must NOT include: Layout structure, UI spacing/color rules, Component definitions, Page structure

**3.4 Component System (UI Unit Layer)** — Role: Defines reusable UI building blocks.
- Includes: Buttons, Cards, Inputs, etc., Internal component states, Reusable UI behavior
- Must NOT include: Page structure, UX philosophy, Layout rules, Navigation flow

### 4. Rule Enforcement

**R4.1 Single Ownership Rule**: Each concept MUST belong to only one layer.
Example: Undo behavior → Interaction ONLY / Card structure → Component ONLY / Screen layout → Layout ONLY

**R4.2 Decision Rule (Critical)**: If uncertain, classify using this rule:
- Does it define HOW the UI behaves? → Interaction
- Does it define HOW UI is arranged? → Layout
- Does it define a reusable UI unit? → Component
- Otherwise → UX Principles

### 5. Golden Question

When classifying any rule: *"If this rule did not exist, would the UI behavior be undefined?"*
- YES → Interaction / YES (structural) → Layout / YES (UI unit) → Component / NO → UX Principles

### 6. Enforcement Priority

This rule overrides all ambiguous classification cases. If conflict occurs between layers, this rule has higher priority than local definitions.

## Design Review / Visual Review Checklists

Review is not the stage for making the design more visually appealing — it is the stage for identifying problems.

**Design Review Areas**: UX, Visual Hierarchy, Accessibility, Consistency, Design System, Component Reuse, Material 3, Flutter implementation feasibility.

**Visual Review** (performed after the representative High-Fidelity Sample, to validate overall visual direction before creating Design Tokens): Typography scale, Color harmony, Spacing rhythm, Corner radius, Icon size, Visual hierarchy, Overall consistency. No new features or interaction changes should be introduced during this review.

## 참고 (값 아님, 방법론만)

실제 브랜드 값/타이포/컬러는 여기 없다 — `docs/reference/design/01_BrandGuid.md`를 참고. 이 스킬은 "어느 레이어에 속하는 결정인지" 판단하는 방법론만 담는다.
