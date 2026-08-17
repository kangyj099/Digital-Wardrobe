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

**소유권 맵 + 설계 단계 구조 산출물 정책 확정(2026-08-15)** — 크로스커팅 동작·컴포넌트의 소유 파일을 정하는 `docs/reference/architecture/00_OwnershipMap.md` 신설(18행, grep 검증, 규칙 블록을 문서 자신이 실음) + 전달 경로(`Workflow_Project.md` §12.1/§12.4)·판정 기준(`engineering-principles`, Flutter 체크리스트)·검증자(Audit 대조) 배선. Draft→Review 2회→Audit 3회(전부 FAIL 후 PASS). 근거·경위는 `Decision.md` 최상단, 초안 전문은 `docs/superpowers/specs/2026-08-15-structural-design-stage-artifacts-design.md`. 커밋 `ceace0e`.

**Track A(삭제&휴지통 UI 픽스 5건) — PR #27로 `dev` 병합 완료(2026-08-14).**

---

# Current

**Track B(코디 스냅샷 아키텍처) — 구현 완료·Review 통과, 다음 할 일은 Tester 재투입**: 브랜치 `feature/composition-snapshot-implementation`(Track A 병합본 위에 분기, 미푸시 커밋 다수). 아키텍처는 Draft→Review(P0: 오프스크린 캡처 기법이 항상 실패하는 구조 — Flutter SDK 소스로 검증)→Audit(1차 FAIL P1 4건)으로 확정(`00_DataSchema.md` §13, `Decision.md`) → L 구현(캡처/저장, 편집 커밋 연동, 삭제된 옷 자동정리+Draft invalidate, Track A의 불완전했던 배지 판정을 `compositionHasDeletedItemsProvider`로 교체) → **Tester 1차 FAIL(F1~F5)** → Worker 수정(`f84ce62`) → Review가 4번째 `coverImagePath` 미전환 지점 발견 → 수정 완료(`80f7e1a`, `flutter test` 130/130 + 스냅샷 런타임 스위트 14/14 통과).

**→ 다음: Tester 재투입**(§5상 Tester 실패 후 사이클이라 Review는 이미 재통과함). 통과 시 L 태스크라 **Audit 게이트** 1회 후 `dev` PR. Tester가 확인할 것은 F1~F5 수정분의 런타임 재검증 + 회귀(특히 F1이 깨뜨렸던 4개 스위트).

- 참고: `path_provider` 추가로 이 프로젝트 최초의 네이티브 플러그인이 생겼고, Windows 빌드에 **Developer Mode 활성화가 필수**가 됐다(2026-08-14 사용자가 활성화 완료, `flutter build windows` 성공 확인). 새 개발 환경에서는 이 설정이 선행돼야 `flutter test -d windows`가 돈다.
- 참고: `/assets/fonts`가 `.gitignore`에 있어 **새 클론·새 worktree에서는 폰트 누락으로 빌드가 깨진다**(2026-08-14 확인). 현재 폰트는 사용자 로컬에만 존재 — 커밋할지 README 설치 안내로 갈지 미정(라이선스 확인 필요).

**8페이지 레이아웃&데이터 완전성 감사 전체 완료(2026-08-12) — 발견분 중 미구현으로 남은 것 일람**: 옷장 메인→옷 상세→코디 메인→코디 상세→스타일일지 메인→스타일일지 열람→설정→삭제&휴지통 순으로 스펙(`03_화면별UX명세서/*.md`)↔구현 대조 완료. 설정은 발견 0건, 삭제&휴지통은 Track A/B로 처리됨(위 참고). **나머지 페이지의 미구현 잔여분은 아래 3개 항목(옷장 메인 / 스타일일지 열람 / 미픽업 P2·P3 목록)에 전부 분산 기록돼 있으며, 이 감사에서 나온 것 중 그 어디에도 없는 항목은 없다.** 감사 방법론과 역할 분담(레이아웃·기능·데이터는 PM, 시각 디자인 디테일은 사용자)은 `Decision.md` 참고.

**옷장 메인 감사 — 스펙 확정 완료(2026-08-05경), 구현은 전부 미착수**: 사용자와 상세 논의를 거쳐 `01_옷장.md`+`_공통 규칙.md`(제스처 표)에 스펙을 확정했으나 코드에는 아무것도 반영되지 않음(`closet_main_screen.dart`/`app_gallery_grid.dart`에 관련 구현 없음을 2026-08-15 재확인). 잔여 항목:
- **핀치 제스처로 타일 밀도 조절**(`01_옷장.md` 5~7행, `_공통 규칙.md` 제스처 표): 벌리면 밀도↓/오므리면 밀도↑, 3단계 스냅. 제스처 중 그리드 전체를 핀치 비율대로 확대/축소 피드백, Release 시 임계값 넘으면 다음 단계로 스냅 애니메이션·안 넘으면 원위치. **밀도가 바뀌는 모든 경로(핀치·기존 밀도 버튼)에서 보던 아이템이 화면에 남도록 스크롤 앵커링 보정**, 밀도 버튼 아이콘 상태 동기화.
- **텍스트 검색**(`01_옷장.md` 13행): 검색 버튼→입력 필드 전환(모프) 인터랙션 포함. 툴바 배치는 좌측부터 (드롭다운 세그먼트)(정렬순서)(밀도버튼), 우측 끝에 (검색버튼).
- **옷 터치 시 반응 애니메이션 후 상세 전환**(`01_옷장.md` 12행).
- 참고: '차순(오름/내림) 버튼'은 논의 끝에 **스펙아웃 확정**되어 문서에서 삭제됨 — 되살리지 말 것. 분류 기준 드롭다운이 정렬 기준을 겸하므로 별도 정렬 UI는 만들지 않는다(`01_옷장.md` 9행).

**스타일일지 열람 감사 논의 완료(2026-08-07), 실제 구현은 아직 착수 전(위 Track A/B와는 별개 대기열)**: 확정된 발견 4건 — (1) 착용 옷 목록에 [+] 추가 버튼 없음 (2) 날짜/장소 편집 UI 없음 (3)(4) "자동 매칭"(코디↔스타일일지 착용 옷 자동 동기화, 양방향 둘 다) 미구현. `StyleLog.additionalImagePaths` 필드 정정(카드 3~10번 슬롯 사진, `wornItemIds`와는 별개 — `00_DataSchema.md` 오류 수정, `Decision.md` 참고) + 슬롯 10개 상한/롱프레스 드래그 재배치/빈 슬롯 [+] 스펙 확정(`03_스타일 일지.md`). **"연결 바텀시트" 패턴을 `_공통 규칙.md`로 일반화**(좌상단 고정 [+] 타일로 신규 생성, 생성 후 원래 화면으로 프리즈 복귀, 시트 자동 스크롤 — 옷/코디/스타일일지 전체 연결 지점에 재사용, `01_옷장.md`/`02_코디.md`/`03_스타일 일지.md` 전부 이 참조로 정리 완료). 현재 구현(`_bindComposition`/`_bindStyleLog`)은 전체화면 push 방식이라 "바텀시트"가 아님 — 이것도 실제 구현 시 함께 고쳐야 함. **자동 매칭 세부 동작도 확정 완료**(1회성 복사·참조 아님, 재연결 시 누적, 반대방향은 스타일일지發 신규생성에만 적용, 기본 배치 로직은 나중에 교체 쉽게 만들 것 — `Decision.md` 참고). 이 항목 전체(4건 + 연결 바텀시트 실제 구현 + `additionalImagePaths` 필드/화면 + 자동 매칭)를 하나의 Task로 묶어 등록할 것.

**Step⑦ 나머지 스코프 진행 상황 — 그룹 A/B/C 완료, 그룹 D 미착수**: 그룹 A(그룹형 드릴다운, 2026-07-19)/그룹 B(다중선택+휴지통, 13 Task 전부 완료)/그룹 C(설정 나머지 — 다크모드 실동작 포함, 2026-07-28) 전부 완료. 상세 경위는 `Decision.md`/git log(태그: Task 이름으로 검색)가 1차 소스, 이 파일은 더 이상 Task별 세부 내역을 보존하지 않음.
- **그룹 D(에디터급 이월 항목)**: "아트보드 실제 렌더링"은 Task A로 코디 편집기 쪽 완료. 남은 것 — 코디 상세(`composition_detail_screen.dart`)에 정적 렌더 아트보드 추가(Task B, 진행 예정), 추가사진 드래그 순서변경, 옷 추가 바텀시트를 통한 신규 생성 바인딩.
- **"Editor Draft 구현"**: `CompositionDraft`/`compositionDraftProvider`는 Task A로 실제 구현·적용 완료(Commit/Cancel/Rollback 전부 동작). `ClothingItemDraft`/`StyleLogDraft`(옷 추가/스타일일지 추가 화면)는 여전히 미착수 — 각 화면이 실제 Editor 상호작용(옷 추가의 배경제거/크롭/마스킹 등)을 갖추는 시점에 개별 적용. `AutoSaveIndicator` 위젯은 이번에도 안 건드림(여전히 구정책 "상시 저장" 독스트링인 채로 미사용 상태) — 다음에 옷 추가/스타일일지 추가 화면 중 하나를 실제 착수할 때 정리. `composition_main_screen.dart`의 [+] 버튼 분류별 자동 태그 적용(`Decision.md` 참고)도 여전히 미배선 — 옷 추가 바텀시트 착수 시 함께.

**판단 보류 — "자동 매칭"(코디↔스타일일지 착용 옷 자동 동기화) 논의**: 코디 상세 감사에서 새로 발견(스펙엔 있으나 `linkToComposition()`이 아이템 동기화를 전혀 안 함, 기존 추적 중이던 사안 아님). 사용자가 "스타일일지 쪽 개념이니 스타일일지 감사 때 논의"로 미룸 — 스타일일지 열람 감사 진행 시 최우선으로 다시 꺼낼 것.

**미픽업 P2/P3 백로그 (다음에 해당 파일 손댈 때)**:
- (P2) `02_코디 (가상 조합).md` 8행 "정렬/필터에 날씨·계절 기준 지원(스타일 일지와 공통)" 문구가 실제 구현과 어긋남 — 2026-07-19 스펙 근거로 갱신.
- (P2) 옷 상세의 코디 캐러셀/스타일일지 갤러리 섹션에 제목(라벨) 누락 — 코디 상세는 타이틀 붙는데 옷 상세는 안 붙음(비대칭). `closet_item_detail_screen.dart`에 `Text(titleSmall)` 헤더 추가로 해소 가능.
- (P2) `AppDetailScaffold`가 같은 역할의 `AppMainScaffold`와 달리 `lib/screens/`에 배치됨(`lib/widgets/`가 자연스러움) — 호출부 3곳뿐인 지금이 이동 비용 최저.
- (P1) 코디 상세(`composition_detail_screen.dart`)가 스냅샷 대신 `composition.items`에서 `StaticArtboard`를 라이브 렌더링 중 — `00_DataSchema.md` §13.7 지적대로 스냅샷(`CompositionCoverImage`) 표시 + "다음 편집 시 자동 정리" 배너로 전환 필요. `StaticArtboard`의 탭-하이라이트/롱프레스-편집 인터랙션을 정지 이미지 위에서 유지할 별도 설계(탭 오버레이 그리드 등) 필요 — §13 확정 후 후속 Task로 착수.
- (P2) **삭제 UX 흐름이 6개 진입점에 각각 복제됨 — 공용 핸들러로 통합 필요**: 상태 변경 계층(`softDeleteMany`/`restoreMany`/`purgeMany`)은 도메인별 1벌씩만 있고 모든 진입점이 그걸 호출해 문제없으나, 그 위의 "확인 다이얼로그 → 소프트삭제 → pop → 토스트 → 실행취소 배선" 흐름은 메인 갤러리 3곳 + 상세화면 3곳에 손으로 복제돼 있음. 실제 피해 사례: (1) 실행취소 크래시 P0가 상세화면 3곳에서 동일하게 발생해 3개 파일을 각각 고쳐야 했음(2026-08-13), (2) `_confirmAndDelete`가 `closet_main_screen.dart`/`closet_item_detail_screen.dart`에 같은 이름으로 두 벌 존재하며 문구만 다름, (3) 아래 "코디 삭제에 '사용 중' 경고 없음" TechDebt도 강제하는 공용 경로가 없어 생긴 비대칭. 통합 시 도메인별 경고 정책까지 한 곳에서 강제하면 그 TechDebt도 함께 해소됨. 부수적으로 3개 도메인 Notifier의 소프트삭제/복원/영구삭제 구현이 변수명만 다른 복붙이라 제네릭 믹스인(`SoftDeletableNotifier<T>`) 후보.
- (P3) Scrollbar / Scroll Hint(`<`/`>`)는 프로젝트 공용 디자인 후보로 유지, 아직 미제작. 계약(Overlay, 레이아웃 비침습)은 `2026-07-13-scroll-container-and-header-hud-architecture.md` §3/§6 참고.
- (P3) `flutter analyze` 미등재 lint 경고 다수(`typography_pass3_test.dart` 항목에 누적 기록 중, `TechnicalDebt.md` 참고) — 급하지 않음, 해당 파일 손댈 때 정리.

**TechDebt — `AppMainScaffold` 헤더 오버레이 때문에 widget test hit-test가 어긋남(P3)** / **코디 삭제(`composition_main_screen.dart`+`composition_detail_screen.dart` 두 진입점 다)에 "사용 중" 경고 없음(P2)** — 둘 다 `TechnicalDebt.md` 참고, 급하지 않음.

**미확인 — `GlassToast` 히트박스 수정이 사용자가 원래 보고한 증상과 완전히 같은 것인지 사용자 직접 재검증 예정.**

**밀린 Visual Review — 사용자 직접 수행 대기**: 그룹 B 완료로 트리거 조건은 이미 충족됐다(`Workflow_Design.md` §2.1). 수행 주체는 사용자다(`Workflow_Design.md` §2.1 "Who judges"). Claude는 이 게이트를 스크린샷 셀프 판정으로 통과 처리하지 않는다. 대상은 Typography Pass 3 이후 누적된 신규 화면·컴포넌트 전부(Detail 3화면, 분류 드릴다운 캡슐, `GlassToast`/`MultiSelectCheckmark`/휴지통 필터칩 등). 사용자 판정 전까지 Design Tokens는 provisional 유지.

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
