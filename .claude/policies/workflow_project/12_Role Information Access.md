# 12. Role Information Access

Defines what materials each role sees for a given task, based on the task's **Layer** and **Stage** — not on job title. This generalizes across any future pipeline (frontend, backend, infra, etc.) instead of hardcoding per-role exceptions.

## 12.1 Layer × Stage Determines Scope

Every task is tagged with the Layer(s) it touches and the Stage (Decision or Implementation) within that layer. This tagging happens during the existing Impact Scope evaluation (§7) — no separate step is added.

| Layer | Stage | Required Review | Required Materials |
| --- | --- | --- | --- |
| UI/Screen | Decision (Design) | Design Review | Raw references (`참고자료/`), Design reference docs, Plan reference docs (IA/UX spec), Brand docs, `Decision.md`, **Skill: `uiux-design-conventions`** (invoke first), **Skill: `documentation-conventions`** (invoke first) |
| UI/Screen | Implementation (Frontend) | Development Review + spec-compliance check | Finalized design tokens/system doc, screen UX spec, existing widgets (`lib/`), Development workflow policy, Frontend workflow policy (`Workflow_Frontend.md` — stage-index anchor doc, lists the Frontend-specific skills to invoke) |
| Logic/Feature | Decision (Planning) | Usually none (PM scope) | Plan reference docs, **Skill: `documentation-conventions`** (invoke first) |
| Logic/Feature | Implementation | Development Review (functional) | Related code, Plan reference docs, **Skill: `engineering-principles`** (invoke first) |
| Data/API/Architecture | Decision | Development Review (architecture), pre-review | Development workflow policy, **Skill: `documentation-conventions`** (invoke first) |
| Data/API/Architecture | Implementation | Development Review (architecture) | Related modules/schema, **Skill: `engineering-principles`** (invoke first) |
| (any Layer with runtime behavior) | Implementation — Tester pass | Runs after Review passes | Same Reference docs as Review for that Layer/Stage, `Decision.md`/`TechnicalDebt.md`, Worker's handoff + modified files, and the runnable app itself (not the raw exploratory material behind a Decision-stage task) |

## 12.2 Worker vs. Review Materials

Worker and Review do not receive identical materials for the same task.

- **Shared**: judgment-criteria documents — the Reference documents for that Layer/Stage, **and** `Decision.md` / `TechnicalDebt.md`. History documents count as judgment criteria the same way Reference documents do, since Review checks policy compliance and consistency against past decisions.
- **Worker-only**: raw/exploratory material behind a Decision-stage task (e.g. raw design references, brand voice docs). Review does not need the exploration process, only the result and whether it complies.
- **Review-only**: the Worker's output (modified files, change summary, impact scope) — the artifact being judged, which the Worker produces rather than consumes.

## 12.3 Scope Escalation

If Review needs material outside its granted scope to reach a judgment, Review does not expand its own access. Review requests a scope expansion from PM, who re-evaluates Impact Scope (§7) and grants the minimum additional material needed. This preserves the Minimal Handoff Principle (§3) while allowing legitimate exceptions.

## 12.4 Task Manifest

§12.1's Required Materials are abstract categories ("Plan reference docs", "existing widgets"). Before spawning a Worker or Review, PM converts them into an explicit **Task Manifest**: a concrete list of file paths and skills, each tagged with an access mode. This manifest — not a restatement of §12.1's categories — is what goes into the dispatch prompt.

**Access modes**

- **Read** — reference/judgment-criteria material. Must not be modified, even though the Worker's tool grant (`Read, Edit, Write, ...`) would technically allow it.
- **Edit** — an existing file the task expects the Worker to modify.
- **Write** — a new file the task expects the Worker to create.

A `Skill: <name>` entry is always Read — invoking a skill never grants edit access to the skill file itself.

**Example** (Worker dispatch for a UI/Screen × Implementation(Frontend) task):

```
Read: docs/reference/design/00_DesignPrinciples/03_Layout Principles.md, docs/reference/plan/03_화면별UX명세서/01_옷장.md
Edit: lib/screens/closet/closet_main_screen.dart
Write: lib/widgets/closet_item_tile.dart
Skill: flutter-implementation-conventions
```

For a Review dispatch, every item is Read by default (per §12.2, Review judges the Worker's output rather than producing it) — this includes the Worker's modified files themselves, which Review inspects but never edits.
