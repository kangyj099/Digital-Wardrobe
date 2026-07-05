

[Decision] Brand Guide 선행 없이 임시 토큰 값으로 Design System 착수

배경:
Brand Guide 확정 지연으로 Stage 5(Design Tokens) 실값 확보 시점 불투명.

결정:
- Design Tokens 역할 구조(Stage 5)는 유지, 실값 대신 PLACEHOLDER 값으로 Design System/Component Library 선행 진행.
- 모든 컴포넌트는 토큰 역할만 참조(하드코딩 금지). Brand Guide 확정 시 값만 일괄 교체.

사유:
Stage 5 문서에 이미 "역할만 정의, 값은 Brand Guide 대기"로 명시되어 있어 기존 설계 의도와 합치. 새 개념 도입 아님.

Impact:
Design System, Component Library. 화면/기획 문서 변경 없음.

Follow-up:
Brand Guide 확정 시 PLACEHOLDER 값 전수 교체 Task 필요 (TechnicalDebt.md 등록 대상 여부는 별도 확인).