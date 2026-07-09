# 5. Standard Pipeline

Once work is completed, return it to the PM.

## S (Small)

```text
Worker → Complete
```

Exception: if the single modification changes runtime-observable behavior (not just text/style/docs), Tester still runs — treat it as the M pipeline for that step.

---

## M (Medium)

```text
Worker → Review → (Fail) Worker(fix) → Review          [반복: Review 통과할 때까지]
              → (Pass) Tester → (Pass) Complete
                             → (Fail) Worker(fix) → Review   [처음 단계로 회귀, 전체 사이클 재수행]
```

Review 실패 시엔 Worker가 고치고 Review로만 돌아간다(Tester는 아직 볼 필요 없는 코드니까). 하지만 **Tester가 실패하면 Worker가 수정한 뒤 처음 단계인 Review로 돌아가 Review→Tester 사이클을 처음부터 다시 밟는다** — 수정이 새 코드 결함을 만들지 않았는지, 그리고 실제로 동작이 고쳐졌는지 둘 다 다시 확인하기 위함. 이 재검증 루프는 Review와 Tester가 모두 통과할 때까지 반복된다.

---

## L (Large)

```text
PM → Worker → Review → (Fail) Worker(fix) → Review
                   → (Pass) Tester → (Pass) Integrator (or Human) → Worker → Feature Audit → Complete
                                  → (Fail) Worker(fix) → Review
```

M과 동일한 분기 규칙: Review 실패 → Worker(fix) → Review; Tester 실패 → Worker(fix) → Review(처음부터 재수행); Tester 통과 → Integrator로 진행.

---

## XL (Extra Large)

Split the review into two independent reviews.

```text
PM → Worker → Review ×2 → (Fail) Worker(fix) → Review ×2
                       → (Pass) Tester → (Pass) Integrator (or Human) → Worker → Feature Audit → Complete
                                      → (Fail) Worker(fix) → Review ×2
```
