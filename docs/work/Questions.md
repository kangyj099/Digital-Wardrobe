<!--> 사용자 부재 중 PM이 자율 진행하면서 판단을 미룬 질문들. 다음 접속 시 여기부터 확인. <-->

# Open Questions (2026-07-29 자율 진행 세션)

## 1. Visual Review 트리거 시점

Group B(다중선택+휴지통) 계획의 Task 13이 "그룹 B 완료 → PM이 Visual Review 트리거"를 요구함(`docs/history/Decision.md` "Group B 완료 시점에 밀려있던 Visual Review 트리거" 항목, `Workflow_Design.md` §2.1). Typography Pass 3 이후 누적된 신규 화면/컴포넌트(Detail 3화면, 분류 드릴다운 캡슐, `GlassToast`/`MultiSelectCheckmark`/휴지통 필터칩 등)가 전부 대상.

**왜 진행 안 했는지**: Visual Review는 타이포그래피/색상/여백/시각적 위계를 판단하는 작업이라(`uiux-design-conventions` 스킬 체크리스트 기준), 스크린샷을 PM이 혼자 보고 통과 판정하는 것보다 사용자가 직접 보고 확인하는 게 이 프로젝트 관례에 맞는다고 판단(과거 Design 마일스톤은 항상 사용자 확인을 거쳤음). 코드 레벨 진행(Task 11/13)은 이 리뷰와 무관하게 계속함.

**다음 세션에서 결정할 것**: Task 11/13까지 마치고 Group B가 완전히 끝나면, Visual Review를 (a) PM이 스크린샷 찍어서 체크리스트로 셀프 진행할지, (b) 사용자가 직접 화면 보고 판정할지 확인 필요. 그 전까지는 Design Tokens를 "provisional" 상태로 유지(`Workflow_Design.md` §2.1).

---

(추가 질문 생기면 아래에 이어서 기록)
