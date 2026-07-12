# 전체 화면 Skeleton (8단계 프로세스 Step①) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **이 프로젝트는 위 스킬 대신 CLAUDE.md의 자체 하네스(PM→Worker→Review→(Tester))로 실행된다.** 각 Task는 Layer=UI/Screen, Stage=Implementation(Frontend)로 태깅되며, Worker→Review 사이클만 돈다 — Tester는 이 Plan 전체에서 생략(근거는 아래 Global Constraints 참고). 이 헤더는 스킬 포맷 요구사항 준수를 위해 유지한다.

**Goal:** `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 표의 13개 화면 중 아직 골격조차 없는 10개 화면에 대해, 컴포넌트 없이 페이지 타입별 레이아웃 리전만 정의한 골격 코드를 만든다. `app_router.dart`의 텍스트 placeholder를 이 골격으로 승격한다. 이미 실구현된 옷장 메인도 §1 표의 Main-그룹형 페이지 타입이 요구하는 리전 중 하나(그룹형 드릴다운 바)가 빠져 있어, 그 리전만 별도로 보강한다(Task B).

**Architecture:** 화면당 파일 하나(`lib/screens/*.dart`), 전부 `StatelessWidget`(아직 상태/데이터 바인딩 없음 — Step⑦ 몫). 리전은 화면마다 반복되는 임시 헬퍼 `skeletonRegion()`(Task A에서 신설, `lib/screens/skeleton_region.dart`)으로 표현 — 라벨이 적힌 테두리 박스 하나가 리전 하나. `lib/router/app_router.dart`의 해당 라우트를 각 Task에서 새 화면으로 교체한다.

**Tech Stack:** Flutter 3.44.4 / Dart 3.12.2, 기존 `lib/theme/app_spacing.dart`(`AppSpacing`)와 `Theme.of(context)`만 참조 — 신규 디자인 토큰 없음.

## Global Constraints

- 옷장 메인(`ClosetMainScreen`)은 이미 실구현 완료 상태라 헤더/본문/뒤로가기/FAB 등 기존 동작에는 손대지 않는다. 단, §1 표의 Main-그룹형 페이지 타입이 요구하는 "그룹형 드릴다운" 리전이 옷장 메인엔 아직 자리조차 없어(계절 드롭다운은 플랫 필터일 뿐, `GroupedMainViewMode` 드릴다운이 아님) Task B에서 그 리전만 보강한다 — 나머지는 그대로 둔다.
- **컴포넌트 금지**: `lib/widgets/`의 기존 컴포넌트(`OverlayHeader`, `GroupedGalleryGrid` 등)도, 신규 컴포넌트도 이 Plan에서는 import하지 않는다. 뒤로가기 버튼/카테고리 토글도 실제 위젯으로 만들지 않는다(전부 Step②/③ 몫) — `skeletonRegion` 라벨 박스로 그 존재만 표시.
- **상호작용 금지**: FAB의 `onPressed`는 전부 `() {}`(no-op). 실제 네비게이션 배선은 Step⑦(기능 구현) 몫.
- **라우트 분리**: 기존 `AppRoute.settingsTrash`('/settings' 하나로 설정+휴지통을 겸용)를 `AppRoute.settingsMain`('/settings', 그대로 유지)과 신규 `AppRoute.trashMain`('/trash')으로 분리한다 — §1 표에서 설정(Utility)과 휴지통(Main-플랫+필터형)은 서로 다른 페이지 타입이라 화면이 다르다.
- **Tester 생략**: `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §4 — "Step①(스켈레톤)은 실동작이 없는 순수 구조 코드라 Tester 불필요(Review만)". 이 Plan의 모든 Task는 Worker→Review만 돌고 끝난다.
- **선택 모달 2종은 이 Plan의 대상이 아니다**: `docs/reference/plan/03_화면별UX명세서/_공통 규칙.md`의 "기능 재사용 원칙"에 따라 별도 화면을 만들지 않고 기존 메인 화면을 모달로 재호출하는 방식이라, 이 Plan에서 만들 새 파일이 없다. Step⑥("나머지 화면 적용")에서 그 시점까지 완성된 옷장/코디/스타일일지 메인 화면에 모달 프레젠테이션을 씌우는 형태로 다룬다 — Step②의 공용 컴포넌트 후보 리스트업 때 "모달 래퍼"도 후보로 포함시킬 것(이 Plan 완료 후 PM이 다음 세션 인계 시 챙긴다).
- 값(spacing/색상)은 전부 `Theme.of(context)` 또는 `AppSpacing` 참조 — 리터럴 hex/px 금지(`engineering-principles` 스킬).

---

### Task A: `skeletonRegion` 헬퍼 + 코디 메인 골격 (Main-그룹형)

**Files:**
- Create: `lib/screens/skeleton_region.dart`
- Create: `lib/screens/composition_main_screen.dart`
- Modify: `lib/router/app_router.dart`

**Interfaces:**
- Produces: `skeletonRegion(BuildContext context, String label, {double? height})` — `double? Widget` 반환(`height`가 주어지면 고정 높이 `Container`, 없으면 `Expanded`로 감싼 `Container`). Task B/C/D/E/F 전부 이 함수를 소비.
- Produces: `CompositionMainScreen` (`StatelessWidget`, 파라미터 없음) — `app_router.dart`가 소비.

- [ ] **Step 1: `lib/screens/skeleton_region.dart` 작성**

```dart
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Step①(전체 화면 Skeleton) 전용 임시 헬퍼 — 레이아웃 리전 자리만 표시한다.
/// Step②(Component Library)가 실제 컴포넌트를 도입하면 이 헬퍼를 참조하는
/// 모든 화면이 교체되며, 이 파일 자체도 은퇴한다.
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §3 참고.
Widget skeletonRegion(BuildContext context, String label, {double? height}) {
  final box = Container(
    width: double.infinity,
    height: height,
    alignment: Alignment.center,
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
  return height == null ? Expanded(child: box) : box;
}
```

- [ ] **Step 2: `lib/screens/composition_main_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Main-그룹형(옷장 메인과 동일 페이지 타입).
/// `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1/§3 참고.
class CompositionMainScreen extends StatelessWidget {
  const CompositionMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (코디 ▾ + 선택 버튼) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(
            context,
            '분류 선택 바 (그룹형 드릴다운) — Step②',
            height: 48,
          ),
          skeletonRegion(context, '코디 갤러리 그리드 (그룹형)'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/router/app_router.dart` 수정 — import 추가 + `compositionMain` 라우트 교체**

파일 상단 import에 추가:

```dart
import '../screens/composition_main_screen.dart';
```

다음 GoRoute를:

```dart
      GoRoute(
        path: AppRoute.compositionMain,
        builder: (context, state) => _placeholder('코디 메인'),
      ),
```

다음으로 교체:

```dart
      GoRoute(
        path: AppRoute.compositionMain,
        builder: (context, state) => const CompositionMainScreen(),
      ),
```

- [ ] **Step 4: 정적 분석 + 실행 확인**

```bash
flutter analyze lib/screens/skeleton_region.dart lib/screens/composition_main_screen.dart lib/router/app_router.dart
```

Expected: `No issues found!`

```bash
flutter run -d windows
```

Expected: 옷장 메인에서 상단 카테고리 드롭다운으로 "코디" 선택 시 코디 메인 골격 화면(테두리 박스 3개 + FAB)이 표시됨, 에러 없음.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/skeleton_region.dart lib/screens/composition_main_screen.dart lib/router/app_router.dart
git commit -m "feat(skeleton): add skeletonRegion helper and composition main skeleton"
```

---

### Task B: 옷장 메인에 그룹형 드릴다운 리전 보강

옷장 메인은 이미 실구현 상태(Task A/C~F의 다른 화면들과 달리 placeholder가 아님)라 이 Task는 신규 화면을 만들지 않는다. 그러나 §1 표의 Main-그룹형 페이지 타입이 요구하는 3개 리전(Header/GroupingBar/Body) 중 "분류 선택 바(그룹형 드릴다운)" 리전이 옷장 메인엔 아예 없다 — 현재 헤더의 계절 드롭다운은 그룹형 드릴다운이 아니라 단순 플랫 필터이고, 그룹형 드릴다운 아키텍처 자체가 이전 세션에서 스코프 밖으로 명시적으로 미뤄졌던 항목이다(`docs/work/옷장메인_재설계_체크리스트.md` 참고). Step③("Main 화면 3개 적용")에서 옷장/코디 메인 둘 다 이 리전에 실제 `AppMainScaffold`의 `groupingBar` 슬롯을 동일하게 연결할 수 있도록, 지금은 Task A의 코디 메인과 똑같은 자리만 예약해둔다. 뒤로가기 버튼/카테고리 드롭다운 등 이미 실동작하는 다른 부분은 건드리지 않는다 — 그건 Step③에서 `AppMainScaffold`로 정식 교체할 몫이다.

**Files:**
- Modify: `lib/screens/closet_main_screen.dart`

**Interfaces:**
- Consumes: `skeletonRegion` (Task A)

- [ ] **Step 1: `lib/screens/closet_main_screen.dart`에 리전 삽입**

파일 상단 import에 추가:

```dart
import 'skeleton_region.dart';
```

`OverlayHeader(...)`와 그 다음 `Expanded(child: ShaderMask(...))` 사이에 다음을 삽입(현재 `Column`의 두 번째와 세 번째 child 사이):

```dart
                OverlayHeader(
                  actions: [
                    TextButton(onPressed: () {}, child: const Text('선택')),
                  ],
                  child: Row(
                    // ...기존 내용 그대로...
                  ),
                ),
                skeletonRegion(
                  context,
                  '분류 선택 바 (그룹형 드릴다운) — Step②에서 AppMainScaffold groupingBar 슬롯으로 대체 예정',
                  height: 48,
                ),
                Expanded(
                  child: ShaderMask(
                    // ...기존 내용 그대로...
```

(`OverlayHeader`와 `Expanded` 블록 자체의 내용은 수정하지 않는다 — 그 사이에 새 `skeletonRegion(...)` 호출 한 줄만 `Column`의 children 리스트에 추가한다.)

- [ ] **Step 2: 정적 분석 + 회귀 테스트**

```bash
flutter analyze lib/screens/closet_main_screen.dart
```

Expected: `No issues found!`

```bash
flutter test integration_test/closet_main_screen_test.dart -d windows
```

Expected: 기존 22개 전부 Pass — 새 리전은 순수 추가(insertion)라 기존 위젯 파인더/동작에 영향 없어야 한다.

```bash
flutter run -d windows
```

Expected: 옷장 메인 진입 시 헤더 바로 아래 "분류 선택 바 (그룹형 드릴다운)..." 라벨 박스가 보이고, 기존 계절 필터/밀도토글/정렬아이콘/FAB/뒤로가기는 전부 그대로 동작.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/closet_main_screen.dart
git commit -m "feat(skeleton): reserve grouped-drilldown region in closet main screen"
```

---

### Task C: 스타일일지 메인 + 휴지통 골격 (Main-플랫+필터형) + 라우트 분리

**Files:**
- Create: `lib/screens/style_log_main_screen.dart`
- Create: `lib/screens/trash_main_screen.dart`
- Modify: `lib/router/app_router.dart`

**Interfaces:**
- Consumes: `skeletonRegion` (Task A)
- Produces: `StyleLogMainScreen`, `TrashMainScreen` (둘 다 `StatelessWidget`, 파라미터 없음) — `app_router.dart`가 소비.
- Produces: `AppRoute.settingsMain`('/settings'), `AppRoute.trashMain`('/trash') — 기존 `AppRoute.settingsTrash`를 대체. Task F가 `settingsMain`을 소비.

- [ ] **Step 1: `lib/screens/style_log_main_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Main-플랫+필터형 — 그룹 드릴다운 없음(기존
/// 스펙대로 필터 칩만). `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §1 참고.
class StyleLogMainScreen extends StatelessWidget {
  const StyleLogMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (스타일 일지 ▾ + 필터 칩) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(context, '스타일일지 갤러리 (플랫 + 필터, 그룹 드릴다운 없음)'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/screens/trash_main_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Main-플랫+필터형, [+] 버튼 없음(휴지통은
/// 추가 개념이 없는 화면 — `00_페이지 타입 정의.md` 참고).
class TrashMainScreen extends StatelessWidget {
  const TrashMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (휴지통 + 비우기 버튼, 파괴적 액션이라 강한 확인 모달 필요) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(
            context,
            '휴지통 썸네일 그리드 (제목 없이 이미지 중심, 유형 배지 + 잔여일수 오버레이)',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/router/app_router.dart` 수정 — 라우트 상수 분리 + import 추가 + 3개 라우트 교체**

`AppRoute` 클래스에서:

```dart
  static const settingsTrash = '/settings';
```

를 다음으로 교체:

```dart
  static const settingsMain = '/settings';
  static const trashMain = '/trash';
```

파일 상단 import에 추가:

```dart
import '../screens/style_log_main_screen.dart';
import '../screens/trash_main_screen.dart';
```

다음 GoRoute를:

```dart
      GoRoute(
        path: AppRoute.styleLogMain,
        builder: (context, state) => _placeholder('스타일일지 메인'),
      ),
```

다음으로 교체:

```dart
      GoRoute(
        path: AppRoute.styleLogMain,
        builder: (context, state) => const StyleLogMainScreen(),
      ),
```

다음 GoRoute를(설정 라우트, placeholder 라벨은 그대로 두고 상수 이름만 갱신 — 실제 화면 교체는 Task F):

```dart
      GoRoute(
        path: AppRoute.settingsTrash,
        builder: (context, state) => _placeholder('설정/휴지통'),
      ),
```

다음으로 교체:

```dart
      GoRoute(
        path: AppRoute.settingsMain,
        builder: (context, state) => _placeholder('설정'),
      ),
      GoRoute(
        path: AppRoute.trashMain,
        builder: (context, state) => const TrashMainScreen(),
      ),
```

- [ ] **Step 4: 정적 분석 + 실행 확인**

```bash
flutter analyze lib/screens/style_log_main_screen.dart lib/screens/trash_main_screen.dart lib/router/app_router.dart
```

Expected: `No issues found!`

```bash
flutter run -d windows
```

Expected: 옷장 메인 카테고리 드롭다운에 "스타일 일지" 선택 시 스타일일지 메인 골격이 표시됨. `/trash`, `/settings`는 아직 이 화면 그래프에서 진입 UI가 없으므로(추후 Step③ 나비게이션 배선 몫) 코드 리뷰로 라우트 등록만 확인.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/style_log_main_screen.dart lib/screens/trash_main_screen.dart lib/router/app_router.dart
git commit -m "feat(skeleton): split settings/trash routes, add style-log main and trash skeletons"
```

---

### Task D: 상세 화면 3종 골격 (Detail)

**Files:**
- Create: `lib/screens/closet_item_detail_screen.dart`
- Create: `lib/screens/composition_detail_screen.dart`
- Create: `lib/screens/style_log_viewer_screen.dart`
- Modify: `lib/router/app_router.dart`

**Interfaces:**
- Consumes: `skeletonRegion` (Task A)
- Produces: `ClosetItemDetailScreen({required String itemId})`, `CompositionDetailScreen({required String compositionId})`, `StyleLogViewerScreen({required String styleLogId})` — 전부 `StatelessWidget`. `app_router.dart`가 소비.

- [ ] **Step 1: `lib/screens/closet_item_detail_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Detail형 — 공용 네비게이션(헤더 드롭다운 +
/// 뒤로가기)은 Step②/③에서 AppMainScaffold로 대체될 예정이라 리전만 표시한다.
class ClosetItemDetailScreen extends StatelessWidget {
  const ClosetItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (옷장 ▾ + ⋯메뉴) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(
            context,
            '옷 상세 정보 (id: $itemId) — 이미지/메타데이터/착용 이력',
          ),
          skeletonRegion(
            context,
            '상호 참조 링크 (연결된 코디/스타일일지)',
            height: 64,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/screens/composition_detail_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Detail형.
class CompositionDetailScreen extends StatelessWidget {
  const CompositionDetailScreen({super.key, required this.compositionId});

  final String compositionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (코디 ▾ + ⋯메뉴) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(
            context,
            '코디 상세 (id: $compositionId) — 아트보드 스냅샷 + 사용된 옷 목록',
          ),
          skeletonRegion(
            context,
            '상호 참조 링크 (연결된 스타일일지)',
            height: 64,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/screens/style_log_viewer_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Detail형.
class StyleLogViewerScreen extends StatelessWidget {
  const StyleLogViewerScreen({super.key, required this.styleLogId});

  final String styleLogId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (스타일 일지 ▾ + ⋯메뉴) — Step②에서 AppMainScaffold로 대체 예정',
            height: 56,
          ),
          skeletonRegion(
            context,
            '스타일일지 카드 (id: $styleLogId) — 대표→코디→추가사진 슬라이드 + 날짜/장소',
          ),
          skeletonRegion(
            context,
            '상호 참조 링크 (연결된 코디)',
            height: 64,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: `lib/router/app_router.dart` 수정 — import 추가 + 3개 라우트 교체**

파일 상단 import에 추가:

```dart
import '../screens/closet_item_detail_screen.dart';
import '../screens/composition_detail_screen.dart';
import '../screens/style_log_viewer_screen.dart';
```

다음 3개 GoRoute를:

```dart
      GoRoute(
        path: AppRoute.closetItemDetail,
        builder: (context, state) => _placeholder('옷 상세 ${state.pathParameters['id']}'),
      ),
```

```dart
      GoRoute(
        path: AppRoute.compositionDetail,
        builder: (context, state) => _placeholder('코디 상세 ${state.pathParameters['id']}'),
      ),
```

```dart
      GoRoute(
        path: AppRoute.styleLogViewer,
        builder: (context, state) => _placeholder('스타일일지 열람 ${state.pathParameters['id']}'),
      ),
```

각각 다음으로 교체:

```dart
      GoRoute(
        path: AppRoute.closetItemDetail,
        builder: (context, state) =>
            ClosetItemDetailScreen(itemId: state.pathParameters['id']!),
      ),
```

```dart
      GoRoute(
        path: AppRoute.compositionDetail,
        builder: (context, state) =>
            CompositionDetailScreen(compositionId: state.pathParameters['id']!),
      ),
```

```dart
      GoRoute(
        path: AppRoute.styleLogViewer,
        builder: (context, state) =>
            StyleLogViewerScreen(styleLogId: state.pathParameters['id']!),
      ),
```

- [ ] **Step 5: 정적 분석 + 실행 확인**

```bash
flutter analyze lib/screens/closet_item_detail_screen.dart lib/screens/composition_detail_screen.dart lib/screens/style_log_viewer_screen.dart lib/router/app_router.dart
```

Expected: `No issues found!`

```bash
flutter run -d windows
```

Expected: 옷장 메인에서 아무 옷 타일 탭 → 옷 상세 골격 화면(id가 텍스트에 표시됨) 진입, 에러 없음. `기존 integration_test/closet_main_screen_test.dart`가 옷 상세 진입을 전제로 하므로 회귀도 함께 확인:

```bash
flutter test integration_test/closet_main_screen_test.dart -d windows
```

Expected: 기존 통과 건수 그대로 전부 Pass(신규 텍스트 라벨이 기존 위젯 파인더와 충돌하지 않는지 확인).

- [ ] **Step 6: Commit**

```bash
git add lib/screens/closet_item_detail_screen.dart lib/screens/composition_detail_screen.dart lib/screens/style_log_viewer_screen.dart lib/router/app_router.dart
git commit -m "feat(skeleton): add detail screen skeletons for closet/composition/style-log"
```

---

### Task E: Add/Create 화면 3종 골격

**Files:**
- Create: `lib/screens/closet_add_screen.dart`
- Create: `lib/screens/composition_editor_screen.dart`
- Create: `lib/screens/style_log_add_screen.dart`
- Modify: `lib/router/app_router.dart`

**Interfaces:**
- Consumes: `skeletonRegion` (Task A)
- Produces: `ClosetAddScreen`, `CompositionEditorScreen`, `StyleLogAddScreen` (전부 `StatelessWidget`, 파라미터 없음) — `app_router.dart`가 소비.

- [ ] **Step 1: `lib/screens/closet_add_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Add/Create형 — 뒤로가기 없음(자체 취소
/// 버튼이 대체), 카테고리 토글 없음. AppMainScaffold를 아예 쓰지 않는 화면군이라
/// Step②/③ 이후에도 자체 헤더를 유지한다.
class ClosetAddScreen extends StatelessWidget {
  const ClosetAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (취소 버튼 + "?" 코치마크 도움말)',
            height: 56,
          ),
          skeletonRegion(
            context,
            '이미지 촬영/업로드 + AI 배경제거·자동태깅 진행 상태 + 메타데이터 폼',
          ),
          skeletonRegion(
            context,
            '저장 버튼 (상시 저장 원칙 — 진입 즉시 레코드 생성, 위치는 화면 구조에 따라 다름)',
            height: 56,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/screens/composition_editor_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Add/Create형. 드래그/회전/z-index 제스처는
/// 스코프 밖(Global Constraints) — 정적 배치만 표시.
class CompositionEditorScreen extends StatelessWidget {
  const CompositionEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (취소 버튼 + "?" 코치마크 도움말)',
            height: 56,
          ),
          skeletonRegion(
            context,
            '코디 아트보드 (정적 배치만 — 드래그/회전/z-index는 스코프 밖)',
          ),
          skeletonRegion(
            context,
            '저장 버튼 (상시 저장 원칙 — 진입 즉시 레코드 생성)',
            height: 56,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/screens/style_log_add_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Add/Create형.
class StyleLogAddScreen extends StatelessWidget {
  const StyleLogAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (취소 버튼 + "?" 코치마크 도움말)',
            height: 56,
          ),
          skeletonRegion(
            context,
            '슬롯 카드 입력 (대표 이미지 → 코디 연결 → 추가 사진, 좌우 스와이프)',
          ),
          skeletonRegion(
            context,
            '저장 버튼 (상시 저장 원칙 — 진입 즉시 레코드 생성)',
            height: 56,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: `lib/router/app_router.dart` 수정 — import 추가 + 3개 라우트 교체**

파일 상단 import에 추가:

```dart
import '../screens/closet_add_screen.dart';
import '../screens/composition_editor_screen.dart';
import '../screens/style_log_add_screen.dart';
```

다음 3개 GoRoute를:

```dart
      GoRoute(
        path: AppRoute.closetAdd,
        builder: (context, state) => _placeholder('옷 추가하기'),
      ),
```

```dart
      GoRoute(
        path: AppRoute.compositionEditor,
        builder: (context, state) => _placeholder('코디 만들기'),
      ),
```

```dart
      GoRoute(
        path: AppRoute.styleLogAdd,
        builder: (context, state) => _placeholder('스타일일지 추가'),
      ),
```

각각 다음으로 교체:

```dart
      GoRoute(
        path: AppRoute.closetAdd,
        builder: (context, state) => const ClosetAddScreen(),
      ),
```

```dart
      GoRoute(
        path: AppRoute.compositionEditor,
        builder: (context, state) => const CompositionEditorScreen(),
      ),
```

```dart
      GoRoute(
        path: AppRoute.styleLogAdd,
        builder: (context, state) => const StyleLogAddScreen(),
      ),
```

- [ ] **Step 5: 정적 분석 + 실행 확인**

```bash
flutter analyze lib/screens/closet_add_screen.dart lib/screens/composition_editor_screen.dart lib/screens/style_log_add_screen.dart lib/router/app_router.dart
```

Expected: `No issues found!`

```bash
flutter run -d windows
```

Expected: 옷장 메인 FAB → "한 장 추가하기"/"여러 장 추가하기" 탭 → 옷 추가하기 골격 화면 진입, 에러 없음.

```bash
flutter test integration_test/closet_main_screen_test.dart -d windows
```

Expected: 기존 통과 건수 그대로 전부 Pass.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/closet_add_screen.dart lib/screens/composition_editor_screen.dart lib/screens/style_log_add_screen.dart lib/router/app_router.dart
git commit -m "feat(skeleton): add add/create screen skeletons for closet/composition/style-log"
```

---

### Task F: 설정 화면 골격 (Utility)

**Files:**
- Create: `lib/screens/settings_screen.dart`
- Modify: `lib/router/app_router.dart`

**Interfaces:**
- Consumes: `skeletonRegion` (Task A), `AppRoute.settingsMain` (Task C)
- Produces: `SettingsScreen` (`StatelessWidget`, 파라미터 없음) — `app_router.dart`가 소비.

- [ ] **Step 1: `lib/screens/settings_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'skeleton_region.dart';

/// Step①(전체 화면 Skeleton) 산출물. Utility형 — 카테고리 토글 없음.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          skeletonRegion(
            context,
            '헤더 (설정) — Step②에서 AppMainScaffold로 대체 예정(카테고리 토글은 미노출)',
            height: 56,
          ),
          skeletonRegion(
            context,
            '리스트-로우 (토글/체브론), 파괴적 액션은 스와이프 또는 별도 확인 절차로 한 단계 더 진입',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/router/app_router.dart` 수정 — import 추가 + `settingsMain` 라우트 교체**

파일 상단 import에 추가:

```dart
import '../screens/settings_screen.dart';
```

다음 GoRoute를(Task C가 만든 상태):

```dart
      GoRoute(
        path: AppRoute.settingsMain,
        builder: (context, state) => _placeholder('설정'),
      ),
```

다음으로 교체:

```dart
      GoRoute(
        path: AppRoute.settingsMain,
        builder: (context, state) => const SettingsScreen(),
      ),
```

- [ ] **Step 3: 정적 분석 + 실행 확인**

```bash
flutter analyze lib/screens/settings_screen.dart lib/router/app_router.dart
```

Expected: `No issues found!`

```bash
flutter run -d windows
```

Expected: 앱 전체가 여전히 에러 없이 실행됨(설정 화면은 아직 진입 UI가 없으므로 코드 리뷰로 라우트 등록만 확인).

```bash
flutter analyze
```

Expected: `No issues found!` (프로젝트 전체 — 이 Plan의 마지막 Task이므로 전체 정합성 확인)

- [ ] **Step 4: Commit**

```bash
git add lib/screens/settings_screen.dart lib/router/app_router.dart
git commit -m "feat(skeleton): add settings screen skeleton"
```

---

## Self-Review

- **스펙 커버리지**: §1 표 13행 — 옷장 메인(기존 실구현, Task B에서 누락 리전만 보강) 1 + Task A/C~F가 만드는 10개 신규 화면 + 선택 모달 2행(Global Constraints에서 "이 Plan 대상 아님, Step⑥ 몫"으로 명시) = 13행 전부 처리 경로가 있음.
- **Placeholder 스캔**: 전 Task 코드 블록에 TBD/TODO 없음, 모든 `Modify` Step에 정확한 before/after 코드 명시.
- **타입 일관성**: `ClosetItemDetailScreen.itemId`/`CompositionDetailScreen.compositionId`/`StyleLogViewerScreen.styleLogId`는 각각 라우트 정의(`AppRoute.closetItemDetail` 등)의 `:id` 파라미터와 Task D Step 4에서 `state.pathParameters['id']!`로 정확히 대응. `skeletonRegion` 시그니처는 Task A에서 한 번만 정의되고 이후 모든 Task(B 포함)가 동일 시그니처로 소비.
