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

**Step⑦ 착수 전 선행 작업 2건 완료 (2026-07-15).** (a) `Composition`/`StyleLog` `isIncomplete` 필드 Decision 확정(저장 필드 방식) — 그 논의 중 사용자 제안으로 "상시 저장" 정책이 Record Real-time Save + Editor Draft/Commit/Cancel로 분리되는 더 큰 정책 전환(`docs/history/Decision.md` "Editor 저장 모델 전환")까지 함께 확정, Editor 3화면 실배선은 "Editor Draft 구현" 후속 작업으로 이관. (b) "화면 간 반복 복제된 UI 블록" 5개 사례를 공용 위젯(`ExpandableAddFab`/`GalleryMetaLabel`/`buildSelectionAwareHeaderActions`/`AppDetailScaffold`/`AppDensity.iconFor`)으로 추출, Worker→Review→Tester→Audit(L 사이즈) 전부 통과. Audit이 후속 항목 몇 건 추가 발견 — 상세는 `docs/history/TechnicalDebt.md`.

---

# Current

Flutter 프론트엔드 Hi-Fi 화면 10개 스프린트 (마감 2026-07-24) — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치(PR #5로 dev 1차 병합 완료, 같은 브랜치에서 계속 진행)에서 Subagent-Driven으로 진행 중.
- 스펙: `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`(원 스프린트), `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`(화면 관통 공용 셸 스펙), `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`(Header/HUD·스크롤 컨테이너 정식 스펙 — 지금은 이 3개를 함께 따를 것)
- 원 플랜의 Task 1~7만 유효, Task 8~15는 폐기(대체 근거: `docs/history/Decision.md`의 "화면 관통 공용 UI 셸 아키텍처로 전환" 항목)

**다음 세션 작업**:
1. **Step⑦(기능 구현) 1라운드 진행 중 — Task 1~7 완료(Worker→Review→Tester 전부 통과), Task 8~9 남음(2026-07-16, Task 7 완료 직후 1차 Audit이 P1 2건 발견 → 사용자가 즉시 착수 지시).** 플랜(코드 전부 포함, 그대로 실행 가능): `docs/superpowers/plans/2026-07-15-step7-detail-binding.md`.
   - **완료**: Task 1~4(이전 세션), Task 5(`Composition.coverImagePath`+파생 provider, `69ee1c0`+`62999ee`), Task 6(코디 프리뷰 캐러셀/카드+스타일일지 2열 갤러리 위젯, 옷 상세·코디 상세 재배선, `1b4b339`+`4dd8875`+`37bb25a`, Tester가 발견한 `CrossReferenceLinkBar` 빈 여백 버그까지 해결 후 재통과 — Review→Tester 사이클 재시작 1회), Task 7(스타일일지 열람 실데이터 바인딩+코디 선택 모달 바인딩, `7f6db21`; 도중 서브에이전트가 API 오류로 끊겨 PM이 직접 검증/커밋 마무리, `d6d62e3`), 문서 정정(`c85f52e`).
   - **1차 Audit(Task 7 직후) 발견 P1 2건 → 사용자가 스펙 근거로 정정 지시, 즉시 Task 8/9로 편입**: (a) 스타일일지 열람의 코디 바인딩 UI가 `03_스타일 일지.md`의 카드 순서(대표이미지→코디 슬롯→추가사진)를 어기고 코디 상세와도 다르게 생김 — **Task 7이 구현한 "하단 별도 카드/칩" 방식은 폐기**, 대표이미지+코디 슬롯을 정사각형 2페이지 스와이프 캐러셀로 재구현(스펙 원문 그대로). (b) `AppDetailScaffold.crossReferenceEntries` 계약이 애매해짐 — 폐기. 상세: `docs/history/Decision.md` "스타일일지 열람 카드 구조를 스펙 원문대로 정정..." 항목.
   - **사용자가 동시에 확인한 추가 사항**: "추가 사진"으로 잘못 라벨된 스타일일지 하단 가로스크롤이 실은 "착용 옷"(mock 데이터의 `additionalImagePaths`가 실제 `ClothingItem.imagePath`와 매칭됨) — 라벨 정정 + 탭 시 옷 상세 이동 배선. 옷장 상세의 코디 캐러셀/스타일일지 갤러리는 정사각형으로 통일(코디 상세의 "1개면 2칸 확대"는 승인된 스펙이라 그대로 유지).
   - **다음 착수: Task 8(스타일일지 열람 카드 캐러셀 재구현, UI/Screen)** — Worker→Review→Tester. 그다음 **Task 9(옷장 상세 정사각형 통일 + `crossReferenceEntries`/`CrossReferenceLinkBar` 폐기, UI/Screen)** — Worker→Review→Tester. **Task 9 Tester 통과 직후 2차(최종) Audit 필요**(CLAUDE.md §4 — 코드가 다시 바뀌었으므로 1차 Audit로 완료 처리 안 함).
   - **1라운드 스코프 밖**(Task 9 완료 후 별도 후속 항목으로 BACKLOG 등록 필요 — Plan 문서 "완료 후 PM 처리 사항" 참고): 겹친 아이템 팝업/아트보드 실제 렌더링, 추가사진(진짜 의미의, 착용 옷과 별개인 순수 추가사진 개념은 이번에 없어짐) 드래그 순서변경, 신규 생성 바인딩, Detail "⋯더보기" 메뉴 실제 연결. 추가로: `CompositionGalleryTile`(코디 메인 그리드) 이미지 업그레이드(착수 비용 낮아짐, TechDebt 참고), 코디 아이템 개수 상한 15개의 실제 코드 반영(Editor 구현 시점, `Decision.md` "Detail 화면 상호참조를..." 항목).
   - **Step⑦ 나머지 스코프**(1라운드 완료 후 별도 Plan으로 이어감): 그룹형 드릴다운 실배선(옷장/코디 메인 2곳), 선택 버튼 진입/다중선택 자체, 휴지통 복원·영구삭제·비우기 실행, 설정 알림/다크모드/프로필 진입 연결.
   - **"Editor Draft 구현"(신규 후속 작업, Step⑦ 전체 완료 후)**: 도메인별 `draftsProvider`(`ClothingItemDraft`/`CompositionDraft`/`StyleLogDraft`) 신설, `EditorHeader.onCancel`/`AutoSaveIndicator` Draft 기준 배선, Editor 3화면 실제 Commit/Cancel 로직, `isIncomplete` 토글 로직. Recovery는 세션 내 복원만 범위(앱 강제종료 후 복원은 제외). 착수 전 `AutoSaveIndicator` 독스트링/Editor 3화면 skeleton 라벨의 구 정책("상시 저장" 서술) 정리도 함께(P2, Audit 2026-07-15 발견).
- ~~Detail 3화면 보일러플레이트 중복~~ **완료(2026-07-15)** — 위 (b)에서 `AppDetailScaffold`로 해소(단, 파라미터 협소 문제는 위 Step⑦ 착수 노트 참고).
- (P2) `AppDetailScaffold`(`lib/screens/app_detail_scaffold.dart`)가 같은 역할의 `AppMainScaffold`(`lib/widgets/`)와 달리 `lib/widgets/`가 아닌 `lib/screens/`에 배치됨 — Audit(2026-07-15) 발견, 근거가 약한 배치(상세는 `docs/history/TechnicalDebt.md` "화면 간 반복 복제된 UI 블록" 항목 하단). 호출부가 3곳뿐인 지금이 이동 비용이 가장 쌈, 급하지 않음.
- 6번째 UI 블록 중복 사례(Editor 3화면 `EditorHeader`+`skeletonRegion` 보일러플레이트, P3, Audit 2026-07-15 발견) — "Editor Draft 구현" 착수로 어차피 재작성될 예정이라 의도적으로 추출 보류(`docs/history/TechnicalDebt.md` 참고).
- `CrossReferenceLinkBar` Step④ placeholder가 완성된 컨트롤처럼 보여 Visual Review 시 혼동 위험(P3, 위 TechDebt 항목 하단 참고) — 우선순위 낮음, 픽업 시 비활성 스타일 검토.
- 코디 타일 표시 방식(Audit P1, Step③ 때 발견)은 `coverImagePath` 필드 신설로 방향만 확정, 착수는 보류 중(`docs/history/TechnicalDebt.md`).
- Scrollbar / Scroll Hint(`<`/`>`)는 프로젝트 공용 디자인 후보로 유지 — 이번 라운드엔 제작 안 함. 실제로 만들 때 지킬 계약(Overlay, 레이아웃 비침습)은 위 스펙 §3/§6에 이미 정의됨.
- (P2, 급하지 않음) 휴지통 mock provider에 삭제 시각(`deletedAt`) 필드가 없어 실제 3-domain 집계 전환 시 "N일 남음" 계산 불가 — 모델에 필드 추가 필요. `mockTrashEntries`의 `t3` 항목이 `remainingDays: 27`로 15일 상한을 넘는 값이라 다음에 손댈 때 0~15 범위로 조정.

---

# Next

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
