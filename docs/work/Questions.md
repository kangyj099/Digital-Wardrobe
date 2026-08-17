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

## 3. 직렬화 매퍼 배치 — 구현됨, **Audit 게이트만 남음**

`lib/data/`의 별도 매퍼로 갔다. 근거와 세부 규칙은 `Decision.md` 최상단 항목 참고.

**아직 확정이 아니다.** Data/Architecture × Decision이라 `Workflow_Project.md` §5가 크기 무관 Audit 게이트를 건다. 코드는 들어갔지만 그 게이트를 안 거쳤으므로 잠정이다.

**Audit이 볼 것**: `lib/data/`와 `lib/services/`의 경계가 실제로 갈라지는지, `00_OwnershipMap.md`에 `lib/data/` 행을 올릴지, `CompositionMapper`가 `tags` 없이 나간 것이 허용 가능한 미완성인지.

---

## 4. ~~Firebase 의존성의 Windows 빌드 리스크~~ — **해소(2026-08-17), 실측함**

`firebase_core` 4.13.0 / `cloud_firestore` 6.8.0을 추가하고 직접 확인했다. **깨지지 않는다.**

- `flutter build windows --debug` 성공(300.6초, 첫 빌드라 Firebase C++ SDK 컴파일 포함). 경고는 LNK4099(SDK 내부 libcurl의 PDB 없음)뿐이고 무해하다.
- `flutter test -d windows`도 정상 작동. `trash_execution_test.dart` 5/5 통과.
- `flutter analyze` 기준선 유지, 유닛테스트 전량 통과. Firebase 초기화 코드를 안 넣었으므로 유닛테스트는 Firebase 앱 없이 돈다.

**남은 것은 `flutterfire configure`뿐이다.** 대화형 로그인을 요구해 사용자가 직접 실행해야 한다(세션에서 `! flutterfire configure`). 이게 `lib/firebase_options.dart`를 만들고, 그게 있어야 `Firebase.initializeApp()`을 붙일 수 있다. 그 전까지 §11(오프라인 로컬퍼스트 초기화)은 착수 불가다.

---

## 5. 착용일 없는 스타일일지의 "그룹" 처리 (Open Question #17 잔여분)

정렬은 "맨 뒤"로 확정됐다. 그룹핑은 안 정했다.

스타일일지 메인에 날짜 그룹 헤더가 생기면 `wornDate`가 null인 항목을 별도 "날짜 없음" 그룹으로 뺄지 정해야 한다. 지금은 표시할 그룹 UI 자체가 없어 정할 근거가 없어 보류했다.

---

(추가 질문 생기면 아래에 이어서 기록)
