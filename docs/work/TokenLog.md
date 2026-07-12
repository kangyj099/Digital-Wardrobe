<!--> PM이 Worker/Review/Tester 스폰 직전과 handoff 수신 직후 `/context`로 확인한 대화 전체 토큰 수치의 근사 기록. Delta는 PM 세션의 컨텍스트 증가분(디스패치 프롬프트 + 반환된 handoff)에 대한 근사치이며, 서브에이전트 자신의 내부 토큰 소모량이 아니다 — 서브에이전트는 별도 컨텍스트 윈도우에서 실행되어 PM이 그 내부 사용량을 직접 관측할 수 없다. 절차: `.claude/policies/Workflow_Project.md` §14.1. <-->

# Token Usage Log

| Date | Task | Agent | Before (tokens) | After (tokens) | Delta |
| --- | --- | --- | --- | --- | --- |
