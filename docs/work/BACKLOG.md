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

**버그 수정 2건 완료(2026-07-28)**: (1) `GlassToast` 투명 히트박스가 뒷 화면 터치를 가로채던 문제 — `Center(child: IntrinsicWidth(child: Material(...)))`로 수정, Worker→Review→Tester 통과, 커밋 `28cca3e`+`e175ffc`. (2) (P1) `FlutterError: setState() ... called during build` 크래시 — provider-to-provider watch(`styleLogsLinkedToItemProvider`가 `compositionsContainingItemProvider`를 watch하던 구조)가 build 중 ancestor `setState()` 크래시를 유발하는 게 근본원인이라 확인, `compositionsProvider` 직접 필터 인라인으로 제거. 사용자의 실제 5단계 재연 시나리오 포함 신규 회귀테스트 3개 전부 PASS(Worker→Review 2라운드→Tester 통과), 커밋 `90e44a1`+`52303f6`. Tester가 부수적으로 확인한 comp02 소프트삭제 drift 실패 3건은 기존에 이미 기록된 별개 TechDebt(아래 참고).

---

# Current

**Group B Task 11(Detail 3화면 "더보기" 메뉴 — 실제 [삭제] 연결) 착수 예정** — 계획 문서 `docs/superpowers/plans/2026-07-21-multi-select-and-trash.md` 3509행~ 참고. Task 12(설정→휴지통 진입 로우)는 이미 완료돼 스킵, Task 13(문서 갱신 마무리)만 Task 11 이후 남음 — 13개 Task 중 11개 완료, 2개만 남은 상태.

**미착수 — (P2) 삭제된 옷이 코디 상세 "사용된 옷" 목록에 정상 데이터처럼 계속 나타나고 탭됨** — `composition_detail_screen.dart:34`와 `style_log_viewer_screen.dart:58`가 필터 안 된 원본 `closetItemsProvider`를 씀. 원인은 확인됐으나 수정 방향(목록에서 제외/배지 표시/탭 허용+안내)은 사용자 확인 필요. 위 P1 크래시는 이제 해소됐으니 다음에 착수 가능.

**미확인 — `GlassToast` 히트박스 수정이 사용자가 원래 보고한 증상(버튼 눌림 애니메이션은 보였다가 멈춤)과 완전히 같은 것인지 사용자 직접 재검증 예정.**

**TechDebt 참고 — comp02 소프트삭제로 깨진 통합테스트**: `composition_detail_data_binding_test.dart`/`detail_cross_reference_visuals_test.dart`/`style_log_composition_binding_test.dart`(확인된 실패, 이번 세션 Tester가 재확인)+`detail_thumbnail_square_unification_test.dart`(미확인 추정) — `TechnicalDebt.md` "[TechDebt] comp02 소프트삭제로 tapCompositionById 기반 통합테스트..." 항목 참고. Group B Task 8/9(코디·스타일일지 메인 마이그레이션)에서 이미 픽업 권장했었는데 아직 안 됨 — Task 11 착수 전에 픽업할지 판단 필요.

---

**병렬 작업 완료(2026-07-23) — 하네스 파이프라인 보완 + 문서 구조 개편**: `../Digital-Wardrobe-pipeline-docs` worktree(`feature/pipeline-docs-restructure`, `feature/flutter-hifi-screens`에서 분기)에서 아래 3건을 독립적으로 완료, `dev`로 PR 대기 중 — 이 Current 항목(Group B 등)과는 무관한 별도 스레드라 그대로 계속 진행하면 됨.
1. Task 완료 시 "세션 내 후속 작업 없음" 판단되면 BACKLOG.md만으로 새 세션이 이어받을 수 있는지 시뮬레이션 후 문제없으면 `/clear` 권유 — `Workflow_Project.md` §3 신설, CLAUDE.md 체크포인트 7번.
2. 설계/계획(Decision 단계) 산출물은 크기 무관 확정 전 Audit 필수 — `Workflow_Project.md` §5 "Decision-Stage (Design & Plan) Pipeline" 신설 + §12.1 표 갱신, `.claude/agents/audit.md` 트리거 추가. 이 플랜 자체가 이 원칙의 첫 적용 사례(Review 1회+Audit 1회 통과 후 확정).
3. `.claude/policies/`·`docs/reference/`의 라우터+앵커 구조(부모+서브파일 24개, 5개 그룹) 단일 파일로 재통합 + TOC 추가, 저장소 전체 상호참조 갱신(30여 지점) + 병합 결과 독립 Review 1회(P0/P1/P3 전부 없음) 통과. **이후 토큰 비용 재검토로 부분 롤백**(같은 세션, 사용자 피드백) — §12.1 Required Materials에 직접 걸려 Worker/Review에 좁게 자주 dispatch되는 핫패스 2개(`00_DesignPrinciples.md`/`03_화면별UX명세서.md`)는 서브파일 구조로 되돌리고, PM이 스스로 전체를 훑는 빈도가 높아 병합 손해가 작은 정책 문서 3종(`Workflow_Project/Design/Development.md`)만 병합 유지. **최종 상태: 5개 그룹 중 3개만 병합.**
상세는 `docs/history/Decision.md` 최상단 4개 항목 참고.

---

Flutter 프론트엔드 Hi-Fi 화면 10개 스프린트 (마감 2026-07-24) — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치(PR #5로 dev 1차 병합, PR #10으로 dev 2차 병합 완료 2026-07-18 — Task 7~13/Step②~⑦ 1라운드 전체, 같은 브랜치에서 계속 진행)에서 Subagent-Driven으로 진행 중.
- 스펙: `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`(원 스프린트), `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`(화면 관통 공용 셸 스펙 — **§2 "그룹형 드릴다운" 절은 2026-07-19에 정정 각주로 대체됨, 나머지 절은 유효**), `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`(Header/HUD·스크롤 컨테이너 정식 스펙), `docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md`(그룹형 드릴다운 캡슐 + 설정 진입점 최종 스펙, Task 1~7로 구현 완료 — 지금은 이 4개를 함께 따를 것)
- 원 플랜의 Task 1~7만 유효, Task 8~15는 폐기(대체 근거: `docs/history/Decision.md`의 "화면 관통 공용 UI 셸 아키텍처로 전환" 항목)

**다음 세션 작업**:
1. **"Step⑦ 나머지 스코프" 진행 중 — 4개 그룹(A~D)으로 분해, 그룹 A 완료(2026-07-19), 그룹 B부터 이어가면 됨.**
   - ~~그룹 A(그룹형 드릴다운 옷장·코디 2곳 + 설정 진입점 이동)~~ **완료(2026-07-19)** — 위 "Last Completed" 참고. `AppMainScaffold.groupingBar` 슬롯 삭제, `ClassificationDrilldownCapsule`+3상태 그리드 배선, 설정 진입점 이동 전부 반영, 관련 구 스펙 2건(`04_설정.md` §1, `2026-07-12-cross-screen-ui-shell-design.md` §2)에 정정 각주 완료.
   - **그룹 B(다중선택 진입/실행 + 휴지통 복원·영구삭제·비우기)**: 스펙+구현계획 작성 완료(2026-07-21). Task 1(모델 — `deletedAt` 필드 + `copyWith` sentinel 패턴, 3개 모델) 완료(2026-07-22, 커밋 `72366f2`+`540ee83`). Task 2(도메인 Notifier — `softDeleteMany`/`restoreMany`/`purgeMany`, 3개 provider) 완료(2026-07-22, 커밋 `d2c3e3e`). **Task 3(휴지통 집계 재작성 + 자동 영구삭제 + 안전가드 3곳) 완료(2026-07-24)** — Worker→Review(1차 PASS, P1 발견: mock 시드 변경으로 `composition_classification_test.dart`/`composition_providers_test.dart` 3개 테스트가 계획서 어디에도 배정 안 된 채 깨짐)→Worker(addendum: `comp03` 신설로 season:null/weather:rain 데모 복원 + 약한 테스트 자체완결형으로 재작성)→Review(2차 PASS, P1 해소 확인, P3 1건은 PM이 직접 정리)→Tester(PASS, 5개 런타임 시나리오 전부 크래시 없음 — 앱 부팅+자동purge, 휴지통/코디상세/스타일일지열람/옷장메인 진입) 전체 사이클 통과. Task Size는 M("One feature")로 판단해 Tester 통과 후 Audit 없이 완료 처리. 커밋 `14c0ec0`(본체)+`029641e`(addendum)+`4cc57fd`(P3 라벨 정리)+`bd1dc32`(Tester 통합테스트 신규). `flutter analyze` 클린(기존 `integration_test/` 경고 6개만)/`flutter test` 85개 전부 통과 확인됨. Tester가 재확인한 기존 통합테스트 2개(`settings_trash_shell_test.dart`/`closet_main_screen_test.dart`)의 실패(mock 개수 변화로 인한 assertion 불일치, 크래시 아님)는 Task 3 자체가 이미 disclose한 known issue — **Task 7(옷장 메인 마이그레이션)이 이 두 스위트의 stale assertion 갱신을 반드시 포함해야 함**(누락 시 회귀 스위트가 계속 빨간 상태로 남음, Tester 지적). **[범위 정정, Task 5 Tester/Audit, 2026-07-28] 이 known issue 대상이 실제로는 5개 스위트로 더 넓음** — `composition_style_log_main_screen_test.dart`(1건)/`closet_main_shell_widgets_regression_test.dart`(3건)/`gallery_meta_label_extraction_test.dart`(1건)/`classification_drilldown_test.dart`(4건)/`style_log_gallery_column_count_test.dart`(1건)도 전부 같은 원인(`c07`/`c08`/`comp02` soft-delete로 mock 개수 변화)으로 실패 중임을 Task 5 Tester가 발견, Audit이 `mock_data.dart`/provider 필터 대조로 재확인함. **Task 7은 원래 대상 2개 + 이 5개, 총 7개 스위트의 stale count assertion을 전부 갱신해야 함.** **Task 4(`AppMainScaffold.bottomFloatingActions` 파라미터) 완료(2026-07-28)** — Worker(계획 문서 1053~1136행 TDD 스텝 그대로 따름, 단 테스트는 계획의 bare `MaterialApp` 대신 파일 기존 관례인 `pumpAt` 헬퍼로 작성 — bare `MaterialApp`은 `context.canPop()` 호출 때문에 GoRouter 없이 실패함)→Review(findings 없음, `pumpAt` 대체가 파일 관례에 부합함을 재확인·`FrostedBackButton`과 반대편 anchoring이라 충돌 없음·매직넘버 없음 확인) 사이클 통과. 아직 어떤 화면도 이 파라미터를 실제로 소비하지 않는 순수 인프라 추가라 앱에서 도달 가능한 런타임 동작이 없음 — Task 1/2(모델/Notifier)와 같은 성격으로 판단해 Tester 생략, 위젯 테스트로 렌더링 자체 검증 완료. 커밋 `1e1ae17`. **Task 5(다중선택 시각 지원 — 타일 4종 + 그리드 어댑터 3종) 완료(2026-07-28)** — `MultiSelectCheckmark` 신규 위젯 + 4개 갤러리 타일(`selectable`/`composition`/`style_log`/`trash_gallery_tile.dart`)에 `onLongPress`/`multiSelectMode`/`selected` 배선(체크서클은 `multiSelectMode`일 때만 렌더 — 구 초안 P0 버그였던 "selected만으로 렌더" 재발 없음, 4곳 전부 Review가 개별 확인), 3개 그리드 어댑터(`grouped`/`composition`/`style_log_gallery_grid.dart`)에 `multiSelectMode`/`selectedIds`/`onItemLongPress` 배선. `trash_main_screen.dart`+`gallery_meta_label_extraction_test.dart`의 `remainingDays`→`daysUntilPurge` 콜사이트 최소 수정 포함(계획서 Step13 사전승인 범위). Worker(스코프 밖 파일 수정을 스스로 플래그하며 투명하게 보고)→Review(findings 없음, 플래그된 스코프 확장도 타당하다고 확인)→Tester(PASS, 신규 `multi_select_visual_support_test.dart` 10개 + 기존 회귀 스위트 재실행, 위 known issue 범위 확장을 발견)→Audit(P0/P1 없음, P2 1건+P3 2건은 `TechnicalDebt.md`에 기록) 전체 사이클 통과. Task Size L(8개 프로덕션 파일)로 판단해 Audit까지 완료. 커밋 `4487d29`. **Task 6(`GlassToast` 위젯) 완료(2026-07-28)** — Overlay+`GlassPill` 기반 신규 위젯. Worker(계획의 `Future.delayed`를 취소 가능한 `Timer`로 교체 — `flutter_test`의 pending-timer 불변조건 위반 회피, 정당한 편차)→Review(1차: P1 2건 — A13 라이브리전 누락, `UndoableActionToast`와의 외견상 중복)→PM이 `docs/superpowers/specs/2026-07-21-multi-select-and-trash-design.md` §5 근거로 공존이 의도된 것임을 확인(`Decision.md` 신규 항목 참고)→Worker(접근성 추가+docstring 보강+`AppDurations.toastDefault` 공용 상수 추출)→Review(2차 PASS) 사이클 통과. 아직 어떤 화면도 소비하지 않는 순수 신규 위젯이라 Task 4/1/2와 같은 성격 — Tester 생략. 커밋 `a890c61`.

**Task 7(`GalleryMainScreen<T>` 셸 신설 + 옷장 메인 마이그레이션) 완료(2026-07-28)** — 신규 제네릭 셸(`lib/widgets/gallery_main_screen.dart`, Task 4/5/6을 전부 소비 — `bottomFloatingActions`/타일·그리드 다중선택 파라미터/`GlassToast`)이 다중선택 상태(모드 토글/선택 id 집합)를 전담, `closet_main_screen.dart` 전면 재작성으로 기존 분류/드릴다운/밀도/정렬 로직 유지하며 다중선택 삭제(연결된 코디 있으면 확인 팝업, `GlassToast` undo) 추가. `selection_aware_header_actions.dart`를 X버튼 전용으로 좁힘(중복 "선택" 버튼 렌더링 버그 해소). Worker→**Review 4라운드**(① 재발한 stale-closure 버그를 소비 화면에서 우회 수정 + 미완성 아이템 테스트데이터 교체, 둘 다 타당 확인 ②③④ PM이 스코프를 잘못 좁혀줘서 놓친 stale count 스위트들을 라운드마다 하나씩 추가 발견·수정 — `composition_style_log_main_screen_test.dart`/`settings_trash_shell_test.dart` 포함 최종 8개 파일)→Tester(PASS, 신규 통합테스트 6개 시나리오 + 기존 4개 스위트 재확인)→**Audit**(P0/P1 2건: 이 커밋이 안 돼 있었던 것 자체 + BACKLOG 미갱신 → 이번 커밋으로 해소, `comp02` 소프트삭제로 깨진 통합테스트 4개 추가 발견 → Task 7과 무관한 별도 `TechnicalDebt.md` 항목으로 기록) 전체 사이클 통과. 커밋 `7763214`(본체, 12개 파일)+`2afd52a`/`d5f22fb`(TechnicalDebt 기록)+`30c63f7`(Task 8 계획서 stale-closure 패턴 사전 정정). **Task 8(코디 메인 마이그레이션) 완료(2026-07-28)** — `composition_main_screen.dart`을 `GalleryMainScreen<Composition>`으로 재작성(계절/날씨/날짜 드릴다운 유지, `GalleryMainScreen`이 다중선택 상태를 전담하므로 `ConsumerWidget` 유지 — Task 7의 `ClosetMainScreen`이 stateful인 건 무관한 기존 이유 때문). 코디는 옷장과 달리 "사용 중" 확인 팝업 없음(코디 자체를 참조하는 개념이 없어서). Worker(계획 편차 0건 — Task 7 Review가 이미 정정해둔 stale-closure 패턴 그대로 재사용)→Review(P3 1건뿐, comp02 소프트삭제로 실제로는 코디 2개(comp01/comp03) active인데 Worker 테스트가 1개 선택 시나리오만 다뤄 2개 선택 경로가 미검증이라는 지적, 논블로킹)→Tester(PASS, Review가 지적한 2개 선택 경로까지 직접 검증 — `composition_multi_select_two_item_test.dart` 신규, 드릴다운 상태에서의 다중선택 상호작용도 확인) 사이클 통과. Task Size M(단일 화면 마이그레이션, 셸 자체는 이미 존재)이라 Audit 없이 완료 처리. 커밋 `0c5360d`. **Task 9(스타일일지 메인 마이그레이션 — 플랫형 첫 검증) 완료(2026-07-28)** — `style_log_main_screen.dart`을 `GalleryMainScreen<StyleLog>`로 재작성, `classification`을 아예 안 넘겨(`null` 기본값) 그룹형 캡슐/밀도·정렬 토글이 전혀 안 그려지는 첫 실사용 사례. Worker(계획의 `pumpApp` 헬퍼가 실제 UI와 안 맞아 `composition_style_log_main_screen_test.dart`의 실제 `goToCategory` 패턴으로 대체 — 계획 자체가 이 대체를 미리 허용해둠)→Review(findings 없음 — `classification:null`이 코드상 실제로 캡슐/토글을 아예 안 만드는지 셸 소스까지 직접 확인)→Tester(PASS, 2개 선택/X취소/FAB숨김까지 전부 확인) 사이클 통과. Task Size M이라 Audit 없이 완료 처리. 커밋 `c0e173e`. **Task 10(휴지통 메인 마이그레이션 + 복원/영구삭제/비우기 실행) 완료(2026-07-28)** — `trash_main_screen.dart` 전면 재작성, `GalleryMainScreen<T>` 안 쓰고 `AppMainScaffold` 직접 배선(복원+영구삭제 2버튼/탭=정보팝업/필터칩). 3도메인 실제 복원/영구삭제 실행 배선(`restoreMany`/`purgeMany`), 영구삭제만 확인 다이얼로그(복원은 가역이라 확인 없음), "비우기" 확인 다이얼로그. Worker가 실제 버그 하나 발견+수정(`showModalBottomSheet`에 `isScrollControlled: true` 필요 — 이미지 추가로 기본 높이 상한 넘어 오버플로). Worker→Review(P2 1건, 정보팝업이 스펙과 3가지 시각적으로 어긋남 — 계획 문서 자체의 갭, `TechnicalDebt.md` 기록)→Tester(PASS, 필터칩/교차화면 복원검증/필터중 다중선택 영구삭제/0개 선택 비활성화 등 6개 시나리오)→Audit(P0/P1: 이 커밋 자체가 안 돼 있었던 것+BACKLOG 미갱신 → 이 커밋으로 해소, P2: 휴지통 다중선택 "닫기"가 다른 3화면과 다른 위젯 사용→`TechnicalDebt.md` 기록, **Task 12는 이미 Group C Task 1에서 만족됨 확인** — 스킵) 전체 사이클 통과. 커밋 `03b7c64`(본체)+`c50b70b`(TechDebt 기록). **다음 세션은 Task 11(Detail 3화면 "더보기" 메뉴 — 실제 [삭제] 연결, 계획 문서 3509행~)부터** — Task 12(설정→휴지통 진입 로우)는 이미 완료돼 스킵, Task 13(문서 갱신 마무리)만 Task 11 이후 남음. **이로써 13개 Task 중 11개 완료, Task 11/13 두 개만 남음 — 이번 계획(`2026-07-21-multi-select-and-trash.md`) 거의 종료 단계.** 스펙 `docs/superpowers/specs/2026-07-21-multi-select-and-trash-design.md`(review 2회 통과, `GalleryMainScreen<T>` 제네릭 셸로 4개 Main형 화면 통합 + `deletedAt` 기반 휴지통), 구현계획 `docs/superpowers/plans/2026-07-21-multi-select-and-trash.md`(13 Task, review 1회 + 프로젝트 전체 홀리스틱 Audit 1회 통과, 지적사항 전부 반영 — "선택" 버튼 중복 렌더링 버그, 휴지통 정보팝업 이미지/제작일 누락, 옷 삭제 시 코디 사용 개수 사전경고, 필터칩 선택표시 등).
     - **병렬 세션 확인(2026-07-21, 2차 재확인 완료)**: `../Digital-Wardrobe-composition-artboard` worktree(브랜치 `feature/composition-artboard-widget`)에서 코디 아트보드(`InteractiveArtboard`) 작업이 동시 진행 중. 1차 확인 시엔 그 브랜치가 스펙/계획 문서뿐이었으나, 재확인 시점엔 이미 실제 코드 커밋(`45b04ba feat(artboard): add ArtboardItem data model` — `lib/widgets/interactive_artboard/artboard_item.dart`+테스트, 2줄 요약: 신규 파일만)이 착수된 상태였음 — 그래도 여전히 `lib/widgets/interactive_artboard/`에만 격리돼 있어 그룹 B가 건드리는 파일(`composition.dart`/`composition_providers.dart`/`composition_main_screen.dart`/`composition_detail_screen.dart`/`composition_editor_screen.dart`)과 **겹치는 파일 없음** 재확인됨. 그 스펙이 "Composition/ClothingItem/Riverpod provider에 zero dependency, 기존 파일 무수정"을 명시(§1,§2,§6)하고 있어 이 격리가 우연이 아니라 설계 원칙임 — 다만 이 원칙 자체가 지켜지는지, 그리고 아트보드 쪽이 `composition_editor_screen.dart`를 실제로 배선하는 단계에 들어가는 순간부터는 겹칠 수 있으니 그룹 B의 Task 8/11(코디 메인/Detail) 착수 직전에 한 번 더 `git log origin/dev..feature/composition-artboard-widget --stat`로 재확인할 것.
     - Detail 화면 "⋯더보기" 메뉴는 사실상 이 그룹 소속(유일한 항목이 [삭제]) — 그룹 B 계획 Task 11에 포함됨.
   - **그룹 C(설정 나머지 — 알림/다크모드/휴지통 진입/로그아웃)**: 스펙 확정(2026-07-27, `docs/history/Decision.md` "설정 화면 최종 로우 구성 확정" 항목/`04_설정.md` §2·§4·§6) + 그 결정문서 커밋 완료(`d95d32e`). **Task 1(화면 로우 재구성) 완료(2026-07-27)** — Worker 구현→Review 1회 PASS(P3 1건 PM 직접 수정)→Tester 1차(FAIL: 신규 "실행취소" 테스트가 `pump()` 1프레임만 써 SnackBar 슬라이드인 애니메이션 중에 탭해 빗나감)→Worker(그 줄만 `pumpAndSettle()`로 수정)→Review 재검토 PASS→Tester 재검증 PASS 전체 사이클 통과. Task 크기 S/M이라 Audit 없이 완료 처리. 커밋 `3ca9d6c`(`lib/screens/settings_screen.dart`, `lib/widgets/undoable_action_toast.dart` 신규, 통합테스트 2개 수정).
     - **Tester가 재확인한 pre-existing 회귀 2건(이 Task가 만든 것 아님, `git stash` 대조로 확인, 이미 Task 3 때 disclose된 known issue)**: `closet_main_screen_test.dart` 8개 실패(FAB 펼침/접힘, `/trash` push 렌더링, 그리드 라벨 등), `settings_trash_shell_test.dart`의 TrashMainScreen 그룹 5개 실패(mock 휴지통 항목 4개 기대 vs 3개 렌더링). 위 "다음 세션 작업" 1번 그룹 B 서술대로 **Task 7(옷장 메인 마이그레이션)이 이 stale assertion 갱신을 반드시 포함해야 함** — 여전히 미해소.
     - **Task 2(다크모드 실동작 배선, Layer=Logic/Feature) 완료(2026-07-28)** — `lib/providers/theme_providers.dart` 신규(`ThemeModeNotifier extends StateNotifier<ThemeMode>`, `set(bool)`), `main.dart`가 `themeModeProvider`를 watch해 `MaterialApp.themeMode`에 연결, `SettingsScreen`이 `ConsumerStatefulWidget`으로 전환돼 다크모드 `Switch`가 이 provider를 읽고 씀(알림 스위치는 그대로 로컬 상태 유지 — 백엔드 기능 없음). Worker→Review(1차: P2 `theme_providers_test.dart` 누락 + P3 미사용 `toggle()` 발견)→Worker(addendum: 테스트 3종 추가 + `toggle()` 제거)→Review(2차 PASS)→Tester(PASS, `dark_mode_toggle_test.dart` 4개 시나리오 — 토글 왕복, 화면 이동 후에도 유지, 세션 내 상태 보존, 연타 안정성 — 전부 통과, 기존 `settings_trash_shell_test.dart` 회귀 없음 재확인) 전체 사이클 통과. Task Size S/M이라 Tester 통과 후 Audit 없이 완료 처리. 커밋 `552eb7a`. **이로써 그룹 C(설정 나머지) 전체 완료** — 로우 4개(알림/다크모드/휴지통 진입/로그아웃) 전부 실동작 배선 끝(알림은 스펙상 UI 토글까지만이 스코프, 백엔드 없음 — §2 로우1 참고).
     - **로그아웃 로우 관련 참고(사용자 확인, 2026-07-27)**: 로그아웃은 MVP에서 실기능 없음(세션/인증 시스템 자체가 없어 `_handleLogout`의 `onUndo`/`onExpire`는 빈 콜백). 나중에 이 로우를 숨겨야 할 때는 지금 미리 feature flag를 만들지 말고, 그 시점에 로우를 지우는 일반 커밋으로 처리할 것(불필요한 사전 추상화 금지 원칙).
     - **세션 운영 참고**: Review/Tester가 같은 Task 안에서 재검토가 필요해지면 새 에이전트를 스폰하지 말고 기존 에이전트에 `SendMessage`로 이어서 시킬 것 — 레퍼런스 문서를 다시 안 읽어도 돼 토큰이 크게 절약됨(캐시 TTL 1시간 내에서 유효, 사용자와 이번 세션에서 합의).
   - **그룹 D(에디터급 이월 항목 — 겹친 아이템 팝업/아트보드 실제 렌더링/추가사진 드래그 순서변경/신규 생성 바인딩)**: 아직 스펙 착수 전. "Editor Draft 구현"(별도 후속 작업)과 인프라 상당 부분 겹칠 가능성 높음 — 아트보드 렌더링은 그룹 B의 코디 삭제 캐스케이드용 스냅샷 아키텍처와도 연결됨.
   - **"Editor Draft 구현"(Step⑦ 전체 완료 후 별도 후속 작업)**: 도메인별 `draftsProvider`(`ClothingItemDraft`/`CompositionDraft`/`StyleLogDraft`) 신설, `EditorHeader.onCancel`/`AutoSaveIndicator` Draft 기준 배선, Editor 3화면 실제 Commit/Cancel 로직, `isIncomplete` 토글 로직. Recovery는 세션 내 복원만 범위(앱 강제종료 후 복원은 제외). 착수 전 `AutoSaveIndicator` 독스트링/Editor 3화면 skeleton 라벨의 구 정책("상시 저장" 서술) 정리도 함께(P2, Audit 2026-07-15 발견).
2. **그룹 A Audit(2026-07-19, Task 7 직후) 발견 P2/P3 — 다음에 해당 파일 손댈 때 픽업**:
   - (P2) `02_코디 (가상 조합).md` 8행 "정렬/필터에 날씨·계절 기준 지원(스타일 일지와 공통)" 문구가 실제 구현(코디는 날짜/계절/날씨 3기준, 스타일일지와는 메커니즘 자체가 다름 — 그룹형 드릴다운 vs 플랫+필터)과 어긋남. 이 파일을 다음에 손댈 때 2026-07-19 스펙을 근거로 갱신.
   - (P2) `lib/widgets/classification_group_card.dart`의 라벨 배지 `vertical: 2` 패딩이 `AppSpacing` 미등재 매직넘버 — `docs/history/TechnicalDebt.md`에 이미 기록됨, 이 파일 다음에 손댈 때 정리.
   - (P3) `flutter analyze` 미등재 lint 경고 2건 추가 확인(`style_log_gallery_column_count_test.dart`의 `go_router`/`style_log_cross_reference_gallery` unused import) — 기존 `typography_pass3_test.dart` 항목에 함께 기록됨(`TechnicalDebt.md`), 이번 그룹 A 작업과는 무관한 기존 부채.
3. **2차(최종) Audit(2026-07-16, Task 9 직후) 발견 P2/P3 — 여전히 미픽업, 다음 Step⑦ 나머지 스코프(그룹 B~D) 착수 전 검토**:
   - (P2) 옷 상세의 코디 캐러셀/스타일일지 갤러리 섹션에 제목(라벨) 누락 — 코디 상세는 "사용된 옷"/"연결된 스타일일지" 타이틀을 붙이는데 옷 상세는 안 붙임, 비대칭. `closet_item_detail_screen.dart`에 "연결된 코디"/"연결된 스타일일지" `Text(titleSmall)` 헤더 추가로 간단히 해소 가능.
   - (P2/P3) "착용 옷"(구 "추가 사진")이 스타일일지 열람의 스와이프 카드 슬롯 구조(대표이미지→코디 슬롯)에 포함돼야 하는지 미확정 — `03_스타일 일지.md` 23-24행 문언은 포함되는 것처럼 읽히나, 현재 구현(Task 8)은 별도 가로 스크롤 섹션으로 둠. 사용자 확인 필요(다음 세션 질문 후보).
   - (P3) `docs/history/Decision.md` "Detail 화면 상호참조를 텍스트 칩 → 썸네일 캐러셀/갤러리로 확장" 항목의 Impact 문단에 남은 초안 시절 Task 번호(정정 각주로 이미 보강함, `docs/history/Decision.md` 참고) — 추가 조치 불필요, 기록만.
   - ~~(P3) `expandSingle` 파라미터 비대칭~~ **해소(2026-07-18, Task 12)** — 파라미터 자체가 삭제되어 두 화면 모두 항상 정사각형으로 통일됨.
   - (P3) `flutter analyze` 미등재 lint 경고 2건(`integration_test/header_hud_stack_architecture_test.dart:200`, `integration_test/settings_trash_shell_test.dart:86`) — 기존 `typography_pass3_test.dart` 항목과 같은 성격, 다음에 해당 파일 손댈 때 정리.
- ~~Detail 3화면 보일러플레이트 중복~~ **완료(2025-07-15)** — `AppDetailScaffold`로 해소. 이후 Task 9(2026-07-16)에서 `crossReferenceEntries` 계약 자체를 폐기(`CrossReferenceLinkBar`도 삭제) — TechDebt 항목 해소됨.
- (P2) `AppDetailScaffold`(`lib/screens/app_detail_scaffold.dart`)가 같은 역할의 `AppMainScaffold`(`lib/widgets/`)와 달리 `lib/widgets/`가 아닌 `lib/screens/`에 배치됨 — Audit(2026-07-15) 발견, 근거가 약한 배치. 호출부가 3곳뿐인 지금이 이동 비용이 가장 쌈, 급하지 않음.
- 6번째 UI 블록 중복 사례(Editor 3화면 `EditorHeader`+`skeletonRegion` 보일러플레이트, P3, Audit 2026-07-15 발견) — "Editor Draft 구현" 착수로 어차피 재작성될 예정이라 의도적으로 추출 보류(`docs/history/TechnicalDebt.md` 참고).
- 코디 타일 표시 방식(Audit P1, Step③ 때 발견)은 `coverImagePath` 필드 신설(Task 5, 2026-07-16 완료)로 착수 비용이 낮아짐 — `CompositionGalleryTile`(코디 메인 그리드) 이미지 업그레이드는 여전히 미착수(TechDebt 참고).
- 코디 아이템 개수 상한 15개(`Decision.md` 확정, 2026-07-16) — 실제 코드 반영은 Editor 구현 시점.
- Scrollbar / Scroll Hint(`<`/`>`)는 프로젝트 공용 디자인 후보로 유지 — 이번 라운드엔 제작 안 함. 실제로 만들 때 지킬 계약(Overlay, 레이아웃 비침습)은 위 스펙 §3/§6에 이미 정의됨.
- ~~휴지통 mock provider에 삭제 시각(`deletedAt`) 필드가 없어 실제 3-domain 집계 전환 시 "N일 남음" 계산 불가~~ **그룹 B 계획(Task 1/3)에 해결책 포함됨(2026-07-21, 아직 미착수)** — `deletedAt` 필드를 3개 모델에 추가하고, `mockTrashEntries`/`TrashEntriesNotifier` 자체를 삭제해 3-domain 파생 집계(`trashEntriesProvider`)로 교체. `t3`의 상한 초과값 문제도 이 교체로 자동 해소(더 이상 존재하지 않는 mock). 별도로 손댈 필요 없음 — 그룹 B Task 1/3 진행 시 함께 처리됨.
- ~~`ClothingItem`의 category/season/color/material 4개 필수 필드를 선택 필드로 전환(nullable화)~~ **완료(2026-07-19)** — Worker→Review(1차 P0 발견·재작업)→Review(2차 통과)→Tester 전체 사이클 통과, 실제 영향 파일은 애초 집계(13개)보다 훨씬 좁은 4개였음. 상세는 `docs/history/Decision.md` 해당 항목의 "상태" 줄 참고. 후속으로 필요했던 옷장·코디 메인 헤더 스펙의 "옷장은 미분류 없음" 전제 갱신도 같은 날 완료(커밋 `e7e6b73`, 위 1번 그룹 A 항목 참고) — 더 할 일 없음.

---

# Next

- ~~`ui-ux-pro-max` 플러그인에서 Flutter 관련 내용만 추출해 프로젝트 로컬 스킬로 이식~~ **완료(2026-07-18)** — `feature/flutter-ui-reference-skill` 브랜치(저장소 바깥 sibling worktree)에 방치돼 있던 450줄 초안을 이어받아 검증 후 커밋. 검증 내용: (1) Flutter 52개 가이드라인·팔레트/폰트 표 샘플을 원본 플러그인 로컬 캐시(`~/.claude/plugins/marketplaces/ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max/data/*.csv`)와 대조해 추출 정확성 확인, (2) 라이선스 고지문이 원본 `LICENSE` 파일과 정확히 일치함을 재확인(MIT, Copyright Next Level Builder). 산출물: `.claude/skills/flutter-ui-reference/SKILL.md`. 후속 조치로 `.claude/settings.json`에 `"ui-ux-pro-max@ui-ux-pro-max-skill": false` 추가해 이 프로젝트에서만 원본 플러그인(7개 스킬: banner-design/brand/design/design-system/slides/ui-styling/ui-ux-pro-max) 비활성화 — 전역 설정은 그대로 둬서 다른 프로젝트는 영향 없음.

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

(2026-07-13 발견) **Windows에서 `flutter test integration_test/<file> -d windows` 연속 실행 시 파일 잠금으로 빌드 실패.** 이전 실행의 `digittal_wardrobe.exe` 프로세스가 종료되지 않고 남아있으면(`tasklist`로 확인 가능) 다음 빌드가 그 exe를 "쓰기용으로 열 수 없다"(`LINK : fatal error LNK1168`)며 실패한다. **예방**: 통합테스트 파일을 여러 개 순차 실행할 때마다 사이사이 `taskkill //F //IM digittal_wardrobe.exe`(PowerShell/Git Bash 기준, 이미 실행 중인 게 없으면 에러 무시하고 넘어가도 됨)로 강제 종료할 것. Windows가 이 프로젝트에서 `integration_test`를 돌릴 수 있는 사실상 유일한 non-web 디바이스라(Chrome/Edge는 "Web devices are not supported for integration tests yet") 이 문제를 피할 방법이 없음 — 항상 위 예방 조치를 습관화할 것.

(2026-07-13 발견) **`windows/runner/*.cpp`(네이티브 Windows 러너 보일러플레이트)에 non-ASCII(한글 등) 주석을 넣으면 MSVC 빌드가 깨짐.** 이 파일들이 BOM 없는 UTF-8이라 MSVC가 시스템 코드페이지로 해석을 시도하며 non-ASCII 문자에 C4819 경고를 내고, `windows/CMakeLists.txt`의 `/W4 /WX`가 이를 에러로 승격시켜 빌드 자체가 실패한다(실측: `main.cpp`에 넣은 한글 주석 하나가 원인, 커밋 `fab826a`에서 영어로 교체해 해결). `lib/`(Dart)는 이 프로젝트 관례대로 한글 주석을 계속 써도 무방 — 이 문제는 `windows/` 네이티브 C++ 파일에만 해당. **예방**: `windows/runner/` 아래 파일을 건드릴 땐 주석을 영어로 쓸 것.

---

(2026-07-13 재발·재해소, 원인 정정) `.claude/worktrees/policy-doc-versioning-audit/` 등 stale worktree 4개(2026-07-12 정리) 이후에도 고아 디렉토리 2개(`policy-audit-fix`, `setting-ui-temp`)가 남아있었음 — `setting-ui-temp`는 이미 pruned된 `policy-doc-versioning-audit` 메타데이터를 가리키는 죽은 `.git` 포인터를 갖고 있어, 그 정리 이후로도 계속 검색을 중복시키고 있었던 것으로 추정(`rm -rf`로 지워 `git worktree remove`를 안 거친 게 원인으로 보임). 2026-07-13에 재발견·삭제 완료.
**원인 정정**: 2026-07-12 기록엔 "이 worktree들이 gitignore 안 돼 있어서"라고 돼 있었으나, 이후 `.claude/worktrees`는 실제로 `.gitignore`에 등록돼 있었음에도 Glob이 여전히 매칭하는 걸 확인 — 진짜 원인은 **이 환경의 Grep/Glob 도구가 `.gitignore`를 아예 참조하지 않는 것**(gitignore 대상인 `.dart_tool/`도 그대로 매칭됨으로 검증). 재발 방지로 `Workflow_Project.md` §15 신설 — 앞으로 병렬 세션용 worktree는 저장소 바깥 형제 디렉토리로만 생성(상세: `Decision.md` 최상단).

---

# Parking Lot

MVP 명세상 Phase 2/3로 의도적으로 제외된 항목 (`00_MVP.md` §2 참고):

- Composition calendar (Phase 2)
- 실사진 위 핫스팟 레이어 (Phase 2)
- 추천/피드/팔로우 (Phase 3)
- 커스텀 그룹(폴더) (Phase 2~3)
