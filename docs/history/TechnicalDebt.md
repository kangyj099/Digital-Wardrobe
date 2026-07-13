<!--> 최신 Decision이 위로, 오래된 것이 아래로 가게 작성함<-->

[TechDebt] `FadingScrollEdge`가 정적 상단 마스크뿐 — 조건부(남은 콘텐츠 있을 때만)·하단 페이드 미구현

상태: 미해결

내용:
사용자가 2026-07-13에 직접 지적: 의도한 스펙은 "스크롤 가능한 영역에서 콘텐츠가 상/하단으로 더 있을 때만" Edge Gradient가 보이는 것인데, 현재 `lib/widgets/fading_scroll_edge.dart`는 `ScrollController`/`ScrollNotification` 등 스크롤 상태를 전혀 보지 않는 고정 `ShaderMask`(`LinearGradient` stops `[0.0, 0.06]`, 상단만) 하나뿐이다 — 하단 페이드는 구현 자체가 없다. 또한 `AppMainScaffold`의 `body` 슬롯(헤더/툴바 아래)에만 적용돼 상태표시줄 바로 아래가 아니라 헤더보다 아래에서 시작한다.
**해소 경로 확정**: 같은 날 사용자가 정식 스펙(`docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`)을 제공 — `ShaderMask` 방식은 그 스펙 §5 "AI Constraints"에서 명시적으로 금지되며, `TopGradientOverlay`/`BottomGradientOverlay`(스크롤 위치 기반 조건부 오버레이)로 완전히 교체될 예정. 이 TechDebt 항목은 그 Implementation 태스크가 완료되면 해소됨 — 별도 대응 불필요, 스펙 문서가 Source of Truth.

---

[TechDebt] `CompositionGalleryTile`이 아직 텍스트만 표시 — 향후 `Composition.coverImagePath` 필드 신설로 해소 예정(사용자 확정)

상태: 미해결 (방향 확정, 미착수)

내용:
Step③ Audit(2026-07-13)이 P1으로 지적: `CompositionGalleryTile`(`lib/widgets/composition_gallery_tile.dart`)이 코디 이름+계절 텍스트만 표시해 `02_코디 (가상 조합).md`의 "옷장과 동일한 레이아웃/버튼 패턴"(실제 사진 타일) 요구와 어긋난다. 대응 방식 3가지(대표 아이템 이미지 1장 재사용 / 미니 아트보드 합성 렌더 / `StyleLog`처럼 `coverImagePath` 필드 신설)를 검토한 결과 사용자가 **`coverImagePath` 필드 신설**로 확정(2026-07-13) — 단, 지금 당장 착수하지 않고 현행 텍스트 표시를 유지한 채 이후 라운드로 미룬다. 필드 신설 시 사용자가 대표 이미지를 지정/캡처하는 로직(신규 기능)이 선행돼야 하므로 순수 Frontend 표시 변경이 아니라 Data/Architecture 결정 + Editor(Step⑤) 연동이 함께 필요.

---

[TechDebt] Step③ Audit(2026-07-13)에서 발견된 소소한 주석/lint 이슈 3건 — 다음 해당 파일 터치 시 함께 정리

상태: 미해결

내용:
1. `lib/widgets/app_main_scaffold.dart:29`와 `lib/screens/closet_main_screen.dart:73`의 groupingBar 관련 주석이 "실제 그룹형 드릴다운은 Step③ 몫"이라고 적혀있는데, Step③(2026-07-13)이 실제로 끝나며 groupingBar는 여전히 skeleton placeholder로 남고 실제 드릴다운은 Step⑦(기능 구현)로 확정됐다 — `composition_main_screen.dart`의 대응 주석("Step⑦에서 실제 드릴다운으로 대체 예정")만 최신 상태. 두 주석을 Step⑦ 기준으로 맞출 것.
2. `integration_test/composition_style_log_main_screen_test.dart:8`에 미사용 import(`package:digittal_wardrobe/router/app_router.dart`) — `flutter analyze` 경고 1건.
둘 다 기능에는 영향 없는 문서/lint 수준 이슈라 별도 사이클 없이 다음에 해당 파일을 건드릴 때 같이 정리하면 됨.

---

[TechDebt] `StyleLog` 모델에 정렬/필터 기준 필드(날씨/옷 종류/계절) 자체가 없어 스타일일지 메인 다중 필터 UI를 구현할 수 없음

상태: 미해결

내용:
`03_스타일 일지.md` UX명세서는 스타일일지 메인의 정렬/필터로 "날짜, 옷 종류, 날씨, 계절 기준 지원(역순 보기 옵션 포함)"을 요구하지만, `StyleLog`(`lib/models/style_log.dart`) 모델에 `season`/`weather`/착용 옷 종류에 대응하는 필드가 전혀 없다(날짜만 `wornDate`로 존재). Step③(코디/스타일일지 메인 적용, 2026-07-13)에서 `style_log_main_screen.dart`를 `AppMainScaffold`로 마이그레이션하며 Review가 이 사실을 지적 — 이전 Step①(전체 화면 Skeleton) 단계엔 "헤더 (스타일 일지 ▾ + 필터 칩)"이라는 placeholder 주석이라도 있었으나, 이번 마이그레이션에서 비기능 정렬 아이콘 하나만 남기고 그 흔적이 사라졌다. 실제 필터 구현은 `StyleLog` 모델 확장(Data/Architecture 레이어 결정) 없이는 불가능 — 모델 필드 추가가 선행돼야 함.

---

[TechDebt] 화면 간 반복 복제된 UI 블록 3종 — Step④ 이후 화면이 늘기 전에 공용 컴포넌트/헬퍼로 추출 검토 필요

상태: 미해결

내용:
Step③(코디/스타일일지 메인 적용, 2026-07-13)에서 Review가 지적: (1) FAB 펼침 애니메이션 스캐폴딩(`_buildFabOption`/`_onFabOptionTap`/`AnimatedSize` 블록, 약 35줄)이 `closet_main_screen.dart`와 `style_log_main_screen.dart`에 텍스트만 바꿔 그대로 복제됨. (2) `_densityIcon(int density)` private 메서드가 `closet_main_screen.dart`와 `composition_main_screen.dart`에 코드 100% 동일하게 존재. (3) 갤러리 타일의 "좌하단 반투명 pill + `ConstrainedBox`+ellipsis" 라벨 블록이 `selectable_gallery_tile.dart`/`composition_gallery_tile.dart`/`style_log_gallery_tile.dart` 3곳에 동일 패턴으로 존재. 각 경우 모두 기존 패턴을 정확히 따른 것이라 지금 당장 문제는 아니지만(Review 판정: P2, 논블로킹), Step④~⑥에서 Detail/Editor/휴지통 화면이 추가되면 동일 블록이 계속 늘어날 것 — `ExpandableAddFab` 공용 위젯, `AppDensity.iconFor(density)` 헬퍼, `GalleryMetaLabel` 위젯 등으로의 추출을 다음 Step 진입 전에 검토 권장.

---

[TechDebt] `CrossReferenceLinkBar.height`(64)가 `AppSpacing`이 아니라 위젯 파일 로컬 const로 남아있음

상태: 미해결

내용:
Step②(Component Library) Task 2-A에서 `lib/widgets/cross_reference_link_bar.dart`를 신설하며 Detail 3화면(옷 상세/코디 상세/스타일일지 열람) skeleton의 `height: 64`(상호 참조 링크 바) 값을 그대로 가져왔으나, 이번 태스크의 Edit 대상에 `lib/theme/app_spacing.dart`가 포함되지 않아 `AppSpacing` 토큰으로 승격하지 못하고 위젯 파일 로컬 `static const`로 남겼다. Review(2026-07-13)에서 하드코딩 원칙 위반은 아니라고 판정(이름 있는 const + 출처 주석 확인)했으나, `app_spacing.dart`가 다음에 Edit 대상에 포함될 때 정식 토큰으로 승격 검토 필요.

---

[TechDebt] 옷장 메인 재설계 중 추가된 시각적 매직넘버(스크롤마스크/틴트/디버그 상태바 치수) 토큰화 필요

상태: 미해결

내용:
`closet_main_screen.dart`에 추가한 세이지 틴트 컨테이너 크기(240x240)/alpha(0.15), `ShaderMask` stops([0.0, 0.06]), 디버그 상태바 높이(24)·아이콘 크기(14)·도트 크기(6)·폰트 크기(12) 등이 리터럴로 남아있음. 이번 스코프(코너 반경/duration 토큰화)와는 별개라 이번 라운드에서는 토큰화하지 않았으나, 추후 Design Tokens 확정 시 반영 검토 필요.

---

[TechDebt] `AppRadius`(`lib/theme/app_spacing.dart`) — Brand Guide/Design Tokens 문서에 정식 등재 필요

상태: 미해결

내용:
옷장 메인 재설계 시 `AppRadius.sm`(16, 드롭다운 패널)/`AppRadius.pill`(100, 필 버튼)을 코드에서 처음 정의했으나, Design Tokens에는 이 코너 반경 값에 대한 역할명 자체가 없었음. 추후 Brand Guide/Design Tokens 문서에 정식 등재 검토 필요.

---

[TechDebt] `documentation-conventions`/`uiux-design-conventions` 스킬 채택 보류 — 파일럿 초안만 존재, 정식 검토 필요

상태: 해결됨 (2026-07-10) — 실채택 완료. 상세: `Decision.md` 최상단 항목 참고.

내용:
`Digital-Wardrobe-testbed/localTestbed`(브랜치 `feature/skill-extraction-testbed`) 파일럿에서 `hardcoding-prevention`(현 `engineering-principles`)/`flutter-implementation-conventions`와 함께 시험됐으나, 실제 채택 패스(`engineering-principles`/`flutter-implementation-conventions` 채택 Decision 참고)에서는 제외됨. `documentation-conventions`(`Workflow_Project.md` §1.4/§1.5 대상)와 `uiux-design-conventions`(`Workflow_Design.md`의 Layer Boundary Rule + Design/Visual Review 체크리스트 대상)는 아직 파일럿 초안 상태로만 존재. 채택 여부/타이밍 재검토 필요.

참고: 파일럿 원본(`Digital-Wardrobe-testbed/localTestbed/REPORT.md`)은 이후 해당 worktree 삭제로 더 이상 존재하지 않음 — 내용은 채택 Decision 항목에 요약됨.

---

[TechDebt] `.superpowers/sdd/`의 플랫(non-namespaced) 파일명이 서로 다른 plan 간 충돌

상태: 미해결

내용:
`task-N-brief.md`, `task-N-report.md` 같은 파일명이 plan별로 구분되지 않고 공유됨. 서로 다른 plan(예: git-flow-commit-policy plan과 flutter-frontend-hifi-screens plan)이 둘 다 Task 7을 가지면, 나중 plan의 Task 7 산출물이 앞선 plan의 Task 7 파일을 덮어씀.

발견 경위:
2026-07-09 세션 인계 실패 조사 중 발견.

영향:
같은 세션 내에서 여러 plan을 순차 실행할 때 이전 plan의 task 브리핑/리포트가 유실될 수 있음.

조치 방향(착수 조건):
`.superpowers/sdd/` 하위에 plan-slug 기반 서브디렉토리 또는 파일명 prefix 도입 검토. superpowers 스킬 자체(외부 플러그인)의 스크립트(`scripts/task-brief`, `scripts/sdd-workspace`)를 건드리는 문제라 이 프로젝트 단독으로 고치기 애매함 — 필요시 플러그인 쪽에 이슈 제기 검토.

---

[TechDebt] `guard_git_actions.py`의 세그먼트 분리 매칭 — heredoc 등 일부 셸 구문은 여전히 오탐/누락 가능

상태: 부분 해결 (원래 문제는 고쳐짐, 더 좁은 범위의 한계가 남음)

내용:
원래 문제("COMMIT_RE/PR_CREATE_RE/PUSH_RE가 원본 커맨드 문자열 전체에 `.search()`를 수행해서, 실제 git/gh 호출이 아니라 그 문자열을 텍스트로 담고 있는 커맨드도 차단됨")는 git-flow 정책 재설계 작업 Task 9 fix round에서 해결됨: 이제 커맨드를 셸 연산자(`&&`, `||`, `;`, `|`)로 분리하고, 각 세그먼트의 선두(`VAR=val` 및 `sudo`/`env`/`exec`/`command`/`time`/`nice`/`nohup` 같은 흔한 래퍼 제거 후)가 실제로 `git`/`gh` 호출인지만 확인한다. 이 변경으로 fix round 1에서 `sudo git commit` 등 래퍼가 붙으면 게이트가 통째로 뚫리는 새 회귀가 잠깐 생겼으나, fix round 2에서 래퍼 스트리핑을 추가해 해결함.

남은 한계:
- 세그먼트 분리가 순수 텍스트 기반이라, 셸 연산자(`&&`/`;`/`|`)를 리터럴 텍스트로 포함하는 heredoc 본문(예: 이 문서 자체처럼 파이프나 세미콜론이 들어간 프로즈/코드를 heredoc으로 작성하는 커맨드)은 여전히 의도치 않게 여러 세그먼트로 쪼개질 수 있다.
- `sudo`/`env`/`exec`/`command`/`time`/`nice`/`nohup` 외의 래퍼(`ssh host git commit`, `bash -c "git commit"`, `xargs` 등)는 스트리핑 대상이 아니라 여전히 게이트를 우회할 수 있다.
- 근본 해결(진짜 셸 파서 사용)은 범위가 커서 여전히 보류.

발견 경위:
Task 2 리뷰(원래 문제 발견) → Task 9 fix round 1(세그먼트 매칭으로 해결 시도) → 리뷰에서 `sudo`/`env`/`exec`/`command`/`time` 래퍼 우회 회귀 발견 → fix round 2에서 래퍼 스트리핑 추가로 해결. 이 과정에서 리뷰어가 heredoc 기반 진단 커맨드가 여전히 오탐될 수 있음을 재확인함.

영향:
- 지정된 7개 래퍼(`sudo`/`env`/`exec`/`command`/`time`/`nice`/`nohup`)로 인한 우회는 fix round 2로 닫혔으나, 그 외 래퍼(`ssh host git commit`, `bash -c "git commit"`, `xargs` 등)로 인한 우회는 여전히 가능함.
- 남은 오탐 한계는 이 하네스로 훅 자체를 다루는 문서/테스트 작성 시(특히 heredoc 사용 시) 여전히 마주칠 수 있음 — 불편함 수준.

조치 방향(착수 조건):
비슷한 문제가 반복되거나 작업 여유가 생기면, 정규식 기반 세그먼트 분리 대신 실제 셸 파서(예: `shlex`나 POSIX 셸 문법 파서)로 교체 검토.

---