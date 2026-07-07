<!--> 최신 Decision이 위로, 오래된 것이 아래로 가게 작성함<-->

[Decision] Design Workflow 순서 변경 — Hi-Fi Sample 선행 방식으로 전환 (기존 결정 대체)

결정:
- ref_정책_Workflow_Design.md §2 프로세스를 다음으로 변경:
  Brand Guide(방향) → Hi-Fi Sample(3~5화면, Wireframe 겸함) → Visual Review 
  → 사이즈/간격/컬러 조정 → Design Tokens 확정 → Component Library → 나머지 화면
- 기존 "PLACEHOLDER 병행 착수" 결정(Design System/Component Library를 Brand Guide와 
  병행 진행)은 본 결정으로 대체(superseded)

사유:
디자인 수치(사이즈/간격/컬러)는 실제 화면에서 육안 확인 후 픽스해야 한다는 판단.

Impact:
- ref_정책_Workflow_Design.md §2, §5 갱신 필요
- 기존 준비된 Task B(Design System/Component Library placeholder 착수) 보류

---

[Decision] Brand Guide Pass 2 확정 — Colors (T1~T3 실값)

결정:
- Pass 1 Visual Direction(아이보리~베이지 배경 + 블루뉴트럴 + 딥블루그레이) 기반
  Primary/Neutral/Accent 실값 확정
- On-Primary는 순수 흰색(#FFFFFF) 대신 오프화이트 적용 (T2의 흑백 회피 취지를
  Neutral 역할뿐 아니라 On-Primary에도 동일 적용)
- 다크모드 대비(WCAG 4.5:1/3:1) 1차 검증 완료

사유:
P6 "흑백 기피" 원칙을 텍스트/배경 역할 전반에 일관 적용. 별도 예외 규정 없음.

Impact:
Design System Stage 5 T1~T3 실값 확정. Task B(Design System 구축) 착수 조건 일부 충족.

Follow-up:
- T2 Gray 스케일 근사치 → 실제 색상 툴 재보간 필요 (Task B 착수 조건)
- Warning/Accent 등 미검증 대비 쌍 → Task B 진입 전 전수 재검증 필요
- 문서 파일명(Pass1+2 통합) 리네이밍 → Pass 3 완료 후 일괄 정리

---

[Decision] Brand Guide Pass 1 확정 — Essence/Personality/Visual Direction

결정:
- Brand Essence: E2 (자기 이해형 — "입어온 나를 돌아보는 기록")
- Brand Personality: 든든한 개인 기록자 (격식 있는 다정함, 반말/애칭/과한 감탄사 배제)
- Visual Direction: 아이보리~베이지 배경 + 블루뉴트럴, 딥블루그레이로 무게감,
  웜톤/핑크/그린 계열 액센트 배제

사유:
Needs 문서 ②(기억/취향 축)에 무게 실은 Essence 선택. Personality는 P1의
"경로별 표현 강도만 차등, 구조는 미분기" 원칙과 정합되도록 담백함 기반 단일 축 유지.

Impact:
Pass 2(컬러 실값), Pass 3(타이포)의 상위 제약. Design System Stage 5 실값 산정 시 참조.

Follow-up:
- Accent 색상 역할 미정 → Pass 2에서 결정
- 다크모드 대비(WCAG 4.5:1) 검증 → Pass 2 착수 조건
- 팔레트 5종 → 1종 압축 → Pass 2에서 확정

---

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