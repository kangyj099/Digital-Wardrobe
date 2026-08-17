<!--> 사용자 부재 중 PM이 자율 진행하면서 판단을 미룬 질문들. 다음 접속 시 여기부터 확인. <-->

# Open Questions (2026-07-29 자율 진행 세션)

## 1. Visual Review 트리거 시점

Group B(다중선택+휴지통) 계획의 Task 13이 "그룹 B 완료 → PM이 Visual Review 트리거"를 요구함(`docs/history/Decision.md` "Group B 완료 시점에 밀려있던 Visual Review 트리거" 항목, `Workflow_Design.md` §2.1). Typography Pass 3 이후 누적된 신규 화면/컴포넌트(Detail 3화면, 분류 드릴다운 캡슐, `GlassToast`/`MultiSelectCheckmark`/휴지통 필터칩 등)가 전부 대상.

**왜 진행 안 했는지**: Visual Review는 타이포그래피/색상/여백/시각적 위계를 판단하는 작업이라(`uiux-design-conventions` 스킬 체크리스트 기준), 스크린샷을 PM이 혼자 보고 통과 판정하는 것보다 사용자가 직접 보고 확인하는 게 이 프로젝트 관례에 맞는다고 판단(과거 Design 마일스톤은 항상 사용자 확인을 거쳤음). 코드 레벨 진행(Task 11/13)은 이 리뷰와 무관하게 계속함.

**다음 세션에서 결정할 것**: Task 11/13까지 마치고 Group B가 완전히 끝나면, Visual Review를 (a) PM이 스크린샷 찍어서 체크리스트로 셀프 진행할지, (b) 사용자가 직접 화면 보고 판정할지 확인 필요. 그 전까지는 Design Tokens를 "provisional" 상태로 유지(`Workflow_Design.md` §2.1).

**갱신(2026-07-29 세션 내)**: Task 11/13 둘 다 이 세션에서 완료됨 — Group B(13개 Task)가 이제 완전히 끝났다. 위 질문이 더 이상 "다음에 결정"이 아니라 **지금 바로 결정 가능한 상태**. 다음 접속 시 최우선으로 확인.

---

## 2. 스타일일지 "착용 옷" 슬롯 구조가 스펙과 맞는지

`03_스타일 일지.md` 23-24행 문언은 "착용 옷"(구 "추가 사진")이 스타일일지 열람의 스와이프 카드 슬롯 구조(대표이미지→코디 슬롯)에 포함되는 것처럼 읽히는데, 실제 구현(Task 8, `style_log_viewer_screen.dart`)은 그 스와이프 카드와 별개인 독립 가로 스크롤 섹션으로 구현돼 있다. 문언과 구현 중 뭐가 맞는 의도인지 사용자 확인 필요 — 스펙을 정정할지, 구현을 스와이프 카드 슬롯 구조로 옮길지 결정 필요.

(2026-07-16 2차 Audit에서 처음 발견, BACKLOG.md에 오래 머물러 있던 항목을 이번 Task 13 문서 정리 중 이곳으로 이관)

---

## 3. 직렬화 매퍼를 어디에 둘지 (Phase 2 착수 전 필수)

`toFirestore()`/`fromFirestore()`를 모델 파일 안에 넣을지, 별도 매퍼 파일로 뺄지 정해야 한다.

**별도 파일이 유력하다.** `lib/models/`가 Flutter UI 레이어에 의존하지 않는다는 규칙이 이미 있고(`enums.dart`의 `ArtboardBackgroundColor` 주석, 2026-08-07 Audit이 레이어 위반으로 지적해 확립됨), `cloud_firestore`의 `Timestamp`를 모델에 직접 import하면 같은 종류의 위반이 된다.

**다만 확정 전 Audit이 필수다** — Data/Architecture × Decision이라 `Workflow_Project.md` §5가 크기 무관 Audit 게이트를 건다. 사용자 부재 중 혼자 확정하지 않고 멈춰둔 이유다. `00_OwnershipMap.md` 등재 여부도 함께 판단해야 한다.

---

## 4. Firebase 의존성을 언제 추가할지 (Phase 3, Windows 빌드 리스크)

`firebase_core`/`cloud_firestore`를 `pubspec.yaml`에 넣는 것이 Windows 빌드를 깨뜨릴 수 있다.

이 프로젝트는 Windows가 `integration_test`를 돌릴 수 있는 사실상 유일한 non-web 디바이스다(`BACKLOG.md` Known Issues). FlutterFire의 Windows 지원은 `path_provider` 같은 1st-party 플러그인보다 성숙도가 낮아, 추가 직후 통합테스트 실행 자체가 막히면 검증 수단을 잃는다. `path_provider` 추가 때도 Developer Mode 활성화가 새로 필요해졌던 전례가 있다.

**착수 전 확인할 것**: 별도 브랜치에서 의존성만 추가해 `flutter build windows`와 `flutter test -d windows`가 도는지 먼저 확인하고, 깨지면 Firestore 전환 자체를 Windows 검증이 필요 없는 범위로 다시 잘라야 한다.

`flutterfire configure`가 대화형 로그인을 요구해 사용자가 직접 실행해야 하는 것도 함께 걸려 있다(세션에서 `! flutterfire configure`).

---

## 5. 착용일 없는 스타일일지의 "그룹" 처리 (Open Question #17 잔여분)

정렬은 "맨 뒤"로 확정됐다. 그룹핑은 안 정했다.

스타일일지 메인에 날짜 그룹 헤더가 생기면 `wornDate`가 null인 항목을 별도 "날짜 없음" 그룹으로 뺄지 정해야 한다. 지금은 표시할 그룹 UI 자체가 없어 정할 근거가 없어 보류했다.

---

(추가 질문 생기면 아래에 이어서 기록)
