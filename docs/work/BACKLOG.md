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

**Group B 종료(자리비움 세션) 직후, 사용자 복귀해 앱을 직접 구동하며 Visual Review 진행(2026-07-29)** — 사용자가 실제 조작하며 버그 3건+시각수정 2건 발견, 전부 그 자리에서 Worker→Review→Tester 사이클(파일별 독립 병렬 진행)로 수정 완료:
1. 옷장 다중선택 모드 중 "미완성" 배지 아이템 탭이 무시되던 버그(`selectable_gallery_tile.dart`) — 커밋 `e6c7cff`.
2. 스타일일지 열람 이미지→코디 스와이프가 실제 마우스 드래그로 안 되던 버그 — Flutter 기본 `MaterialScrollBehavior`가 `dragDevices`에서 mouse를 제외하는 게 원인, 앱 전역 `AppScrollBehavior`로 해소(`lib/main.dart`) — 커밋 `3d8fa43`.
3. `GlassToast` "실행취소" 버튼 가시성 부족 — `primaryLight` 배경 추가 — 커밋 `bd923af`.
4/5. 휴지통 필터칩 가로 오버플로 해소(스크롤) + 단일선택→다중선택 전환 — 커밋 `8021b81`.
전체 배치 Tester 통과 후(신규 크로스컷팅 회귀테스트 `9191aca`) **Task 크기 L로 판단해 Audit 실행** — P1 1건 발견: 이 배치가 쓴 `primaryLight` 토큰이 다크모드에서 `colorScheme.primary`와 완전히 같은 값이라 방금 고친 버튼 텍스트가 다크모드에선 여전히 안 보임. 즉시 수정(HSL 명도만 낮춰 새 값 도출, `gray800` 재사용은 다른 위젯 하이라이트가 묻혀서 기각) → Review→Tester(다크모드 실기기 구동, 4개 소비처 전부 확인) 통과 — 커밋 `0c16786`+`db4d75c`(Decision 기록). **병렬 세션 관련 참고**: Worker 4개를 동시에 같은(worktree 격리 안 된) 작업 디렉토리에 돌렸더니 일부가 각자 `git stash`로 A/B 비교하다 서로 부딪히는 레이스가 있었음(외부 세션 아님, 자기 자신들끼리) — PM이 combined 상태를 전체 재검증(`flutter analyze`+전체 `flutter test`+관련 통합테스트 6개 개별 재실행)해서 무결성 확인 후 진행함. **다음에 병렬 Worker를 여러 개 띄울 땐 git stash 등 working tree를 건드리는 작업을 하지 말라고 명시하거나, 정말 필요하면 순차 진행할 것.**

---

# Current

**미착수 — 스타일일지 메인 필터/정렬 UI 전체 구현(사용자 발견 버그2, 확인 필요)**: 스펙(`03_스타일 일지.md` 7-10행)이 "정렬/필터: 날짜/옷종류/날씨/계절 4기준+역순"을 요구하는데 현재 `style_log_main_screen.dart`는 이 UI가 통째로 없음(Task 9가 `classification: null`로 넘겨서 그룹/정렬 캡슐 자체가 안 그려짐). 사용자가 "지금 바로 전체 구현" 확정했으나, 착수 중 `StyleLog` 모델에 계절/날씨/옷종류 필드 자체가 없다는 걸 발견 — 데이터 소스를 (A) 연결된 코디에서 파생 (B) 착용 옷 이미지경로 매칭으로 역추적 (C) `StyleLog`에 필드 직접 추가 중 뭘로 할지 사용자 확인 요청 중, 답변 대기.

**Step⑦ 나머지 스코프 진행 상황 — 그룹 A/B/C 완료, 그룹 D 미착수**: 그룹 A(그룹형 드릴다운, 2026-07-19)/그룹 B(다중선택+휴지통, 13 Task 전부 완료)/그룹 C(설정 나머지 — 다크모드 실동작 포함, 2026-07-28) 전부 완료. 상세 경위는 `Decision.md`/git log(태그: Task 이름으로 검색)가 1차 소스, 이 파일은 더 이상 Task별 세부 내역을 보존하지 않음.
- **그룹 D(에디터급 이월 항목 — 겹친 아이템 팝업/아트보드 실제 렌더링/추가사진 드래그 순서변경/신규 생성 바인딩)**: 아직 스펙 착수 전. "Editor Draft 구현"과 인프라 상당 부분 겹칠 가능성 높음 — 아트보드 렌더링은 그룹 B의 코디 삭제 캐스케이드용 스냅샷 아키텍처와도 연결됨. 착수 전 `../Digital-Wardrobe-composition-artboard` worktree(`feature/composition-artboard-widget`, 코디 아트보드 `InteractiveArtboard` 병렬 작업)가 `composition_editor_screen.dart`를 실제로 배선하는 단계에 들어갔는지 `git log origin/dev..feature/composition-artboard-widget --stat`로 재확인할 것(그 전까진 `lib/widgets/interactive_artboard/`에만 격리돼 파일 겹침 없음, 2026-07-21 확인).
- **"Editor Draft 구현"(별도 후속 작업, Step⑦ 전체 완료 후)**: 도메인별 `draftsProvider`(`ClothingItemDraft`/`CompositionDraft`/`StyleLogDraft`) 신설, `EditorHeader.onCancel`/`AutoSaveIndicator` Draft 기준 배선, Editor 3화면 실제 Commit/Cancel 로직, `isIncomplete` 토글 로직. Recovery는 세션 내 복원만 범위. 착수 전 `AutoSaveIndicator` 독스트링/Editor 3화면 skeleton 라벨의 구 정책("상시 저장" 서술) 정리, Editor 3화면 `EditorHeader`+`skeletonRegion` 보일러플레이트 중복(P3) 추출도 함께 검토. 착수 시 아이템 개수 상한 15개(`Decision.md` 확정)도 실제 코드에 반영.

**미픽업 P2/P3 백로그 (다음에 해당 파일 손댈 때)**:
- (P2) `02_코디 (가상 조합).md` 8행 "정렬/필터에 날씨·계절 기준 지원(스타일 일지와 공통)" 문구가 실제 구현과 어긋남 — 2026-07-19 스펙 근거로 갱신.
- (P2) 옷 상세의 코디 캐러셀/스타일일지 갤러리 섹션에 제목(라벨) 누락 — 코디 상세는 타이틀 붙는데 옷 상세는 안 붙음(비대칭). `closet_item_detail_screen.dart`에 `Text(titleSmall)` 헤더 추가로 해소 가능.
- (P2) `AppDetailScaffold`가 같은 역할의 `AppMainScaffold`와 달리 `lib/screens/`에 배치됨(`lib/widgets/`가 자연스러움) — 호출부 3곳뿐인 지금이 이동 비용 최저.
- (P1) `CompositionGalleryTile`(코디 메인 그리드) 이미지가 아직 텍스트 전용 — `coverImagePath` 필드는 이미 있어 착수 비용 낮음.
- (P3) Scrollbar / Scroll Hint(`<`/`>`)는 프로젝트 공용 디자인 후보로 유지, 아직 미제작. 계약(Overlay, 레이아웃 비침습)은 `2026-07-13-scroll-container-and-header-hud-architecture.md` §3/§6 참고.
- (P3) `flutter analyze` 미등재 lint 경고 다수(`typography_pass3_test.dart` 항목에 누적 기록 중, `TechnicalDebt.md` 참고) — 급하지 않음, 해당 파일 손댈 때 정리.

**TechDebt — `AppMainScaffold` 헤더 오버레이 때문에 widget test hit-test가 어긋남(P3)** / **코디 삭제(`composition_main_screen.dart`+`composition_detail_screen.dart` 두 진입점 다)에 "사용 중" 경고 없음(P2)** — 둘 다 `TechnicalDebt.md` 참고, 급하지 않음.

**미확인 — `GlassToast` 히트박스 수정이 사용자가 원래 보고한 증상과 완전히 같은 것인지 사용자 직접 재검증 예정.**

**판단 보류 — Visual Review 트리거 시점**: Group B 완료 시점에 트리거하기로 사용자 확정된 밀린 Visual Review(`Decision.md`/`Workflow_Design.md` §2.1)를 PM이 혼자 스크린샷 보고 판정할지, 사용자가 직접 볼지 미정 — 사용자 부재 중이라 보류, 상세는 `docs/work/Questions.md` 참고. **그룹 B가 이제 완전히 끝났으니 다음 세션 시작 시 최우선으로 재검토할 것.**

---

**병렬 작업 완료(2026-07-23) — 하네스 파이프라인 보완 + 문서 구조 개편**: `../Digital-Wardrobe-pipeline-docs` worktree(`feature/pipeline-docs-restructure`, `feature/flutter-hifi-screens`에서 분기)에서 아래 3건을 독립적으로 완료, `dev`로 PR 대기 중 — 이 Current 항목(Group B 등)과는 무관한 별도 스레드라 그대로 계속 진행하면 됨.
1. Task 완료 시 "세션 내 후속 작업 없음" 판단되면 BACKLOG.md만으로 새 세션이 이어받을 수 있는지 시뮬레이션 후 문제없으면 `/clear` 권유 — `Workflow_Project.md` §3 신설, CLAUDE.md 체크포인트 7번.
2. 설계/계획(Decision 단계) 산출물은 크기 무관 확정 전 Audit 필수 — `Workflow_Project.md` §5 "Decision-Stage (Design & Plan) Pipeline" 신설 + §12.1 표 갱신, `.claude/agents/audit.md` 트리거 추가. 이 플랜 자체가 이 원칙의 첫 적용 사례(Review 1회+Audit 1회 통과 후 확정).
3. `.claude/policies/`·`docs/reference/`의 라우터+앵커 구조(부모+서브파일 24개, 5개 그룹) 단일 파일로 재통합 + TOC 추가, 저장소 전체 상호참조 갱신(30여 지점) + 병합 결과 독립 Review 1회(P0/P1/P3 전부 없음) 통과. **이후 토큰 비용 재검토로 부분 롤백**(같은 세션, 사용자 피드백) — §12.1 Required Materials에 직접 걸려 Worker/Review에 좁게 자주 dispatch되는 핫패스 2개(`00_DesignPrinciples.md`/`03_화면별UX명세서.md`)는 서브파일 구조로 되돌리고, PM이 스스로 전체를 훑는 빈도가 높아 병합 손해가 작은 정책 문서 3종(`Workflow_Project/Design/Development.md`)만 병합 유지. **최종 상태: 5개 그룹 중 3개만 병합.**
상세는 `docs/history/Decision.md` 최상단 4개 항목 참고.

---

Flutter 프론트엔드 Hi-Fi 화면 스프린트 — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. 원 마감 2026-07-24 경과 후에도 Step⑦ 그룹 B/C 스코프로 계속 진행 중. `feature/flutter-hifi-screens` 브랜치(PR #5/#10으로 dev 병합 완료, 이후 계속 같은 브랜치에서 진행)에서 Subagent-Driven으로 진행.
- 스펙: `docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md`(그룹형 드릴다운/설정 진입점), `2026-07-21-multi-select-and-trash-design.md`(다중선택+휴지통, Group B 근거), `2026-07-13-scroll-container-and-header-hud-architecture.md`(Header/HUD·스크롤 컨테이너). 원 스프린트 계획(2026-07-08)과 그 Task 8~15는 화면 관통 공용 셸 아키텍처로 대체돼 폐기(`Decision.md` 참고).

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

(2026-07-29 발견, Task 11 Review) **Windows에서 `flutter test -d windows`에 통합테스트 파일 2개 이상을 한 번에 넘기면 두 번째부터 "Error waiting for a debug connection: The log reader stopped unexpectedly, or never started."로 실패.** 아래(2026-07-13) 항목의 `LINK : fatal error LNK1168`(빌드 전 파일 잠금)과는 다른 지점 — 이건 빌드는 성공(exe 생성 확인됨)하고 그 다음 실행 단계에서 디버그 커넥션을 못 잡는 것. 개별 파일로 하나씩 실행하면 둘 다 100% 통과 확인됨. **예방**: `flutter test integration_test/a_test.dart integration_test/b_test.dart -d windows`처럼 여러 파일을 한 명령에 묶지 말고, 파일당 한 번씩 개별 실행할 것(아래 파일잠금 예방 조치와 별개로 항상 지킬 것).

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
