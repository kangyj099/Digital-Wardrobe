<!--> 프로젝트 현재 상태 스냅샷. 세션 시작 시 여기부터 확인. 항상 최신으로 유지 <-->

# Project

Digital Closet (working title, `digittal_wardrobe`)

Version: 1.0.0+1

Status: 🟡 Hi-Fi UI 구현 단계 (mock 데이터 기반, 실제 Firebase/AI 백엔드 연동 전)

---

# Current Milestone

레이아웃 & 데이터 작업 — 스타일일지 필터 UI, Firestore 데이터 스키마 설계 등. 디자인 시스템 구축(Brand Guide → Hi-Fi Sample → Visual Review → Design Tokens → Component Library, 순서 근거: `.claude/policies/Workflow_Design.md` §2)은 완성 전 보류 상태, Design Tokens는 provisional 유지. 밀린 Visual Review 트리거 시점은 아래 "Current" 섹션의 "판단 보류 — Visual Review 트리거 시점" 항목 참고.

---

# Last Completed

**설정 화면 로그인/로그아웃 토글 로우 구현(2026-08-04)** — 계정 로우 1개가 로그인 상태에 따라 라벨/스타일 전환(로그인 진입점 위치 결정 겸함, `Decision.md` 기록). Worker→Review(P1 2건: 상태전환 타이밍/문서 미반영→수정)→Tester(Fail 1건: 공용 `UndoableActionToast`의 SDK `persist` 기본값 버그 발견→Worker가 `lib/widgets/undoable_action_toast.dart`까지 확장 수정→Review→Tester 재통과, 6/6 Pass) 전체 사이클 완료. 커밋 `379aa04`~`5079a64`(구현), `8b4a863`(문서/정책). 같은 세션에서 `Workflow_Project.md` §12.1 Data/Architecture×Decision 행의 Audit 게이트 누락도 별건으로 발견·수정(버전 3.2).

---

# Current

**PR #20 병합 확인 완료(2026-08-02)** — `dev`로 병합됨(머지 커밋 `afbafe7`). 단, 병합은 커밋 `7425a13` 시점에 일어났고, 그 직후 세션 종료 직전에 만들어진 커밋 `0c14af7`(BACKLOG에 이 감사 계획 표를 기록한 커밋)는 병합 3분 뒤 push돼 PR에 포함되지 못하고 `feature/flutter-hifi-screens`에 고아로 남아 있었음 — `dev` fast-forward 동기화 후 `feature/layout-data-audit` 브랜치를 새로 파고 `0c14af7`를 cherry-pick으로 가져와 반영(커밋 `23a6a55`). 아래 감사 작업은 이 브랜치(`feature/layout-data-audit`, `dev`에서 분기)에서 진행.

**대기 중 — 별도 세션 `feature/db-schema-design`(PR #21, 미병합)에 Firestore 데이터 스키마 확정본이 `docs/reference/architecture/00_DataSchema.md`로 있음.** 이 세션에서 확정한 폴더 분리(`data/`=스키마, `architecture/`=상위구조)와 경로가 어긋나 있어 사용자가 병합 전 `docs/reference/data/00_DataSchema.md`로 옮기기로 함(미착수). PR #21 머지/동기화 시 확인할 것.

**진행 중 — 페이지별 레이아웃/노출 정보값 감사(Layout & Data Completeness Audit), 사용자 승인된 계획, `feature/layout-data-audit`에서 착수(2026-08-02)**: 사용자가 "화면 구성이 원하는 대로 안 나왔다"고 지적 — **역할 분담 재확정: 레이아웃 구조/기능/데이터 바인딩은 PM(Claude) 담당, 시각 디자인 디테일(색상/크기/간격/블러/타이포 등)은 이제 사용자가 직접 담당**(Claude 메모리 `feedback_layout_data_vs_visual_design_scope.md`에 기록 완료, 새 세션에서도 자동 로드됨). 순서 합의: 레이아웃 → 기능 수정/추가 → 데이터 연결 → (디자인 디테일은 사용자가 나중에).

**감사 대상 및 계획(플랜 파일은 세션 로컬이라 여기 원문 보존)**:

| 페이지 | 스펙 파일 | 구현 파일 | 상태 |
|---|---|---|---|
| 옷장 메인 | `01_옷장.md` | `closet_main_screen.dart` | 완성 |
| 옷 상세 | `01_옷장.md` | `closet_item_detail_screen.dart` | 완성(사용자가 "원하는 대로 안 나왔다"고 지적한 페이지, 최우선 점검 후보) |
| 옷 추가 | `01_옷장.md` | `closet_add_screen.dart` | 스켈레톤만(대조 대상 아님) |
| 코디 메인 | `02_코디 (가상 조합).md` | `composition_main_screen.dart` | 완성 |
| 코디 상세 | `02_코디 (가상 조합).md` | `composition_detail_screen.dart` | 완성 |
| 코디 제작(에디터) | `02_코디 (가상 조합).md` | `composition_editor_screen.dart` | 스켈레톤만(대조 대상 아님, "Editor Draft 구현" 착수 전) |
| 스타일일지 메인 | `03_스타일 일지.md`(+`filter.md`) | `style_log_main_screen.dart` | 완성(필터 UI 제외) |
| 스타일일지 열람 | `03_스타일 일지.md` | `style_log_viewer_screen.dart` | 완성 |
| 스타일일지 추가 | `03_스타일 일지.md` | `style_log_add_screen.dart` | 스켈레톤만(대조 대상 아님) |
| 설정 | `04_설정.md` | `settings_screen.dart` | 완성 |
| 삭제&휴지통 | `05_삭제 & 휴지통.md` | `trash_main_screen.dart` | 완성 |

방법(페이지당 동일): (1) 스펙 전문에서 레이아웃 요구사항+노출 데이터 항목 항목화 (2) 구현 파일과 하나씩 대조 (3) `항목|스펙 요구|실제 구현|상태(있음/없음/다른 형태)` 표로 기록, **색상/크기/여백 등 시각 디테일은 표에 안 올림**. 목업(옷장 메인/스타일일지 상세/코디 제작 3곳만 존재)은 레이아웃 구조 참고용으로만 곁들이고 시각 값 추출은 안 함. Explore 서브에이전트 병렬 파견으로 1차 수집 후 PM이 직접 재확인. 산출물은 페이지별로 순서대로(옷장 메인→옷 상세→코디 메인→코디 상세→스타일일지 메인→스타일일지 열람→설정→휴지통) 하나씩 보고, 한 번에 몰아서 안 줌. 이번 라운드는 점검만(코드 변경 없음) — 발견 후 수정은 사용자 확인 받고 별도 진행.

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

**병렬 작업 — 하네스 토큰 비용 진단 + 정책 문서 정리, `dev`로 PR #22 대기 중**: 사용자가 "자동 작업이 토큰을 너무 빨리 쓴다"고 진단 요청 → 원인은 프로젝트 규모가 아니라 Review/Tester 재검증 루프의 콜드 스폰 + 정책 문서 간 중복 서술로 확인. PR #19(재검증 스코프를 diff 단위로 좁힘, `Workflow_Project.md` §5)는 2026-08-02 병합 완료. 이어서 `audit` 서브에이전트로 CLAUDE.md+정책 문서 4종의 중복 서술을 감사 → CLAUDE.md 체크포인트 3~7, `Workflow_Development.md`/`Workflow_Design.md`의 Roles/Core Operating Principles 중복을 포인터로 정리한 후속 커밋이 이미 병합된 PR #19에 잘못 추가돼 브랜치 정리 때 유실될 뻔함 — dangling commit에서 복구해 새 브랜치(`docs/policy-dedup-2`)로 PR #22 재오픈. 이 Current 항목(Style Log 필터 등)과는 무관한 별도 스레드, 상세는 `docs/history/Decision.md` 최상단 항목 참고.

---

**병렬 작업 완료(2026-08-02~04) — 전체 앱 Firestore 데이터 스키마 설계 확정(2라운드)**: `../Digital-Wardrobe-db-schema-design` worktree(`feature/db-schema-design`, `dev`에서 분기)에서 Data/API/Architecture × Decision 문서 신설 및 확장. 1라운드(Worker→Review→Audit)에 이어, 사용자 테이블별 직접 리뷰(User→ClothingItem→Composition→StyleLog) 중 오프라인/로컬퍼스트 아키텍처 요구사항이 나와 §11 전면 재작성 → Development Review 2라운드(P1 2건 수정)→Audit 2라운드(P1 3건 수정) 전부 통과. 산출물: `docs/reference/data/00_DataSchema.md`. 상세는 `docs/history/Decision.md` 최상단 2개 항목 참고 — 이 Current 항목(Style Log 필터 등)과는 무관한 별도 스레드.
- (P2) 텍스트 검색(`00_MVP.md` §4.1, MVP 포함 기능)이 스키마 문서에 전혀 다뤄지지 않음 — Firestore 네이티브 풀텍스트 검색이 없어 클라이언트 사이드 필터링 전략 명시가 필요(Audit 2026-08-02 발견). 다음에 `00_DataSchema.md` 손댈 때 섹션/Open Question 추가.
- (P3) `00_DataSchema.md` Open Question #5의 미구현 필드 예시 목록에 `ClothingItem.size`/`Composition.mood_tags` 누락(기능상 문제 없음, 예시만 불완전, Audit 2026-08-02 발견) — 다음에 이 문서 손댈 때 보완.
- (P2) `lib/providers/trash_providers.dart`(또는 관련 mapping 지점)에서 `TrashEntry.createdAt`이 현재 `StyleLog.wornDate`를 매핑하고 있음 — 스키마 리뷰(2026-08-04)로 `StyleLog.createdAt`(신규 필드)로 옮기기로 확정(`00_DataSchema.md` §5/Open Question #18 참고). 실제 Firestore 마이그레이션 시점에 함께 반영.
- **(P2) 실제 Firestore 마이그레이션 착수 시 함께 반영해야 할 스키마 확장분 일괄 목록** (`00_DataSchema.md` 2라운드 리뷰, 2026-08-04) — 지금은 전부 Decision-stage 문서에만 존재, 코드 미반영:
  - `User` Dart 모델 자체가 아직 없음 — `lib/models/user.dart` 신설 필요(`email`/`authProvider`/`createdAt`/`lastActiveAt`/`lastSyncedAt`).
  - `ClothingItem.color`: `String?` → `ClothingColor?`(신규 enum, `enums.dart`, Open Question #11의 16개 후보값) 타입 변경 + 기존 mock 데이터 재태깅.
  - `ClothingItem.hasGraphic`/`hasPattern`(신규 bool? 필드, Open Question #12) — `00_MVP.md` §4.1 스펙 변경(3택1→독립 2개)에 대응.
  - `ClothingItem.acquiredAt`(신규 Timestamp? 필드).
  - `ClothingItem.analysisMetadata`/`analysisModelVersion`/`analyzedAt`(신규, §12 — 내부 구조는 추천 알고리즘 설계 후 결정, Open Question #16).
  - `Composition.tags`(신규 `List<String>` 필드).
  - `StyleLog.createdAt`(신규) / `wornDate`(nullable로 타입 변경) — Trash 매핑 변경(위 항목)과 함께.
  - §11 전체(Anonymous Auth 제거, `unlinked_local` 로컬 스코프+`disableNetwork()`, 링크 시 실 uid 마이그레이션+이미지 재처리, Open Question #13/#19) — 이건 스키마가 아니라 앱 초기화/인증 아키텍처 자체를 새로 구현하는 별도 큰 작업, 다른 항목들과 규모가 다름.

---

**병렬 작업 완료(2026-07-23) — 하네스 파이프라인 보완 + 문서 구조 개편**: `../Digital-Wardrobe-pipeline-docs` worktree(`feature/pipeline-docs-restructure`, `feature/flutter-hifi-screens`에서 분기)에서 아래 3건을 독립적으로 완료, `dev`에 이미 병합됨.
1. Task 완료 시 "세션 내 후속 작업 없음" 판단되면 BACKLOG.md만으로 새 세션이 이어받을 수 있는지 시뮬레이션 후 문제없으면 `/clear` 권유 — `Workflow_Project.md` §3 신설, CLAUDE.md 체크포인트 7번.
2. 설계/계획(Decision 단계) 산출물은 크기 무관 확정 전 Audit 필수 — `Workflow_Project.md` §5 "Decision-Stage (Design & Plan) Pipeline" 신설 + §12.1 표 갱신, `.claude/agents/audit.md` 트리거 추가. 이 플랜 자체가 이 원칙의 첫 적용 사례(Review 1회+Audit 1회 통과 후 확정).
3. `.claude/policies/`·`docs/reference/`의 라우터+앵커 구조(부모+서브파일 24개, 5개 그룹) 단일 파일로 재통합 + TOC 추가, 저장소 전체 상호참조 갱신(30여 지점) + 병합 결과 독립 Review 1회(P0/P1/P3 전부 없음) 통과. **이후 토큰 비용 재검토로 부분 롤백**(같은 세션, 사용자 피드백) — §12.1 Required Materials에 직접 걸려 Worker/Review에 좁게 자주 dispatch되는 핫패스 2개(`00_DesignPrinciples.md`/`03_화면별UX명세서.md`)는 서브파일 구조로 되돌리고, PM이 스스로 전체를 훑는 빈도가 높아 병합 손해가 작은 정책 문서 3종(`Workflow_Project/Design/Development.md`)만 병합 유지. **최종 상태: 5개 그룹 중 3개만 병합.**
상세는 `docs/history/Decision.md` 최상단 4개 항목 참고.

---

**(종료됨, PR #20으로 dev 병합)** Flutter 프론트엔드 Hi-Fi 화면 스프린트 — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치(PR #5/#10 이후 계속 같은 브랜치에서 진행, Step⑦ 그룹 B/C까지 완료)에서 Subagent-Driven으로 진행하다, PR #20 "디자인 임시 종료하고 레이아웃&데이터작업으로 전환"으로 dev 병합 — 이후 현재 마일스톤("레이아웃 & 데이터 작업", 위 참고)으로 전환.
- 스펙: `docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md`(그룹형 드릴다운/설정 진입점), `2026-07-21-multi-select-and-trash-design.md`(다중선택+휴지통, Group B 근거), `2026-07-13-scroll-container-and-header-hud-architecture.md`(Header/HUD·스크롤 컨테이너). 원 스프린트 계획(2026-07-08)과 그 Task 8~15는 화면 관통 공용 셸 아키텍처로 대체돼 폐기(`Decision.md` 참고).

---

# Next

- **[최우선] `Workflow_Project.md` §5/§12.1 정책 문서 자기모순 수정** — §12.1 표의 `Data/API/Architecture | Decision` 행에 "mandatory Audit before confirmation (크기 무관)" 문구가 누락돼 있음(`UI/Screen`·`Logic/Feature` 두 Decision 행엔 있음). §5 "Decision-Stage (Design & Plan) Pipeline" 본문 scope 문장도 Data/Architecture를 언급 안 함. DB 스키마 설계 확정 전 Audit(2026-08-02)이 발견(P1) — 이 Audit 자체가 그 누락된 규칙으로 트리거됐다는 자기모순이라 신뢰도 문제. `.claude/policies/**` 수정이라 실제 Edit 전 사용자 확인 필요(CLAUDE.md 체크포인트 2) — 사용자가 지금 당장은 보류, 백로그 최우선으로 등록만 해달라고 확정(2026-08-02).
- ~~`ui-ux-pro-max` 플러그인에서 Flutter 관련 내용만 추출해 프로젝트 로컬 스킬로 이식~~ **완료(2026-07-18)** — `feature/flutter-ui-reference-skill` 브랜치(저장소 바깥 sibling worktree)에 방치돼 있던 450줄 초안을 이어받아 검증 후 커밋. 검증 내용: (1) Flutter 52개 가이드라인·팔레트/폰트 표 샘플을 원본 플러그인 로컬 캐시(`~/.claude/plugins/marketplaces/ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max/data/*.csv`)와 대조해 추출 정확성 확인, (2) 라이선스 고지문이 원본 `LICENSE` 파일과 정확히 일치함을 재확인(MIT, Copyright Next Level Builder). 산출물: `.claude/skills/flutter-ui-reference/SKILL.md`. 후속 조치로 `.claude/settings.json`에 `"ui-ux-pro-max@ui-ux-pro-max-skill": false` 추가해 이 프로젝트에서만 원본 플러그인(7개 스킬: banner-design/brand/design/design-system/slides/ui-styling/ui-ux-pro-max) 비활성화 — 전역 설정은 그대로 둬서 다른 프로젝트는 영향 없음.

---

# MVP Progress

`docs/reference/plan/00_MVP.md` §2 스코프 기준, **실제 Firebase/AI 백엔드 연동** 여부 체크리스트(UI 구현 상태는 각 줄에 병기).

- [ ] Clothing archiving (AI 배경제거 + 자동태깅) — UI: 옷장 메인/상세/등록(`closet_main_screen.dart`/`closet_item_detail_screen.dart`/`closet_add_screen.dart`) 구현됨, AI 연동 없음
- [ ] View/filter by tags — UI: 그룹형 드릴다운/필터 구현됨(그룹 A), 실데이터 없음
- [ ] Composition (가상 코디, 편집 가능) — UI: 메인/상세/에디터(`composition_main_screen.dart`/`composition_detail_screen.dart`/`composition_editor_screen.dart`) 존재, 아트보드 실제 렌더링은 그룹 D 이월(위 "Current" 참고)
- [ ] Style Log — UI: 메인/뷰어/등록(`style_log_main_screen.dart`/`style_log_viewer_screen.dart`/`style_log_add_screen.dart`) 구현됨, 필터/정렬 UI는 진행 중(위 "Current" 참고)
- [ ] Clothing-based history — 상세 화면들의 상호참조(캐러셀/갤러리)는 구현됨, mock 데이터 기준
- [ ] Automatic wear count — UI 표시는 있으나 자동 집계 로직 자체가 미구현(mock이 값 하드코딩); Firestore 마이그레이션 시 집계 메커니즘은 `docs/reference/data/00_DataSchema.md` §7에 이미 설계됨

---

# Current Folder

`lib/`:
- `screens/`: 13개 파일(옷장/코디/스타일일지/휴지통 메인·상세·등록·에디터, 설정, 공용 스캐폴드 등)
- `widgets/`: 36개 파일(공용 컴포넌트)
- `providers/`: 6개(도메인별 + 분류/테마)
- `models/`: 5개(`ClothingItem`/`Composition`/`StyleLog`/`TrashEntry`/`enums`)
- `theme/`, `mock/`, `router/`도 별도 존재
- `integration_test/`, `test/`에 광범위한 테스트 스위트 존재(다수 통과 확인됨, 상세는 git log/Decision.md)

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
