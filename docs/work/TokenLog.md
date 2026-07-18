<!--> PM이 Worker/Review/Tester 스폰 직전과 handoff 수신 직후 `/context`로 확인한 대화 전체 토큰 수치의 근사 기록. Delta는 PM 세션의 컨텍스트 증가분(디스패치 프롬프트 + 반환된 handoff)에 대한 근사치이며, 서브에이전트 자신의 내부 토큰 소모량이 아니다 — 서브에이전트는 별도 컨텍스트 윈도우에서 실행되어 PM이 그 내부 사용량을 직접 관측할 수 없다. 절차: `.claude/policies/Workflow_Project.md` §14.1. <-->

# Token Usage Log

**Status: OFF**

이 줄이 이 로깅 기능 전체(§14.1 토큰 근사치 + §14.2 Read/Edit Stats)의 유일한 on/off 스위치다. 기본값은 OFF(평상시엔 켜두지 않음, 토큰 소모 문제가 의심될 때만 켜는 진단용 도구). `docs/work/AgentStats.md`를 포함해 이 기능에 관여하는 모든 문서/에이전트는 작업 전 이 줄을 확인한다.

- **켜기**: 위 줄을 `**Status: ON**`으로 바꾼다.
- **끄기**: 다시 `**Status: OFF**`로 바꾼다. 기존에 쌓인 로그 행은 지우지 않는다(과거 진단 기록으로 유지).

| Date | Task | Agent | Before (tokens) | After (tokens) | Delta |
| --- | --- | --- | --- | --- | --- |
