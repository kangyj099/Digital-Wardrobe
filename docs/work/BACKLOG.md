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

**Step⑦ 나머지 스코프 — 그룹 A(그룹형 드릴다운 캡슐 + 설정 진입점 이동) 완료 (2026-07-19).** `docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md`를 Task 1~7로 구현 — 옷장/코디 메인의 `groupingBar` skeleton을 `[중분류▾][소분류▾]` 캡슐+3상태(플랫/그룹개요/드릴인) 그리드로 교체, 설정 진입점을 `CategoryToggleDropdown` 메뉴로 이동. 전 Task Worker→Review 통과(일부 P0/P1 재작업 포함, Task 7은 추가로 Tester 12개 신규 테스트+Audit까지 통과, P0 없음). 커밋 4개(`7bc4e84`/`02470c9`/`64f6388`/`6d27c1a`), 문서 갱신(Decision.md/TechnicalDebt.md/구 스펙 2건 정정 각주) 완료. 상세 경위: `docs/superpowers/plans/2026-07-19-classification-drilldown-and-settings-entry.md`, `docs/history/Decision.md` 최상단 항목.

---

# Current

Flutter 프론트엔드 Hi-Fi 화면 10개 스프린트 (마감 2026-07-24) — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치(PR #5로 dev 1차 병합, PR #10으로 dev 2차 병합 완료 2026-07-18 — Task 7~13/Step②~⑦ 1라운드 전체, 같은 브랜치에서 계속 진행)에서 Subagent-Driven으로 진행 중.
- 스펙: `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`(원 스프린트), `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`(화면 관통 공용 셸 스펙 — **§2 "그룹형 드릴다운" 절은 2026-07-19에 정정 각주로 대체됨, 나머지 절은 유효**), `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`(Header/HUD·스크롤 컨테이너 정식 스펙), `docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md`(그룹형 드릴다운 캡슐 + 설정 진입점 최종 스펙, Task 1~7로 구현 완료 — 지금은 이 4개를 함께 따를 것)
- 원 플랜의 Task 1~7만 유효, Task 8~15는 폐기(대체 근거: `docs/history/Decision.md`의 "화면 관통 공용 UI 셸 아키텍처로 전환" 항목)

**다음 세션 작업**:
1. **"Step⑦ 나머지 스코프" 진행 중 — 4개 그룹(A~D)으로 분해, 그룹 A 완료(2026-07-19), 그룹 B부터 이어가면 됨.**
   - ~~그룹 A(그룹형 드릴다운 옷장·코디 2곳 + 설정 진입점 이동)~~ **완료(2026-07-19)** — 위 "Last Completed" 참고. `AppMainScaffold.groupingBar` 슬롯 삭제, `ClassificationDrilldownCapsule`+3상태 그리드 배선, 설정 진입점 이동 전부 반영, 관련 구 스펙 2건(`04_설정.md` §1, `2026-07-12-cross-screen-ui-shell-design.md` §2)에 정정 각주 완료.
   - **그룹 B(다중선택 진입/실행 + 휴지통 복원·영구삭제·비우기)**: 아직 스펙 착수 전 — 다음 착수 대상. 브레인스토밍 중 확인된 것 — `05_삭제 & 휴지통 (Main형, 플랫+필터 변형).md`에 이미 상세 UX 정의 있음(진입점 2가지: [선택]버튼/롱프레스, 즉시휴지통이동+Toast실행취소, 15일 자동영구삭제, 옷 삭제 시 코디 캐스케이드는 스냅샷 아키텍처 전제라 "Editor Draft 구현" 후속으로 공식 이관됨). `ClosetItemsNotifier.softDelete`는 이미 있으나 Composition/StyleLog엔 없음(3-domain 계약 통일 필요). `TrashEntry`는 독립 mock이라 실제 3-domain `isDeleted` 집계로 전환 필요, `deletedAt` 필드 신설 필요(P2, 이미 기록됨). Detail 화면 "⋯더보기" 메뉴는 사실상 이 그룹 소속(유일한 항목이 [삭제]).
   - **그룹 C(설정 나머지 — 알림/다크모드/프로필편집/휴지통 진입)**: 아직 스펙 착수 전. **중요 발견**: `SettingsScreen` 실제 구현이 승인된 스펙(`04_설정.md`, 2026-07-09 확정)과 어긋난 상태(`TechnicalDebt.md`에 이미 P1로 기록됨) — 승인 스펙은 로우 2개(알림 토글, 로그아웃-Toast+Undo)만 규정하는데 실제론 다크모드/프로필편집 로우가 스펙外로 추가돼 있고 로그아웃 로우는 없음. "프로필 편집"은 이 앱에 프로필/로그인 개념 자체가 MVP 기획 어디에도 없어 실체가 불분명(사용자 확인 필요). 다크모드는 코드상 작음(`AppTheme.dark`/토큰 이미 존재, `main.dart`의 `themeMode: ThemeMode.light` 한 줄만 바꾸면 됨)이나 스펙엔 없어 승인 스펙 갱신 여부 결정 필요. 착수 전 사용자가 실제 설정 화면을 먼저 봐야 함(직접 미확인 상태였음).
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
- (P2, 급하지 않음) 휴지통 mock provider에 삭제 시각(`deletedAt`) 필드가 없어 실제 3-domain 집계 전환 시 "N일 남음" 계산 불가 — 모델에 필드 추가 필요. `mockTrashEntries`의 `t3` 항목이 `remainingDays: 27`로 15일 상한을 넘는 값이라 다음에 손댈 때 0~15 범위로 조정.
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
