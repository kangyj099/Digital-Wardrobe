# 12. Role Information Access

Defines what materials each role sees for a given task, based on the task's **Layer** and **Stage** — not on job title. This generalizes across any future pipeline (frontend, backend, infra, etc.) instead of hardcoding per-role exceptions.

## 12.1 Layer × Stage Determines Scope

Every task is tagged with the Layer(s) it touches and the Stage (Decision or Implementation) within that layer. This tagging happens during the existing Impact Scope evaluation (§7) — no separate step is added.

| Layer | Stage | Required Review | Required Materials |
| --- | --- | --- | --- |
| UI/Screen | Decision (Design) | Design Review | Raw references (`참고자료/`), Design reference docs, Plan reference docs (IA/UX spec), Brand docs, `Decision.md` |
| UI/Screen | Implementation (Frontend) | Development Review + spec-compliance check | Finalized design tokens/system doc, screen UX spec, existing widgets (`lib/`), Development workflow policy, Frontend workflow policy (`Workflow_Frontend.md` — stage-index anchor doc, lists the Frontend-specific skills to invoke) |
| Logic/Feature | Decision (Planning) | Usually none (PM scope) | Plan reference docs |
| Logic/Feature | Implementation | Development Review (functional) | Related code, Plan reference docs, **Skill: `engineering-principles`** (invoke first) |
| Data/API/Architecture | Decision | Development Review (architecture), pre-review | Development workflow policy |
| Data/API/Architecture | Implementation | Development Review (architecture) | Related modules/schema, **Skill: `engineering-principles`** (invoke first) |
| (any Layer with runtime behavior) | Implementation — Tester pass | Runs after Review passes | Same Reference docs as Review for that Layer/Stage, `Decision.md`/`TechnicalDebt.md`, Worker's handoff + modified files, and the runnable app itself (not the raw exploratory material behind a Decision-stage task) |

## 12.2 Worker vs. Review Materials

Worker and Review do not receive identical materials for the same task.

- **Shared**: judgment-criteria documents — the Reference documents for that Layer/Stage, **and** `Decision.md` / `TechnicalDebt.md`. History documents count as judgment criteria the same way Reference documents do, since Review checks policy compliance and consistency against past decisions.
- **Worker-only**: raw/exploratory material behind a Decision-stage task (e.g. raw design references, brand voice docs). Review does not need the exploration process, only the result and whether it complies.
- **Review-only**: the Worker's output (modified files, change summary, impact scope) — the artifact being judged, which the Worker produces rather than consumes.

## 12.3 Scope Escalation

If Review needs material outside its granted scope to reach a judgment, Review does not expand its own access. Review requests a scope expansion from PM, who re-evaluates Impact Scope (§7) and grants the minimum additional material needed. This preserves the Minimal Handoff Principle (§3) while allowing legitimate exceptions.
