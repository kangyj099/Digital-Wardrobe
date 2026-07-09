> Version 1.1
> Purpose: Flutter/Dart 구현 단계에서 반복적으로 발생하는 문제(하드코딩, 잘못된 네비게이션 방식, 리소스 누수, 상태관리 오용)를 미리 방지하기 위한 프론트엔드 구현 원칙. `Workflow_Development.md`(역할/프로세스, 기술 스택 무관)를 대체하지 않고 보완한다. 재사용 가능한 구현 원칙 본문은 `flutter-implementation-conventions` 스킬로 이전됨 — 이 문서는 스코프/흐름만 남김.

---

# Frontend Workflow (Flutter/Dart)

# 1. 목적 및 스코프

`Workflow_Design.md` 핵심 운영 원칙 8번("Always consider Flutter implementation feasibility")을 구체적으로 실행하는 문서다.

- `Workflow_Development.md`: 역할(PM/Worker/Review), 핸드오프, 태스크 사이징 — 기술 스택 무관, 범용.
- `Workflow_Design.md`: 디자인 시스템 거버넌스(UX/Interaction/Layout/Token/Component 레이어 경계).
- **`Workflow_Frontend.md`(이 문서)**: 위 두 문서가 다루지 않는, Flutter/Dart 구현 그 자체의 반복적 함정과 원칙.

Worker/Review 모두 Layer=UI/Screen × Stage=Implementation(Frontend) 태스크를 맡을 때 이 문서를 참조한다 (`Workflow_Project.md` §12.1 Required Materials에 반영됨).

Flutter/Dart 구현을 작성하거나 리뷰하기 전, `flutter-implementation-conventions` 스킬(`.claude/skills/flutter-implementation-conventions/SKILL.md`)을 호출한다 — 네비게이션·상태관리·위젯 생명주기·테스트 깊이 원칙과 Flutter 전용 Review 체크리스트가 이 스킬에 있다.

이 프로젝트의 하드코딩 위반 사례가 최초로 발견된 지점도 프론트엔드 구현이다 — `engineering-principles` 스킬(`.claude/skills/engineering-principles/SKILL.md`)도 함께 호출한다.

---

# 2. 네비게이션 원칙 (go_router)

`flutter-implementation-conventions` 스킬 참고 (§ 네비게이션 원칙).

---

# 3. 상태관리 원칙 (Riverpod)

`flutter-implementation-conventions` 스킬 참고 (§ 상태관리 원칙).

---

# 4. 위젯 생명주기 & 성능 규율

`flutter-implementation-conventions` 스킬 참고 (§ 위젯 생명주기 & 성능 규율).

---

# 5. 테스트 깊이 기준

`flutter-implementation-conventions` 스킬 참고 (§ 테스트 깊이 기준).

---

# 6. Review 체크리스트 연결

`flutter-implementation-conventions` 스킬 참고 (§ Review 체크리스트).

---

# 7. 참고: 커뮤니티에서 검증된 보조 도구

아래는 `flutter-implementation-conventions` 스킬의 원칙을 강제/보조하기 위해 나중에 도입을 검토할 수 있는 도구들이다 (이번 스프린트 범위 밖, 착수 조건이 갖춰지면 별도 태스크로):

- `very_good_analysis` 린트 프리셋 — `flutter_lints`보다 엄격, 구조적으로 지저분한 위젯 트리 패턴을 자동 검출.
- `.claude/commands/design-review` 커스텀 슬래시 커맨드 — 완성된 화면 위젯 트리 + 디자인 시스템 + 레퍼런스 스크린샷을 대조해 자체 비판하는 리뷰 스텝.
