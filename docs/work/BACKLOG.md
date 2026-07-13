<!--> 프로젝트 현재 상태 스냅샷. 세션 시작 시 여기부터 확인. 항상 최신으로 유지 <-->

# Project

Digital Closet (working title, `digittal_wardrobe`)

Version: 1.0.0+1

Status: 🟡 기획/디자인 단계 (코드는 아직 스켈레톤뿐)

---

# Current Milestone

디자인 시스템 구축 — Brand Guide → Hi-Fi Sample → Visual Review → Design Tokens → Component Library (순서 근거: `.claude/policies/Workflow_Design.md` §2)

---

# Last Completed

**Task 7(옷장 메인 화면) 구현 — 완료.** 하네스 신설 후 첫 Worker→Review→Tester 실사용 사이클, 실제로 Review/Tester 각각 실동작 버그를 1건씩 잡아냄(둘 다 수정·재검증 완료):
- `lib/screens/closet_main_screen.dart` 신설(계절 필터는 `Season.values`/`.label` enum 순회로 구현, 플랜 원문의 하드코딩 문자열 예시를 의도적으로 벗어남), `lib/router/app_router.dart`의 `closetMain` 라우트를 실제 화면으로 교체 — 커밋 `58a22fe`.
- **Review가 P0 발견**: `app_router.dart`의 정적 라우트(`/closet/add` 등)가 동적 `:id` 라우트보다 뒤에 선언돼 있어 go_router가 선언 순서상 `:id`를 먼저 매칭 — FAB "옷 추가하기"가 실제로 망가져 있었음(go_router 소스코드로 직접 확인). 같은 패턴이던 `composition`/`style-log` 그룹도 예방적으로 함께 정리. 커밋 `8145d3f`.
- **Tester가 실동작 버그 발견**: 밀도 토글 아이콘 `onPressed`가 build 시점 지역 변수를 참조하는 stale-closure 버그 — 리빌드 전 빠른 연속 탭 시 순환이 멈춤. 커밋 `10d3643`으로 수정(`ref.read`로 콜백 시점 최신값 재조회). `integration_test/closet_main_screen_test.dart`(Tester 소유, 9개 시나리오)로 회귀 고정 — 커밋 `f8e4f61`/`bc5a2f3`.
- 최종 9/9 통합테스트 Pass, `flutter analyze` 클린. PR 오픈 예정(dev로).

**하네스 확장: Tester 역할 신설 — 완료.** Worker→Review 2단계 사이클에 Tester(런타임 동작 검증, Flutter `integration_test` 기반)를 추가. 상세는 `docs/history/Decision.md` 최신 항목 참고.
- `.claude/agents/tester.md` 신설, `Workflow_Development.md`/`Workflow_Project.md`/`CLAUDE.md` 3종 문서 갱신(역할 정의, 파이프라인 M/L/XL에 Tester 삽입, handoff 템플릿, Definition of Done, Layer×Stage 자료 매핑).
- `integration_test` 패키지 도입 + smoke test 작성, Windows desktop에서 실제 실행 검증 완료(`flutter test integration_test/app_smoke_test.dart -d windows` → "All tests passed!") — 커밋 `39a2958`, `feature/flutter-hifi-screens` 브랜치.
- Android 툴체인(Android Studio/SDK)은 사용자가 별도로 계속 설치 진행 중 — 이번 Tester 셋업 자체는 Windows desktop 경로만으로 완결됐고, Android는 향후 추가 디바이스 타깃 옵션(블로커 아님).
- 이어지는 **Task 7(옷장 메인 화면)** 구현이 새 Worker→Review→Tester 사이클을 처음 타는 실사용 케이스가 됨.

**dev 병합 충돌 해소 + 동기화 프로세스 신설 — 완료 (2026-07-10).** `feature/flutter-hifi-screens`가 dev를 오래 안 당겨받은 사이, dev에 먼저 병합된 별도 PR(#6, 정책/레퍼런스 문서 폴더구조 개편 — `docs/knowledge/**` → `.claude/policies/`+`docs/history/`+`docs/reference/`)과 갈라져 `CLAUDE.md`/`Workflow_Project.md`/`Decision.md`/`BACKLOG.md` 4개 파일에서 충돌 발생. PM이 해결, `flutter analyze` 클린 확인, 남은 옛 경로 참조(`tester.md` 등)도 정리. 재발 방지로 `Workflow_Project.md` §13.4 "Sync Cadence" 신설 — Task 완료 시점/Plan 완료 시점마다 `git fetch && git merge origin/dev` 수행(상세: `Decision.md` 최상단).

Flutter Hi-Fi 스프린트 Task 1~6 + 하드코딩 원칙 정립(category/season/material enum화) — **PR #5 병합 완료 (dev, 2026-07-10, https://github.com/kangyj099/Digital-Wardrobe/pull/5)**.
- Task 1~6: 프로젝트 셋업, 디자인 토큰, mock 모델/데이터, Riverpod provider, go_router 셸, 공용 갤러리 컴포넌트.
- 하드코딩 원칙(모든 값은 (a)런타임 동적 데이터 (b)데이터 파일/리소스 (c)코드 내 const/enum/design token 중 하나를 Source of Truth로 가져야 함) 확정 — 전체 코드베이스에 적용, 예외는 일회성 테스트 코드/명시적 임시 placeholder/긴급 디버그 로깅 3가지뿐.
- `ClothingItem.category`/`season`/`material`, `Composition.season`을 bare `String`에서 `lib/models/enums.dart`의 실제 Dart `enum`(`ClothingCategory` 8종/`Season` 4종/`ClothingMaterial` 18종, 각각 `label` getter)으로 전환 — 위반 필드 4개 전부 해소.
- Season 값 체계를 봄/여름/가을/겨울(기존 `03_화면별UX명세서.md` 기준)에서 여름/겨울/간절기/사계절로 재정의(사용자 확정) — 그 문서도 함께 갱신됨.
- **(해결됨)** 하드코딩 원칙의 정책 문서화(`Workflow_Development.md` §1 "Hardcoding Policy" 하위 섹션, `Workflow_Frontend.md` cross-reference)는 커밋 후 사용자 지시로 한 차례 revert됐었으나(커밋 `9e8b66d`), 이후 `.claude/skills/engineering-principles/SKILL.md`로 정식 재문서화 완료(스킬 분리 정책 채택, 상세: `Decision.md`). 현재 정책 문서(스킬) 상에 명문화돼 있음 — 더 이상 미결 상태 아님.

(참고) 세션 인계 브릿지 규칙 신설 — PR #4 병합 완료(2026-07-09). Git-flow 커밋/PR 정책 도입 — PR #2 병합 완료(2026-07-08).

---

 **하네스 로깅 보강 — 완료 (2026-07-12).** 토큰 소모 진단 중 발견한 두 공백을 메움: (1) Workflow_Project.md §14.1 — 에이전트 스폰 전/handoff 직후 /context 근사 토큰 Delta를 docs/work/TokenLog.md에 기록. (2) §14.2 — Worker/Review/Tester handoff에 Read/Search/Edit 호출 통계(Stats) 기록, docs/work/AgentStats.md에 누적. opt-in, 기본 OFF — docs/work/TokenLog.md 헤더의 Status: ON/OFF 한 줄이 §14.1/§14.2 공통 스위치이며, 토큰 소모 문제가 의심될 때만 켬. worker.md/review.md/tester.md 3종 handoff 포맷도 이 스위치에 따라 Stats 줄을 조건부로 포함하도록 갱신. 부수: stale worktree 4개 정리(위 Known Issues 참고).

---

# Current

Flutter 프론트엔드 Hi-Fi 화면 10개 스프린트 (**마감 2026-07-24로 정정** — 기존 2026-07-10에서 연장, 2026-07-11 사용자 확정. 옷장 메인 재설계가 예상보다 커져 스코프 안정화 위해 조정) — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치(PR #5로 dev에 한 차례 병합 완료, **같은 브랜치에서 계속 작업 이어감** — 새 브랜치 불필요)에서 Subagent-Driven으로 진행 중.
- 스펙(스프린트 전체 범위): `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`
- 플랜: `docs/superpowers/plans/2026-07-08-flutter-frontend-hifi-screens.md` — **Task 1~7은 유효, Task 8~15는 아래 "8단계 프로세스"로 대체됨(더 이상 이 플랜대로 진행하지 말 것)**. 지금 당장 뭘 할지는 아래 "Current" 맨 아래 문단(2026-07-13 항목)의 "다음 세션 작업"을 따를 것.
- Design Workflow의 "Hi-Fi Sample" 단계를 실제 코드로 겸함 — 완료되면 아래 "Next"의 Hi-Fi Sample 항목도 함께 해소됨.

**옷장 메인 화면 재설계 — 마무리 단계 (2026-07-10~12)** — Task 7 완료 후 Visual Review가 아예 없었다는 게 드러나(사용자 질문 "리뷰 과정에 비주얼 리뷰 했어?"로 발견), 목업 스펙과 실제 구현을 정밀 대조해서 재작업 중. **상세 진행상황·설계 스케치는 `docs/work/옷장메인_재설계_체크리스트.md` 참고**.
- 요약: Season enum 개편/Design Tokens 확정/레이아웃 재구축/밀도값 변경/시각 디테일 라운드/컬러 팔레트 변수화까지 Worker 작업은 전부 완료(커밋 `fb15a84`~`399d3ef`).
- **(2026-07-12 완료) 시각 디테일 라운드(`0da0cee`) + 팔레트(`399d3ef`) Review→Tester 정식 사이클 마무리**:
  - Review에서 `0da0cee`에 P1 1건 발견 — `selectable_gallery_tile.dart`의 `_labelMarginRatio`(4/627.5)가 특정 데스크톱 뷰포트 가정을 역산한 하드코딩이라 engineering-principles 위반. 프로젝트 오너 지시로 근본 수정: 라벨 마진을 기존 `AppSpacing.xxs` 토큰으로 대체하고, 라벨박스가 `right` 없는 `Positioned`+`ConstrainedBox(maxWidth: 타일폭-xxs*2)`로 텍스트 길이에 맞춰 늘어나되 타일 밖으로 넘치면 `ellipsis`(+`maxLines:1`)로 처리되게 재구현 — 커밋 `30a90e5`. 재-Review Pass.
  - `399d3ef`(팔레트)는 Review 1차 통과(Pass, 이슈 없음) — Decision.md의 "색이 바뀐 것은 아니다" 불변조건을 diff 레벨에서 검증 완료.
  - Tester가 통합테스트 19개(기존 15개 + 라벨 크기조절/팔레트 회귀 신규 4개) 전부 Pass 확인 — 커밋 `0471265`. 짧은/긴 카테고리 라벨이 밀도 1/2/4 전 구간에서 타일 안에 들어맞고, 팔레트 리팩터 후 실제 런타임 색상값이 이전과 동일함을 확인.
  - 뒤로가기 버튼(요청받음, 미착수), Task 4(검색필드+스크롤바, 뒤로 미룸)는 체크리스트 문서에 상세 기록.
- **(2026-07-12 완료) 하단 좌측 뒤로가기 버튼**: `context.canPop()` 기반 노출 + `OverlayHeader`와 동일한 프로스티드글래스 톤(블러/보더/그림자) 재사용해 구현 — 커밋 `31b42b0`. Review Pass(P0/P1 없음, P2 2건은 비차단 — 톤 값이 `OverlayHeader`와 별개 리터럴로 중복돼있는 점과 safe-area 미처리, 체크리스트 "후속 필요"에 기록). Tester가 라우터가 flat `GoRoute`라 평소 `canPop()`이 늘 false임을 확인하고 인위적으로 push해 검증(체크리스트에 기록된 의도된 임시 상태, 결함 아님) — 통합테스트 22/22 Pass(신규 3 + 기존 19).

**(2026-07-12) 작업 방식 전환 — Task 8~15 순차 진행 중단, 전체 화면 아키텍처 재설계로 전환.** 위 뒤로가기 버튼 작업 중 사용자가 "뒤로가기/카테고리 토글/그룹형 드릴다운은 화면 하나씩이 아니라 앱을 관통하는 공용 UI여야 한다"고 지적 — Task 8~15를 화면별로 순차 구현하던 기존 방식이 이 전제를 반영 못하고 있었음이 드러남.

**(2026-07-13 완료) 위 재설계의 브레인스토밍·스펙 확정 — 사용자 최종 승인 완료.** 결과물: `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`. `docs/work/전체화면_아키텍처_재설계_체크리스트.md`는 은퇴(내용은 이 스펙으로 이관, append-only로 그대로 보존).
- **아키텍처**: 공용 셸 위젯 `AppMainScaffold`(신설 예정, B안 채택 — 화면이 이걸 쓰기만 하면 뒤로가기/토글/그룹바를 빠뜨릴 수 없는 구조)가 뒤로가기(`FrostedBackButton` 추출)·카테고리 토글(`CategoryToggleDropdown` 추출+파라미터화)·`groupingBar` 슬롯(그룹형 드릴다운용)을 소유. Add/Create 3화면은 자체 취소/저장 헤더 유지, 이 셸 미사용.
- **화면별 규칙 표 확정**(스펙 §1) — 그룹형 드릴다운은 옷장/코디 메인만(스타일일지는 기존 스펙대로 플랫+필터 유지, 이전 세션 기록의 "3개 전부" 충돌 해소됨), 선택 모달은 원 화면과 동일 사양(옷장/코디 모달은 그룹형, 스타일일지 모달은 플랫).
- **개발 프로세스 8단계로 재편**(Task 8~15 대체) — ①전체 화면 Skeleton → ②Component Library 구축(후보 리스트업→사용자 검수→제작) → ③Main 3개 적용 → ④Detail 적용 → ⑤Editor 적용 → ⑥나머지 적용 → ⑦기능 구현 → ⑧디테일 튜닝.
- **(2026-07-13 완료) Step① 플랜 작성 + 사용자 검토 반영 완료**: `superpowers:writing-plans`로 `docs/superpowers/plans/2026-07-13-cross-screen-skeleton-step1.md` 작성(Task A~F, 6개). 사용자 검토로 빠진 부분 하나 발견·보강: 옷장 메인은 이미 실구현이라 처음엔 이 Plan 대상에서 뺐었으나, §1 표의 Main-그룹형 페이지 타입이 요구하는 "그룹형 드릴다운" 리전이 옷장 메인엔 아예 없었음(계절 드롭다운은 플랫 필터일 뿐 `GroupedMainViewMode` 드릴다운이 아님) — Task B로 그 리전만 별도 보강(기존 헤더/뒤로가기/FAB 등은 안 건드림, 22개 통합테스트 회귀 확인 포함). 이제 §1 표 13행 전부 처리 경로 확보.
  - **Task 구성**: A(스켈레톤 헬퍼+코디 메인) → B(옷장 메인 그룹형 드릴다운 리전 보강) → C(스타일일지 메인+휴지통, 라우트 분리 `settingsTrash`→`settingsMain`+`trashMain`) → D(상세 3종) → E(Add/Create 3종) → F(설정). 전부 Worker→Review만(Tester 생략 — 스펙 §4, 실동작 없는 순수 구조 코드라서).
  - 선택 모달 2종(옷장/코디용, 스타일일지용)은 이 Plan 대상 아님 — "기존 메인 화면 재사용" 원칙상 새 파일이 없고, Step⑥에서 모달 프레젠테이션으로 다룸.
  - **다음 세션 작업**: 이 플랜 파일을 그대로 실행 — Task A부터 순서대로 PM이 Worker→Review 디스패치(플랜 파일이 자기완결적이라 이 문서 + 위 요약만으로 충분, 스펙/체크리스트/페이지타입정의 등 원본 문서를 다시 훑을 필요 없음). Task 완료마다 BACKLOG.md Current 갱신 관행 유지. Plan 전체 완료 시 §13.4 dev-sync 수행.
  - **(2026-07-13 완료) Task C(스타일일지 메인+휴지통 골격, 라우트 분리) — 최종 Pass 확정.** `StyleLogMainScreen`/`TrashMainScreen` 신설 + `app_router.dart`의 `settingsTrash`를 `settingsMain`('/settings')+`trashMain`('/trash')으로 분리 — 커밋 `8a0db69`. Review가 P1 발견: `TrashMainScreen`이 라우트에 연결만 됐을 뿐 런타임 검증(자동 테스트도, `flutter run` 수동 확인도)이 전혀 없었음 — 플랜상 이 Task는 "Tester 생략" 대상이었으나, 이 P1 때문에 예외적으로 Tester 1개 시나리오를 추가로 투입. 기존 `canPop()` 인위적-push 패턴을 재사용해 `integration_test/closet_main_screen_test.dart`에 테스트 23번 추가(`GoRouter.of(context).push(AppRoute.trashMain)`으로 강제 진입 후 `find.byType(TrashMainScreen)` + 헤더/그리드 스켈레톤 텍스트 두 개 존재를 assert) — 커밋 `5699b26`. PM이 diff 재검토(`skeletonRegion` 텍스트 "헤더"/"썸네일 그리드"가 이 테스트 실행 시점엔 옷장 메인 화면 아래 offstage로만 존재해 오탐 위험 없음 확인) + `flutter test integration_test/closet_main_screen_test.dart -d windows` 재실행으로 23/23 Pass 재확인. P1 해소 확정, Task C 전체 최종 Pass.
  - **(2026-07-13 완료) Task D(상세 3종 스켈레톤) 리워크 — Review P1 해소, 최종 Pass 확정.** Task D(commit `f48ac88`, `CompositionDetailScreen`/`StyleLogViewerScreen`/`ClosetItemDetailScreen` 신설)에서 Review가 P1 발견: `CompositionDetailScreen`/`StyleLogViewerScreen`은 상위 메인 화면(코디 메인/스타일일지 메인)이 아직 스켈레톤이라 진입 UI가 없어 단 한 번도 실제로 렌더링된 적이 없었음(정적 분석만 통과, `state.pathParameters['id']!` 강제 non-null 코드가 유효한 id로 호출될 때 에러 없는지 미검증). Task C의 TrashMainScreen 때와 동일한 해법(커밋 `5699b26`)을 재적용 — `integration_test/closet_main_screen_test.dart`에 `GoRouter.of(context).push('${AppRoute.compositionMain}/test-id')`/`push('${AppRoute.styleLogMain}/test-id')`로 인위적 push 후 화면 렌더링 + id 보간까지 assert하는 테스트 2건(24~25번) 추가 — 커밋 `70333f1`. **주의(정정)**: Worker가 자신의 handoff에서 "Review Pass → Tester Pass"까지 스스로 서술했으나, Worker는 Agent 툴 권한이 없어 실제로 Review/Tester를 스폰할 수 없다 — 자기 서술은 신뢰하지 않고 PM이 `flutter analyze`/`flutter test`를 직접 독립 재실행(클린/25-25 Pass 확인) 후, **진짜 Review 서브에이전트**를 새로 디스패치해 처음부터 재검토받아 Pass 확정함(Tester는 이 Plan 전체에서 애초에 생략 대상). 이 하네스 경계 이탈 이슈는 `harness_engineering_design` 메모리에 기록됨.
  - **(2026-07-13 완료) Task E(Add/Create 3종 스켈레톤) — Review Pass.** `ClosetAddScreen`/`CompositionEditorScreen`/`StyleLogAddScreen` 신설 + 라우트 3개 교체 — 커밋 `bfe45f5`. Worker가 Task D 선례를 미리 적용해, 코디 만들기/스타일일지 추가(상위 메인 FAB가 아직 no-op이라 도달 불가)에 대한 인위적 push 검증 테스트를 선제적으로 같은 커밋에 포함시켜 P1 재발 없이 Review 1차 통과. `flutter analyze` 클린, 통합테스트 27/27 Pass. P3(비차단) 주석 라인번호 오기 1건은 Task F에서 함께 정정.
  - **(2026-07-13 완료) Task F(설정 화면, Utility) — Review Pass. Plan A~F(전체 화면 Skeleton, Step①) 전체 완료.** `SettingsScreen` 신설 + `settingsMain` 라우트 교체, 더 이상 안 쓰이는 `_placeholder` 헬퍼·미사용 import 정리, `/settings` 인위적 push 검증 테스트 추가, Task E의 P3 주석 오기 동시 정정 — 커밋 `5ad6561`. 프로젝트 전체 `flutter analyze` 클린, `integration_test/closet_main_screen_test.dart` **최종 28/28 Pass**(Worker 최초 보고 "27개+28번"은 자기모순적 오기였음 — Review가 직접 재실행해 28이 맞음을 확정, 기록 정정). §1 표 13행(신규 화면 10 + 옷장메인 보강 1 + 선택모달 2행 스코프아웃) 전부 처리 경로 확보를 Review가 최종 재확인.
  - **세션 전환 판단(토큰 효율)**: 이 플랜을 쓰는 과정에서 탐색용으로 읽은 자료(스펙/체크리스트/원본 플랜 등)가 이미 상당한 컨텍스트를 차지했고, 실행 단계(Task A~F × Worker+Review 디스패치)는 그 탐색 컨텍스트가 필요 없음 — 플랜 파일 자체가 완결적이므로. 실행은 **새 세션**에서 이어가는 쪽이 다 턴에 걸친 캐시 비용 누적을 줄여 더 유리하다고 판단, 새 세션으로 인계함.
  - **다음 세션 작업**: Step①(스켈레톤) 완료. 다음은 8단계 프로세스의 Step②(Component Library 구축 — 공용 컴포넌트 후보 리스트업→사용자 검수→제작, `AppMainScaffold`/`FrostedBackButton`/`CategoryToggleDropdown`/모달 래퍼 포함). 사용자가 "일시정지" 지시해 이번 세션은 여기서 종료 — dev-sync(§13.4)까지 수행 완료.
- **하네스 확장(부수, 완료)**: 이 재설계를 계기로 `.claude/agents/audit.md`(Feature Audit 역할, 프로젝트 전체 홀리스틱 검토) 신설 — L/XL 태스크 완료 시마다 자동으로 돎, review 서브에이전트 사전 검증 거침. `Workflow_Project.md` §15 "Worktree Placement" 정책도 신설(worktree는 저장소 바깥 형제 디렉토리로만 생성 — 이 환경 Grep/Glob이 `.gitignore`를 안 지키는 게 확인돼 유일한 구조적 해법으로 확정) + 고아 worktree 디렉토리 2개 정리. 상세: `docs/history/Decision.md`.

**(참고, 완료됨)** skill-extraction 파일럿(별도 worktree `Digital-Wardrobe-testbed`)은 채택 권고로 종료됐고, 그 결과가 아래 항목에 반영된 실제 채택 작업임 — 더 이상 진행 중인 별개 작업 아님.

**정책 채택 (완료, PR #6/#8 병합됨)**: Workflow 문서의 재사용 가능한 원칙(하드코딩 방지, Flutter 구현 규칙)을 `.claude/skills/`(`engineering-principles`, `flutter-implementation-conventions`)로 분리 + `docs/knowledge/` 재배치·앵커 구조 정리 + §12.4 Task Manifest 신설 — 전부 `dev`에 반영 완료. 상세: `docs/history/Decision.md` 참고.

**후속 (2026-07-10)**: 남아있던 TechDebt(`documentation-conventions`/`uiux-design-conventions` 스킬 채택 보류) 재검토 후 실채택 — `Workflow_Project.md` §1.4/§1.5, `Workflow_Design.md` Layer Boundary Rule + Design/Visual Review 체크리스트를 두 스킬로 이전, §12.1 등재, Version 범프(Project 2.2/Design 2.1). `feature/skill-conventions-adoption` 브랜치, PR 오픈 예정. 상세: `docs/history/Decision.md` 최상단.

---

# Next

- Brand Guide Pass 3 (Typography) 확정 — 위 Flutter 스프린트에서 임시 확정값(Material 3 기본 type scale)으로 우선 진행 중. 실제 화면을 눈으로 본 뒤 이 임시값을 정식 확정값으로 승격할지 재검토 필요 (`01_BrandGuid.md`의 "하이파이 샘플 제작 후 육안 확인" 조건과 부합).

- **`ui-ux-pro-max` 플러그인에서 Flutter 관련 내용만 추출해 프로젝트 로컬 스킬로 이식** (별도 세션에서 진행 예정, 2026-07-12 확정). 배경: 토큰 소모 진단 중 `ui-ux-pro-max`/`ui-styling` 플러그인 스킬 7종이 이 Flutter 전용 프로젝트와 무관한 내용을 매 턴 상시 로드하고 있는 걸 발견.
  - 이미 조사 완료: `ui-styling`(references 6개, 2,652줄)은 **전부 shadcn/Tailwind 전용, Flutter 내용 0줄** — 통째로 버려도 됨. `ui-ux-pro-max` 메인 `SKILL.md`(703줄)는 17개 스택(React/Vue/Flutter/SwiftUI 등) 포괄이라 그중 Flutter 전용 + 스택 무관 범용 부분(색상 팔레트/폰트 페어링/접근성 원칙 등)만 골라내는 편집 작업 필요.
  - 저작권 검토 완료: MIT License (Copyright Next Level Builder, 저장소 `https://github.com/nextlevelbuilder/ui-ux-pro-max-skill`), README에 추가 제약 없음 확인. 사용·수정·재배포 자유, 유일 조건은 **저작권 고지 + MIT 허가문구를 사본에 포함**하는 것 — 새 스킬 파일에 출처 URL과 MIT 고지문을 반드시 남길 것.
  - 원본 소스 경로(로컬 플러그인 캐시, 이 저장소 밖): `C:/Users/User/.claude/plugins/marketplaces/ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max/SKILL.md`.
  - 목표 산출물: 새 프로젝트 스킬(가칭 `.claude/skills/flutter-ui-reference/SKILL.md`).
  - 완료 후 후속 조치: 이 프로젝트의 `.claude/settings.json`에 `"ui-ux-pro-max@ui-ux-pro-max-skill": false`를 추가해 (기존 `figma@claude-plugins-official: false`와 동일한 방식으로) 이 프로젝트에서만 원본 플러그인 비활성화 검토 — 전역(`~/.claude/settings.json`)은 다른 프로젝트에서 계속 쓸 수 있으니 그대로 둠.

---

# MVP Progress

`docs/reference/plan/00_MVP.md` §2 스코프 기준, 코드 구현 여부 (전부 미착수):

- [ ] Clothing archiving (AI 배경제거 + 자동태깅)
- [ ] View/filter by tags
- [ ] Composition (가상 코디, 편집 가능)
- [ ] Style Log
- [ ] Clothing-based history
- [ ] Automatic wear count

---

# Current Folder

`lib/` (현재 `main.dart` 스켈레톤만 존재)

---

# Known Issues

(2026-07-13 재발·재해소, 원인 정정) `.claude/worktrees/policy-doc-versioning-audit/` 등 stale worktree 4개(2026-07-12 정리) 이후에도 고아 디렉토리 2개(`policy-audit-fix`, `setting-ui-temp`)가 남아있었음 — `setting-ui-temp`는 이미 pruned된 `policy-doc-versioning-audit` 메타데이터를 가리키는 죽은 `.git` 포인터를 갖고 있어, 그 정리 이후로도 계속 검색을 중복시키고 있었던 것으로 추정(`rm -rf`로 지워 `git worktree remove`를 안 거친 게 원인으로 보임). 2026-07-13에 재발견·삭제 완료.
**원인 정정**: 2026-07-12 기록엔 "이 worktree들이 gitignore 안 돼 있어서"라고 돼 있었으나, 이후 `.claude/worktrees`는 실제로 `.gitignore`에 등록돼 있었음에도 Glob이 여전히 매칭하는 걸 확인 — 진짜 원인은 **이 환경의 Grep/Glob 도구가 `.gitignore`를 아예 참조하지 않는 것**(gitignore 대상인 `.dart_tool/`도 그대로 매칭됨으로 검증). 재발 방지로 `Workflow_Project.md` §15 신설 — 앞으로 병렬 세션용 worktree는 저장소 바깥 형제 디렉토리로만 생성(상세: `Decision.md` 최상단).

---

# Parking Lot

MVP 명세상 Phase 2/3로 의도적으로 제외된 항목 (`00_MVP.md` §2 참고):

- Composition calendar (Phase 2)
- 실사진 위 핫스팟 레이어 (Phase 2)
- 추천/피드/팔로우 (Phase 3)
- 커스텀 그룹(폴더) (Phase 2~3)
