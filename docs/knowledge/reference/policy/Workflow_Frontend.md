> Version 1.0
> Purpose: Flutter/Dart 구현 단계에서 반복적으로 발생하는 문제(하드코딩, 잘못된 네비게이션 방식, 리소스 누수, 상태관리 오용)를 미리 방지하기 위한 프론트엔드 구현 원칙. `Workflow_Development.md`(역할/프로세스, 기술 스택 무관)를 대체하지 않고 보완한다.

---

# Frontend Workflow (Flutter/Dart)

# 1. 목적 및 스코프

`Workflow_Design.md` 핵심 운영 원칙 8번("Always consider Flutter implementation feasibility")을 구체적으로 실행하는 문서다.

- `Workflow_Development.md`: 역할(PM/Worker/Review), 핸드오프, 태스크 사이징 — 기술 스택 무관, 범용.
- `Workflow_Design.md`: 디자인 시스템 거버넌스(UX/Interaction/Layout/Token/Component 레이어 경계).
- **`Workflow_Frontend.md`(이 문서)**: 위 두 문서가 다루지 않는, Flutter/Dart 구현 그 자체의 반복적 함정과 원칙.

Worker/Review 모두 Layer=UI/Screen × Stage=Implementation(Frontend) 태스크를 맡을 때 이 문서를 참조한다 (`Workflow_Project.md` §12.1 Required Materials에 반영됨).

값 하드코딩 금지 원칙은 `Workflow_Development.md` §1 "Hardcoding Policy (No Magic Values)" 참고.

---

# 2. 네비게이션 원칙 (go_router)

## 핵심 규칙: `push` vs `go`

- **`context.push()`** — 화면을 스택에 쌓아 올린다. 뒤로가기/제스처로 이전 화면 상태 그대로 복귀. **이 프로젝트의 드릴다운·크로스레퍼런스 네비게이션은 전부 이 방식이어야 한다** — `docs/knowledge/reference/design/00_DesignPrinciples.md`의 P4("상세↔상세 크로스레퍼런스는 백스택 유지가 핵심 차별점")와 P7("컨텍스트 복귀 보장")을 기술적으로 구현하는 수단이 `push`다.
  - 예: 옷장 메인 → 옷 상세, 옷 상세 → 코디 상세, 코디 상세 → 옷 상세(역방향), Add/Create 화면 진입.
- **`context.go()`** — 현재 위치를 교체한다. 뒤로가기가 이전 화면으로 안 돌아갈 수 있다. **상위 카테고리 간 수평 전환에만 사용한다** (예: 헤더 드롭다운으로 옷장/코디/스타일일지 전환 — 드릴다운이 아니라 같은 레벨 이동이므로).
- **`context.pop()`** — Add/Create 화면이 저장/취소 후 원래 화면으로 돌아갈 때. `pushReplacement()`나 `go()`로 대체하지 않는다 — 호출한 화면의 상태(스크롤 위치, 필터 등)를 그대로 보존하기 위해서다(P7).

## AI Constraints

- 드릴다운/상세화면 진입, 크로스레퍼런스 이동에 `context.go()`를 쓰지 않는다 — 항상 `context.push()`.
- 상위 카테고리 전환(드롭다운 등) 외의 목적으로 `context.go()`를 쓰지 않는다.
- Add/Create 화면은 저장 성공 시 `context.pop()`으로 복귀한다.

---

# 3. 상태관리 원칙 (Riverpod)

- `build()`(렌더링 메서드) 안에서는 `ref.watch()`만 사용한다. 콜백(`onPressed`, `onTap` 등) 안에서는 `ref.read()`를 사용한다.
  - `ref.read()`를 `build()`에서 쓰면 상태가 바뀌어도 화면이 갱신되지 않는다.
  - `ref.watch()`를 콜백 안에서 쓰는 것은 의미가 없다(구독은 위젯 리빌드 시점에만 유효).
- `StateNotifier`가 들고 있는 리스트/컬렉션 상태는 항상 **새 리스트로 교체**해서 `state = ...`에 대입한다. 기존 리스트를 in-place로 `add`/`remove`하지 않는다 — 그래야 이 상태를 `watch`하는 화면들이 변경을 감지한다. (여기서 "감지하는 쪽"은 §4의 "리스너/구독"과는 별개 개념이다 — §4는 직접 만들고 직접 해제해야 하는 `Timer`/`StreamSubscription`/`FocusNode` 등을 가리킨다.)
- Provider끼리 순환 `watch`(A가 B를 watch, B가 A를 watch)를 만들지 않는다.
- 로컬 위젯 상태(텍스트 컨트롤러, 폼 입력값 등)가 필요한 화면만 `ConsumerStatefulWidget`을 쓴다. 필요 없으면 `ConsumerWidget`으로 충분하다.

## AI Constraints

- 화면 렌더링 로직에 `ref.read()`를 쓰지 않는다.
- 버튼/제스처 콜백에 `ref.watch()`를 쓰지 않는다.
- 컬렉션 상태를 in-place로 mutate하고 그대로 `state`에 재대입하지 않는다(새 리스트 생성 필수).

---

# 4. 위젯 생명주기 & 성능 규율

- **컨트롤러·리스너·구독은 반드시 해제한다.** `TextEditingController`, `AnimationController`, 직접 생성한 `ScrollController`/`PageController`, `Timer`(`cancel()`), `StreamSubscription`(`cancel()`), 직접 생성한 `FocusNode` 등 — `State` 클래스에 `dispose()`를 오버라이드해서 해제한다. ("리스너/구독"은 이 목록의 `Timer`/`StreamSubscription`/`FocusNode`처럼 직접 만들고 직접 해제 책임이 있는 것들을 가리킨다.) (`go_router`가 자체 관리하는 컨트롤러나, 파라미터 없이 쓰는 `PageView.builder`처럼 Flutter가 내부적으로 관리하는 것은 예외.)
- `async` 작업 완료 후 `context`를 사용하기 전에는 `if (!mounted) return;`으로 체크한다 (위젯이 이미 dispose된 상태에서 context 사용 시 크래시).
- 가능한 곳엔 `const` 생성자를 쓴다 — 불필요한 리빌드를 줄인다.
- 필터링/정렬로 순서나 구성이 바뀔 수 있는 리스트·그리드 아이템에는 `key: ValueKey(고유id)`를 부여한다 — 없으면 Flutter가 위치 기반으로 위젯을 잘못 재사용해 상태가 꼬일 수 있다.

## AI Constraints

- `State` 클래스에서 직접 생성한 컨트롤러/리스너를 `dispose()` 없이 방치하지 않는다.
- `async` 갭 이후 `mounted` 체크 없이 `context`를 쓰지 않는다.
- 필터/정렬 대상이 되는 리스트 아이템 위젯에 `key`를 생략하지 않는다.

---

# 5. 테스트 깊이 기준

- 화면/시각적 구성 요소 = `flutter run`으로 직접 실행해 눈으로 확인한다 (위젯 단위 TDD를 강제하지 않는다 — 시각 작업은 완성 여부를 코드로 판단하기 어렵다).
- 순수 로직(필터링, 정렬, 데이터 변환 함수 등 위젯이 아닌 것) = `flutter test` 단위 테스트를 작성한다.
- 접근성 계약(Semantics label 등)을 구현하는 재사용 컴포넌트는 최소 1개 위젯 테스트로 Semantics 출력을 검증한다 — 접근성 정보는 눈으로 확인 안 되는 부분이라 별도 검증이 필요하다.
- `Semantics(label: ...)`로 감싼 위젯의 자식이 자체적으로 접근성 정보를 노출하는 위젯(`Text` 등)이면 `excludeSemantics: true`를 함께 지정한다 — 안 그러면 스크린 리더가 부모 label과 자식 label을 이어붙여 중복 발화한다(`StatusBadge`/`SelectableGalleryTile`에서 위젯 테스트로 실제 발견함: `"미완성 상태\n미완성"`처럼 겹쳐 읽힘).

## AI Constraints

- 화면/위젯 코드에 대해 불필요하게 전면적인 widget-test suite를 요구하지 않는다(시간 낭비, 이 프로젝트의 명시적 방침 아님).
- 순수 로직 함수를 작성하고 대응하는 단위 테스트 없이 넘어가지 않는다.
- Semantics label을 정의한 컴포넌트를 검증 없이 넘어가지 않는다.
- `Semantics(label: ...)`의 자식이 텍스트/이미지처럼 자체 접근성 정보를 갖는 위젯이면 `excludeSemantics: true` 없이 넘어가지 않는다.

---

# 6. Review 체크리스트 연결

`Workflow_Development.md` §4 Review의 "Review Areas"에 아래 Flutter 전용 하위 체크리스트를 추가한다 (별도 역할을 만들지 않고, 기존 Review 역할의 체크리스트를 확장):

| Review Area | Flutter 전용 체크 |
| --- | --- |
| Code quality | `const` 생성자 사용 여부, 색상/spacing/타이포 하드코딩 없이 토큰 참조 여부, 리스트 아이템 `key` 부여 여부 |
| Bugs | 컨트롤러 `dispose()` 여부, `async` 갭 이후 `mounted` 체크, `ref.watch`/`ref.read` 올바른 위치 |
| Architecture | `go_router`의 `push`/`go` 올바른 선택(§2), Provider 순환 의존 없음 |
| UX | 이 프로젝트 Design/Interaction Principles(P4/P7 등, `00_DesignPrinciples.md`)와 일치 여부 |

---

# 7. 참고: 커뮤니티에서 검증된 보조 도구

아래는 이 문서의 원칙을 강제/보조하기 위해 나중에 도입을 검토할 수 있는 도구들이다 (이번 스프린트 범위 밖, 착수 조건이 갖춰지면 별도 태스크로):

- `very_good_analysis` 린트 프리셋 — `flutter_lints`보다 엄격, 구조적으로 지저분한 위젯 트리 패턴을 자동 검출.
- `.claude/commands/design-review` 커스텀 슬래시 커맨드 — 완성된 화면 위젯 트리 + 디자인 시스템 + 레퍼런스 스크린샷을 대조해 자체 비판하는 리뷰 스텝.
