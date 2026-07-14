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

**스크롤 힌트 상단(Top) 그래디언트 표시 조건 수정 완료 (2026-07-15).** 사용자가 "상단 그래디언트가 항상 깔려 보인다"고 지적 → PM이 실측(스크린샷 2장)·기존 통합테스트로 재현 시도했으나 재현 안 됨, 대신 진짜 문제(고정 `scrollTop > 2px`가 헤더/HUD 높이를 무시해 헤더 뒤에 가려져 있던 여백만으로도 조건이 충족됨)를 코드 리딩으로 특정. `AppScrollContainer`에 `topHintThreshold`(기본 2, 화면별 `AppMainScaffold.contentSpacerHeight(...)` 전달) 파라미터를 추가하는 저결합 방향(raw threshold)을 권고 — 헤더 슬롯 정보를 직접 받는 대안은 결합도만 높이고 반복 작업은 줄이지 못함을 비교 설명. 사용자가 직접 구현+커밋(`380d5b4`, Worker/Review/Tester 하네스 밖에서 PM과 페어로 진행). `header_hud_stack_architecture_test.dart`의 스크롤 그라디언트 테스트 2건을 새 threshold 기준으로 갱신(컴파일 에러 1건·미사용 import 1건은 PM이 발견해 알려주고 사용자가 수정), `detail_screens_header_hud_test.dart`(고정 100px 드래그, Detail 화면 threshold 64px이라 우연히 그대로 통과, 16/16 Pass)까지 재검증 완료. 스펙 문서(`2026-07-13-scroll-container-and-header-hud-architecture.md`) Top Gradient 표시 조건도 새 규칙으로 갱신(Bottom은 의도적으로 2px 유지). **로컬 커밋만 있고 origin에 미푸시(26 커밋 ahead) — 다음 세션에서 확인 필요.**

---

# Current

Flutter 프론트엔드 Hi-Fi 화면 10개 스프린트 (마감 2026-07-24) — mock 데이터 기반 UI만, 실제 Firebase/AI 연동 없음. `feature/flutter-hifi-screens` 브랜치(PR #5로 dev 1차 병합 완료, 같은 브랜치에서 계속 진행)에서 Subagent-Driven으로 진행 중.
- 스펙: `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`(원 스프린트), `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`(화면 관통 공용 셸 스펙), `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`(Header/HUD·스크롤 컨테이너 정식 스펙 — 지금은 이 3개를 함께 따를 것)
- 원 플랜의 Task 1~7만 유효, Task 8~15는 폐기(대체 근거: `docs/history/Decision.md`의 "화면 관통 공용 UI 셸 아키텍처로 전환" 항목)

**다음 세션 작업**:
1. **Step⑥(나머지 화면 적용 — 설정/휴지통/선택 모달 등) 진행 중**. §1 표의 플래그 매핑을 그대로 사용.
- Step⑥-A(설정/휴지통) 완료(커밋 `c1d1961`) — Worker→Review(P1 선택버튼 누락·P2 mock 구조 지적 후 재작업→Pass)→Tester(설정 Switch 완전 비활성 지적→재작업→Pass, 통합테스트 40/40) 사이클 완주.
- **다음: Step⑥-B(선택 모달 — 옷장/코디/스타일일지 재호출) 착수**. 별도 화면 신설이 아니라 기존 Main 화면을 모달로 재호출하는 재사용 메커니즘(선택모드 플래그: 뒤로가기→닫기 X버튼, 카테고리 토글 항상 X, 그룹형 드릴다운은 옷장/코디만 유지)이 필요 — 실제 바인딩 호출부(Composition Editor 등에서 여는 지점)는 Step⑦ 몫.
- Detail 3화면 보일러플레이트 중복(P2, Step④ Audit 발견, `docs/history/TechnicalDebt.md` "화면 간 반복 복제된 UI 블록" 항목) — Step⑤까지 마치고 나면 공용 컴포넌트 추출 임계점을 넘었는지 재검토.
- `CrossReferenceLinkBar` Step④ placeholder가 완성된 컨트롤처럼 보여 Visual Review 시 혼동 위험(P3, 위 TechDebt 항목 하단 참고) — 우선순위 낮음, 픽업 시 비활성 스타일 검토.
- 코디 타일 표시 방식(Audit P1, Step③ 때 발견)은 `coverImagePath` 필드 신설로 방향만 확정, 착수는 보류 중(`docs/history/TechnicalDebt.md`).
- Scrollbar / Scroll Hint(`<`/`>`)는 프로젝트 공용 디자인 후보로 유지 — 이번 라운드엔 제작 안 함. 실제로 만들 때 지킬 계약(Overlay, 레이아웃 비침습)은 위 스펙 §3/§6에 이미 정의됨.

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
