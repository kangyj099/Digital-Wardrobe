---
name: flutter-implementation-conventions
description: Flutter/Dart implementation conventions for this project — navigation (go_router push/go/pop), state management (Riverpod), widget lifecycle/performance, and testing depth. Invoke before or while writing or reviewing any Flutter/Dart implementation code (Layer=UI/Screen, Stage=Implementation/Frontend), and includes the Flutter-specific Review checklist and Audit checklist.
---

# Flutter Implementation Conventions

Flutter/Dart 구현 단계에서 반복적으로 발생하는 문제(잘못된 네비게이션 방식, 리소스 누수, 상태관리 오용, 접근성 누락)를 미리 방지하기 위한 구현 원칙.

## 이 스킬을 언제 쓰나

Layer=UI/Screen × Stage=Implementation(Frontend) 태스크의 Worker/Review가 구현/리뷰 전에 호출한다.

---

## 네비게이션 원칙 (go_router)

### 핵심 규칙: `push` vs `go`

- **`context.push()`** — 화면을 스택에 쌓아 올린다. 뒤로가기/제스처로 이전 화면 상태 그대로 복귀. **이 프로젝트의 드릴다운·크로스레퍼런스 네비게이션은 전부 이 방식이어야 한다** — `docs/reference/design/00_DesignPrinciples.md`의 P4("상세↔상세 크로스레퍼런스는 백스택 유지가 핵심 차별점")와 P7("컨텍스트 복귀 보장")을 기술적으로 구현하는 수단이 `push`다.
  - 예: 옷장 메인 → 옷 상세, 옷 상세 → 코디 상세, 코디 상세 → 옷 상세(역방향), Add/Create 화면 진입.
- **`context.go()`** — 현재 위치를 교체한다. 뒤로가기가 이전 화면으로 안 돌아갈 수 있다. **상위 카테고리 간 수평 전환에만 사용한다** (예: 헤더 드롭다운으로 옷장/코디/스타일일지 전환 — 드릴다운이 아니라 같은 레벨 이동이므로).
- **`context.pop()`** — Add/Create 화면이 저장/취소 후 원래 화면으로 돌아갈 때. `pushReplacement()`나 `go()`로 대체하지 않는다 — 호출한 화면의 상태(스크롤 위치, 필터 등)를 그대로 보존하기 위해서다(P7).

### AI Constraints

- 드릴다운/상세화면 진입, 크로스레퍼런스 이동에 `context.go()`를 쓰지 않는다 — 항상 `context.push()`.
- 상위 카테고리 전환(드롭다운 등) 외의 목적으로 `context.go()`를 쓰지 않는다.
- Add/Create 화면은 저장 성공 시 `context.pop()`으로 복귀한다.

---

## 상태관리 원칙 (Riverpod)

- `build()`(렌더링 메서드) 안에서는 `ref.watch()`만 사용한다. 콜백(`onPressed`, `onTap` 등) 안에서는 `ref.read()`를 사용한다.
  - `ref.read()`를 `build()`에서 쓰면 상태가 바뀌어도 화면이 갱신되지 않는다.
  - `ref.watch()`를 콜백 안에서 쓰는 것은 의미가 없다(구독은 위젯 리빌드 시점에만 유효).
- `StateNotifier`가 들고 있는 리스트/컬렉션 상태는 항상 **새 리스트로 교체**해서 `state = ...`에 대입한다. 기존 리스트를 in-place로 `add`/`remove`하지 않는다 — 그래야 이 상태를 `watch`하는 화면들이 변경을 감지한다. (여기서 "감지하는 쪽"은 아래 위젯 생명주기 섹션의 "리스너/구독"과는 별개 개념이다 — 그쪽은 직접 만들고 직접 해제해야 하는 `Timer`/`StreamSubscription`/`FocusNode` 등을 가리킨다.)
- Provider끼리 순환 `watch`(A가 B를 watch, B가 A를 watch)를 만들지 않는다.
- 로컬 위젯 상태(텍스트 컨트롤러, 폼 입력값 등)가 필요한 화면만 `ConsumerStatefulWidget`을 쓴다. 필요 없으면 `ConsumerWidget`으로 충분하다.

### 지연 빌드 콜백 안에서 `ref.watch` 금지

`itemBuilder`, `separatorBuilder`, `PageView`/`ListView`/`GridView`/`Sliver` 계열의 자식 빌더 등 프레임 도중 호출되는 지연 빌드 콜백 안에서는 `ref.watch`를 호출하지 않는다. 필요한 값은 그 콜백을 감싸는 `build()`에서 한 번 watch해 평범한 데이터로 전달한다.

다른 provider를 `ref.watch`로 참조하는 파생 provider에는 `.autoDispose`를 부여한다.

같은 판정 로직을 provider와 직접 호출 양쪽에서 써야 하면, 로직 본체를 순수 함수로 두고 provider를 그 함수의 얇은 래퍼로 만든다.

### AI Constraints

- 화면 렌더링 로직에 `ref.read()`를 쓰지 않는다.
- 버튼/제스처 콜백에 `ref.watch()`를 쓰지 않는다.
- 컬렉션 상태를 in-place로 mutate하고 그대로 `state`에 재대입하지 않는다(새 리스트 생성 필수).
- 지연 빌드 콜백 안에서 `ref.watch`/provider 접근을 하지 않는다.

---

## 위젯 생명주기 & 성능 규율

- **컨트롤러·리스너·구독은 반드시 해제한다.** `TextEditingController`, `AnimationController`, 직접 생성한 `ScrollController`/`PageController`, `Timer`(`cancel()`), `StreamSubscription`(`cancel()`), 직접 생성한 `FocusNode` 등 — `State` 클래스에 `dispose()`를 오버라이드해서 해제한다. ("리스너/구독"은 이 목록의 `Timer`/`StreamSubscription`/`FocusNode`처럼 직접 만들고 직접 해제 책임이 있는 것들을 가리킨다.) (`go_router`가 자체 관리하는 컨트롤러나, 파라미터 없이 쓰는 `PageView.builder`처럼 Flutter가 내부적으로 관리하는 것은 예외.)
- `async` 작업 완료 후 `context`를 사용하기 전에는 `if (!mounted) return;`으로 체크한다 (위젯이 이미 dispose된 상태에서 context 사용 시 크래시).
- 가능한 곳엔 `const` 생성자를 쓴다 — 불필요한 리빌드를 줄인다.
- 필터링/정렬로 순서나 구성이 바뀔 수 있는 리스트·그리드 아이템에는 `key: ValueKey(고유id)`를 부여한다 — 없으면 Flutter가 위치 기반으로 위젯을 잘못 재사용해 상태가 꼬일 수 있다.

### AI Constraints

- `State` 클래스에서 직접 생성한 컨트롤러/리스너를 `dispose()` 없이 방치하지 않는다.
- `async` 갭 이후 `mounted` 체크 없이 `context`를 쓰지 않는다.
- 필터/정렬 대상이 되는 리스트 아이템 위젯에 `key`를 생략하지 않는다.

---

## 테스트 깊이 기준

- 화면/시각적 구성 요소 = `flutter run`으로 직접 실행해 눈으로 확인한다 (위젯 단위 TDD를 강제하지 않는다 — 시각 작업은 완성 여부를 코드로 판단하기 어렵다).
- 순수 로직(필터링, 정렬, 데이터 변환 함수 등 위젯이 아닌 것) = `flutter test` 단위 테스트를 작성한다.
- 접근성 계약(Semantics label 등)을 구현하는 재사용 컴포넌트는 최소 1개 위젯 테스트로 Semantics 출력을 검증한다 — 접근성 정보는 눈으로 확인 안 되는 부분이라 별도 검증이 필요하다.
- `Semantics(label: ...)`로 감싼 위젯의 자식이 자체적으로 접근성 정보를 노출하는 위젯(`Text` 등)이면 `excludeSemantics: true`를 함께 지정한다 — 안 그러면 스크린 리더가 부모 label과 자식 label을 이어붙여 중복 발화한다(`StatusBadge`/`SelectableGalleryTile`에서 위젯 테스트로 실제 발견함: `"미완성 상태\n미완성"`처럼 겹쳐 읽힘).

### AI Constraints

- 화면/위젯 코드에 대해 불필요하게 전면적인 widget-test suite를 요구하지 않는다(시간 낭비, 이 프로젝트의 명시적 방침 아님).
- 순수 로직 함수를 작성하고 대응하는 단위 테스트 없이 넘어가지 않는다.
- Semantics label을 정의한 컴포넌트를 검증 없이 넘어가지 않는다.
- `Semantics(label: ...)`의 자식이 텍스트/이미지처럼 자체 접근성 정보를 갖는 위젯이면 `excludeSemantics: true` 없이 넘어가지 않는다.

---

## Review 체크리스트 (Flutter 전용)

아래 Review Area별 Flutter 전용 하위 체크리스트. 각 행의 근거는 "근거" 열에 표기 — 대부분은 `Workflow_Development.md` §4 "Review Areas"의 확장이지만, Accessibility는 §4에 없는 항목이라 별도 근거(§12.1)를 갖는다. 새 행을 추가할 때는 이 열만 채우면 되고, 아래 서두 설명을 매번 고칠 필요는 없다.

| Review Area | Flutter 전용 체크 | 근거 |
| --- | --- | --- |
| Code quality | `const` 생성자 사용 여부, 색상/spacing/타이포 하드코딩 없이 토큰 참조 여부, 리스트 아이템 `key` 부여 여부 | `Workflow_Development.md` §4 |
| Bugs | 컨트롤러 `dispose()` 여부, `async` 갭 이후 `mounted` 체크, `ref.watch`/`ref.read` 올바른 위치 | `Workflow_Development.md` §4 |
| Architecture | `go_router`의 `push`/`go` 올바른 선택(위 네비게이션 원칙), Provider 순환 의존 없음, 지연 빌드 콜백 내 `ref.watch` 없음, 동작 시퀀스 중복(아래 §), 공용 컴포넌트 도입 시 호출부 전수 확인(아래 §), 소유권 맵 준수 여부(위반 시 P1) | `Workflow_Development.md` §4 / 소유권 맵 규칙 본문은 `engineering-principles` |
| UX | 이 프로젝트 Design/Interaction Principles(P4/P7 등, `00_DesignPrinciples.md`)와 일치 여부 | `Workflow_Development.md` §4 |
| Exception handling | 성공/로딩/빈 상태/실패 상태가 스펙대로 구현됐는지(`_공통 규칙.md`의 AI 처리 실패 상태: 지수 백오프 재시도, 실패 팝업 등), 실패 시 사용자에게 재시도 경로가 있는지 | `Workflow_Development.md` §4 |
| Accessibility | Semantics label 존재 및 `excludeSemantics` 처리 여부, 터치 타겟 44×44 이상(A1/A10), 색상 단독으로 의미 전달하지 않는지(A2), 다크모드 대비비(A3) | `Workflow_Project.md` §12.1의 "Development Review **+ spec-compliance check**" — Design 단계(Decision)에서 이미 정해진 접근성 요구사항을 구현이 지켰는지 확인하는 것이며, §4의 기본 Review Areas 확장이 아니다 |

### 동작 시퀀스 중복 (Rule of Three)

동작 시퀀스는 확인·상태변경·화면전환·피드백·되돌리기 중 둘 이상이 정해진 순서로 묶인 절차를 말한다.

- 이번 diff가 같은 동작 시퀀스를 3곳 이상에서 반복하면 공용 함수/핸들러 추출을 P2로 지적한다.
- 이미 3곳 이상 존재하는 시퀀스에 4번째를 추가하면 추출 없는 추가를 P2로 지적한다.
- 공용 셸이 동작의 진입점만 제공하고 절차는 콜백으로 호출부에 위임하면, 절차를 셸이 소유하도록 계약 확대를 P2로 지적한다.

### 같은 수정을 3곳 이상에 복사하면 중단한다

하나의 버그·요구사항에 대해 동일한 형태의 수정이 3개 이상 파일에 필요하면, Worker는 수정을 진행하기 전에 그 사실을 PM에게 보고한다. 통합 여부는 PM이 판단한다.

### 공용 컴포넌트 도입 시 호출부 전수 확인

공용 위젯/헬퍼로 기존 호출부를 대체하는 변경은, 대상 필드/값의 소비 지점을 직접 grep해 남은 호출부가 0인지 확인한 근거를 요구한다. 스펙에 열거된 호출부 목록은 완전하다고 전제하지 않는다. 해당 변경의 테스트 커버리지도 grep 결과를 기준으로 구성한다.

---

## Audit 체크리스트 (Flutter 전용)

`Workflow_Project.md` §2 "Feature Audit"(프로젝트 전체를 홀리스틱하게 훑는 역할, `.claude/agents/audit.md`가 수행)이 Flutter 코드베이스를 볼 때 쓰는 구체적 체크 항목. Feature Audit의 6개 추상 카테고리(Policy conflicts / Missing functionality / Architecture / UX consistency / Design System consistency / Requirements compliance)에 배타적 1:1로 대응시키지 않는다 — 아래 항목 다수가 여러 카테고리에 동시에 걸치기 때문(예: "토큰 우회"는 Policy conflicts이자 Design System consistency, "중복구현"은 Policy conflicts이자 Architecture). Audit이 finding을 적을 때도 해당하는 카테고리를 자유롭게 복수로 태그한다.

- 헤더/뒤로가기/토글 등 공용 크롬이 여러 화면에 각자 따로 구현돼 있는지(`AppMainScaffold` 등 공용 셸을 안 쓰고 화면이 자체 구현을 새로 짰는지)
- 색상/spacing/타이포/radius/motion이 `lib/theme/` 토큰을 거치지 않고 리터럴 값으로 하드코딩됐는지
- 이미 존재하는 공용 위젯(`lib/widgets/`)과 기능이 겹치는 화면 전용 구현이 새로 생겼는지(중복구현)
- 공용 컴포넌트가 원래 의도(예: `OverlayHeader`는 플로팅 오버레이 전용)와 다르게 오용되고 있는지
- 화면 간 인터랙션/레이아웃 패턴이 서로 다른 화면인데도 불일치하게 구현됐는지
- `lib/` 하위 폴더 구조(`theme/models/mock/providers/router/widgets/screens`)가 계속 지켜지고 있는지, 새 파일이 엉뚱한 폴더에 들어갔는지
- 소유권 맵(`docs/reference/architecture/00_OwnershipMap.md`)의 각 행이 실제 코드와 일치하는지 — 소유 파일 존재 여부, 등재 기준인 "둘 이상의 호출부"를 여전히 만족하는지(grep으로 재확인), 맵에 없는 새 크로스커팅 항목이 생겼는지. **이 항목이 맵의 유일한 주기적 검증자다** — Review 단계 점검은 변경 당사자의 자기 점검이라 맵이 코드와 어긋나도 발견되지 않는다.
- `AppMainScaffold`를 써야 하는 화면(`docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 표 기준)이 실제로 그걸 쓰는지, 우회해서 자체 `Scaffold`를 짰는지
