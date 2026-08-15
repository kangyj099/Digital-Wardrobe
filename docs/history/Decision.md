<!--> 최신 Decision이 위로, 오래된 것이 아래로 가게 작성함<-->

[Decision] 중복 구현 방지를 Review 단계로 이관 + 재발 패턴 TechDebt의 규칙 승격 의무화 (Policy, Decision)

결정:
- `flutter-implementation-conventions`에 Review 체크 3종 신설 — 동작 시퀀스 Rule of Three / 같은 수정이 3곳 이상 필요하면 Worker가 중단하고 PM에 보고 / 공용 컴포넌트 도입 시 grep 기반 호출부 전수 확인. Review 체크리스트 표 Architecture 행에도 반영.
- 같은 스킬 Riverpod 섹션에 "지연 빌드 콜백 안에서 `ref.watch` 금지" 규칙 신설(파생 provider `.autoDispose` 부여, 판정 로직은 순수 함수 + provider 얇은 래퍼 구성 포함).
- `Workflow_Development.md` §1에 설계 산출물 요건 추가 — 동작 절차의 소유 계층과 "화면별로 달라도 되는 경계"를 명시할 것.
- `Workflow_Project.md` §10 Definition of Done에 체크 항목 추가 — 기록한 TechDebt가 재발 가능한 패턴이면 해당 도메인 conventions 스킬에 규칙으로 승격했을 것.

사유:
세 종류의 실패가 각각 다른 지점에서 드러났고, 셋 다 기존 체크리스트가 구조적으로 못 잡는 자리였다.
(a) 설계가 절차를 공용화 대상으로 보지 않음 — `2026-07-21-multi-select-and-trash-design.md`가 `GalleryMainScreen<T>`/`GlassToast`/`softDeleteMany`(명사)는 공용 설계했으나 "삭제 절차"의 소유자를 지정하지 않아 6개 진입점에 복제됨. 실행취소 크래시 P0가 상세화면 3곳에서 동일하게 발생해 3개 파일을 각각 수정했고, 구조 문제 자체는 사용자 질문으로만 드러남(2026-08-14). 코디 삭제에만 "사용 중" 경고가 빠진 기존 TechDebt도 같은 뿌리.
(b) 설계는 맞았으나 구현이 호출부를 다 바꾸지 않음 — `Composition.coverImagePath` 소비자 4곳 중 `00_DataSchema.md` §13.3은 2곳만 열거. 1차 구현 1곳, Tester F2 수정으로 3곳, 4번째(`composition_preview_card.dart`)는 Review가 3라운드째에 발견. Tester 스위트도 스펙의 열거를 따라가 이 지점을 덮지 못함(2026-08-15).
(c) 이미 문서화된 위험이 그대로 재발 — `TechnicalDebt.md`의 "Riverpod provider-to-provider `ref.watch`가 build 중 ancestor `setState()` 크래시를 유발할 수 있는 일반 패턴" 항목(상태: "구조적 가드 없음")이 있는 상태에서 동일 크래시가 코디 갤러리 그리드에서 재발(Tester F1). Worker의 Task Manifest에 `TechnicalDebt.md`가 포함돼 있었으나, 긴 이력 문서에서 "지금 쓰려는 코드가 위험 목록에 있는가"를 역으로 조회하는 일은 실제로 일어나지 않았다 — 지식이 history에는 있었고 rule 자리에는 없었다. 위 §10 체크 항목이 이 이관 단계를 강제한다.

Impact:
- `.claude/skills/flutter-implementation-conventions/SKILL.md`, `.claude/policies/Workflow_Development.md`, `.claude/policies/Workflow_Project.md` 수정.
- 코드 변경 없음. 기존 6중복 삭제 흐름의 실제 통합은 `BACKLOG.md`에 P2로 별도 등록됨.

---

[Decision] 코디 스냅샷 캡처/로컬 저장 아키텍처 확정 (Data/Architecture, Decision)

결정:
- **캡처 대상은 `StaticArtboard`, `InteractiveArtboard` 아님** — 후자는 배경색 버튼/선택 테두리/핸들 등 에디터 전용 크롬을 같은 영역에 그려 캡처에 섞여 들어감. `RepaintBoundary`+`GlobalKey`로 감싸 화면 밖(큰 음수 offset, `Opacity(0)` 래핑은 절대 금지 — `RenderOpacity`가 `alpha==0`이면 자식을 아예 페인트하지 않아 레이어가 안 붙고 `toImage()`가 무조건 실패함)에 `Overlay`로 마운트해 `toImage()`.
- **트리거 지점 2곳, 쓰기 경로는 동일**: (a) 에디터 완료(✔) 커밋, (b) 코디 편집 진입 시 "삭제된 옷 자동 정리" — 둘 다 `CompositionsNotifier.updateItems`로 귀결. (b)는 에디터 화면이 아니라 **네비게이션 호출부**(코디 상세의 편집 진입 지점)에서 실행돼야 함 — `compositionDraftProvider`가 `autoDispose`가 아니라서, 방치된(취소하지 않고 뒤로가기한) 기존 Draft가 있으면 그 Draft의 `create`가 재실행 안 되기 때문. 정리를 실행한 직후 반드시 `ref.invalidate(compositionDraftProvider(compositionId))`로 그 Draft를 무효화해야 다음 진입이 정리된 Record를 다시 읽음 — 이건 기존 "Editor 저장 모델 전환" 결정(방치 Draft 재사용)을 뒤집는 게 아니라, "실제로 정리를 실행한 경우"에만 적용되는 좁은 예외.
- **로컬 저장**: `path_provider` 신규 의존성 추가, `getApplicationSupportDirectory()`(캐시/임시 아님 — OS가 예고 없이 비울 수 있어 "스냅샷은 안 깨짐" 보장이 깨짐) 아래 PNG 저장. 파일명은 매 재생성마다 새로 발급(`{compositionId}_{microsecondsSinceEpoch}.png`) — `Image.file`의 캐시가 mtime이 아니라 경로 기준이라, 고정 파일명 덮어쓰기는 재생성 후에도 이전 이미지가 계속 캐시로 보이는 문제가 생김. 이전 파일은 best-effort 삭제(실패해도 커밋 자체는 막지 않음).
- **`lib/services/` 폴더 신설**: 이번이 첫 사례. **규칙(향후 기능 전반에 적용되는 선례로 확정)**: Riverpod 상태를 다루지 않는 순수 비동기 I/O·플랫폼 연동 로직 → `services/`, Riverpod 상태를 다루는 로직은 계속 `providers/`. (export/import, 업로드 큐, AI 분석 등 다음 기능들도 이 규칙을 따름.)
- **`Composition.isIncomplete`**: 기존 "미완성 배지"의 2026-07-15 Draft-존재-여부 판정 규칙(`_공통 규칙.md`)과는 별개의, Record에 영속되는 조건. `updateItems`(위 두 트리거 지점 공통) 호출마다 `items.isEmpty`로 무조건 재계산 — "정리 후 0개 남으면 기존 미완성 처리 재사용" 요구를 새 상태 없이 만족.
- **스코프 컷(후속 과제로 이관, 이번 결정에 미포함)**: 코디 상세 화면이 스냅샷 대신 `composition.items`를 라이브 렌더링하는 것 자체는 이번에 안 고침 — 탭 하이라이트/롱프레스 편집진입 같은 상호작용이 평면 PNG만으로는 안 되기 때문(별도 탭 오버레이 그리드 설계 필요). "다음 편집 시 자동 정리" 안내 배너도 같은 후속 과제.

사유:
삭제&휴지통 페이지 감사에서 스펙("코디는 저장 시마다 평면 렌더링 스냅샷 저장, 목록/상세는 항상 스냅샷 사용")이 실제로는 전혀 구현 안 된 것을 발견 — `Composition.coverImagePath` 필드만 있고 아무도 채우지 않음. 사용자가 "전부 즉시 수정, 스냅샷 아키텍처 우선"으로 지시. Worker Draft → Review(1차 P0: `Opacity(0)` 래핑이 `RenderOpacity`/`RepaintBoundary` 동작상 캡처를 무조건 실패시킴, Flutter SDK 소스로 직접 검증됨 → 수정 후 재검증 통과) → Audit(1차 FAIL, P1 4건: 방치 Draft가 정리를 무효화할 수 있는 취약점 / `lib/services/` 폴더 선례 미확정 / 병행 진행 중이던 Track A의 "연결끊김" 배지 구현이 이 설계와 다른 판정 기준을 씀 / BACKLOG.md가 두 병행 브랜치에서 갈라짐 → 앞 3건 수정 후 재검증 PASS, 4번째는 PM의 머지 시점 처리 항목으로 분리) 전체 파이프라인 통과.

Impact:
- `docs/reference/data/00_DataSchema.md` §13 신설(§8 표/Open Question #8 갱신 포함).
- `docs/work/BACKLOG.md`에 코디 상세 스냅샷 표시/정리 배너 후속 과제 등록(위 스코프 컷 항목).
- 코드 변경 없음(Decision 단계) — 실제 구현(`lib/services/composition_snapshot_service.dart` 신설, `composition_editor_screen.dart`/`composition_providers.dart`/`composition_editor_providers.dart`/`composition_gallery_tile.dart` 수정, `pubspec.yaml`에 `path_provider` 추가 등)은 별도 L Task로 후속 진행. 그 Task는 병행 진행된 Track A(삭제&휴지통 UI 픽스)의 "연결끊김" 배지 판정 로직을 이 결정의 `compositionHasDeletedItemsProvider`로 교체하는 것을 스코프에 명시 포함해야 함.
- **머지 시 주의**: `feature/composition-snapshot-architecture`와 `feature/trash-cascade-ui-fixes`가 같은 커밋(24b7008)에서 분기된 뒤 각자 `BACKLOG.md`의 Current 섹션을 다르게 수정함 — 둘을 `dev`에 합칠 때 자동 병합에 맡기지 말고, 이 스냅샷 결정의 후속 과제 기록을 Track A 쪽의 (더 최신으로 재구성된) Current 섹션 위에 수동으로 다시 적용할 것.

---

[Decision] 코디↔스타일일지 "자동 매칭" 동작 세부 확정 (Logic/Feature, Decision)

결정:
- **1회성 복사, 참조 아님**: 코디를 스타일 일지에 연결하는 순간 그 코디의 옷들을 스타일 일지의 착용 옷 목록에 한 번 복사(중복 제외) — 이후 코디 쪽 아이템 구성이 바뀌어도 스타일 일지에 재반영 안 됨(라이브 동기화 아님).
- **재연결 시 누적, 대체 아님**: 연결을 다른 코디로 바꿔도 매번 새로 매칭이 발동하되, 기존에 이미 추가돼있던 옷은 지우지 않고 새로 연결한 코디의 옷만 추가(합집합으로 계속 누적).
- **반대 방향 적용 범위**: "스타일 일지 착용 옷 → 새 코디 아트보드 미리 배치"는 스타일 일지 열람의 연결 바텀시트에서 코디를 신규 생성할 때만 해당 — 코디 메인 [+]로 만드는 일반 신규 생성엔 적용 안 됨.
- **기본 배치 로직**: 현재 없음, 당장은 겹치지 않게 화면에 고르게 뿌리는 정도로만 구현. 나중에 별도 "기본 배치 로직"이 추가될 걸 감안해, 그 로직으로 쉽게 교체 가능한 구조로 만들 것(도입 시점은 별도 결정 필요).

사유:
스타일일지 열람 감사에서 자동 매칭 미구현을 발견 후, "발견은 맞지만 구현 방식이 아직 안 정해졌다"는 사용자 지적으로 세부 동작을 논의·확정.

Impact:
- `docs/reference/plan/03_화면별UX명세서/02_코디 (가상 조합).md` "자동 매칭" 항목 갱신 완료.
- 코드 변경 없음(Decision 단계) — 실제 구현은 "연결 바텀시트" 실제 구현과 함께 후속 Task로 진행.

---

[Decision] "연결 바텀시트" 패턴을 공통 규칙으로 일반화 (UI/Screen, Decision) — `_공통 규칙.md` 신설 섹션

결정:
- 옷-코디-스타일 일지 중 어떤 조합이든 서로 연결(바인딩)할 때 쓰는 UI를 "연결 바텀시트"라는 이름으로 공통 패턴화 — `02_코디 (가상 조합).md`(스타일일지 슬롯)/`03_스타일 일지.md`(코디 슬롯)에 각각 따로 서술돼 있던 내용을 `_공통 규칙.md` "연결 바텀시트" 섹션으로 통합, 두 문서는 그 섹션을 참조하도록 정리.
- 신규 확정 상세: 시트 좌상단 고정 위치에 [+] 타일로 새 대상 즉시 생성 가능. 생성 완료 후 원래 화면(빈 슬롯+시트 열림)이 진입 전 상태 그대로 복원 — 화면 전환처럼 안 느껴지고 그 자리에서 이어지는 느낌. 새로 만든 항목이 시트 목록에 나타나며 시트가 그 위치까지 자동 스크롤.
- 기존 "바인딩 뎁스 제한"/"미완성·휴지통 항목 바인딩 불가" 원칙은 그대로 이 시트에도 적용(신규 원칙 아님, 기존 것 재확인).

사유:
스타일일지 열람 감사에서 "코디 슬롯 미연결 시 신규 생성 불가" 발견을 논의하던 중, 사용자가 이 연결 UI의 정확한 동작(좌상단 고정 [+] 타일, 생성 후 원래 화면으로 프리즈된 채 복귀, 시트 자동 스크롤)을 구체화 — 동시에 이 패턴이 옷 상세를 포함해 콘텐츠 간 연결이 필요한 모든 지점에서 재사용될 범용 패턴이라고 확인, 화면별 문서에 중복 서술하지 않고 공통 규칙으로 옮기기로 결정.

Impact:
- `docs/reference/plan/03_화면별UX명세서/_공통 규칙.md`: "연결 바텀시트" 섹션 신설.
- `docs/reference/plan/03_화면별UX명세서/02_코디 (가상 조합).md`, `03_스타일 일지.md`: 각 화면의 관련 항목을 공통 규칙 참조로 축약.
- 코드 변경 없음(Decision 단계) — 현재 구현(`context.push`로 여는 전체화면 선택 화면)은 이 스펙이 요구하는 "하단 시트" 형태가 아니고, 좌상단 고정 [+] 타일/생성 후 프리즈 복귀/자동 스크롤도 전부 미구현 — 실제 구현은 후속 Task.

결정:
- `00_DataSchema.md`가 "`00_MVP.md` §4.3의 추가 사진 개념이 `wornItemIds`로 대체됐다"고 서술했던 것은 **오류** — `wornItemIds`(착용 옷, `ClothingItem` 참조)와 카드 3~10번 슬롯의 "추가 사진"(실제 업로드 이미지)은 서로 다른 별개 기능이다. `03_스타일 일지.md`가 정본.
- `StyleLog`에 `additionalImagePaths`(`array<string>`, Cloud Storage 경로) 필드를 스키마에 복원. 슬롯 상한 **10개**(대표사진 1번+코디 2번 고정, 추가 사진 최대 8장).
- 재배치 상호작용: 사진을 꾹 눌러 스냅 → 좌우로 드래그하면 인접 슬롯과 한 칸씩 순서 교환. 1·2번 슬롯은 재배치 대상 아님.
- 슬롯이 다 안 찼으면, 내용 있는 마지막 슬롯의 다음 슬롯에 [+] 버튼이 표시되어 그 자리에서 바로 사진 추가 가능.

사유:
스타일일지 열람 화면 레이아웃/데이터 감사 중 "카드 3번째 슬롯(추가 사진) 없음"을 발견 — 처음엔 `00_DataSchema.md`의 기존 서술(`wornItemIds`로 대체됨)을 근거로 "이미 결정된 사항, 새 버그 아님"으로 보고했으나, 사용자가 `03_스타일 일지.md`가 정본이며 `00_DataSchema.md` 쪽이 잘못됐다고 정정 — 둘은 애초에 다른 기능(착용한 옷 참조 vs 실제 추가 촬영 사진)이었음.

Impact:
- `docs/reference/data/00_DataSchema.md` §5 필드표+Note+§8 Storage 경로표 갱신 완료(오류 서술 제거, 필드 추가).
- `docs/reference/plan/03_화면별UX명세서/03_스타일 일지.md` — 슬롯 상한/재배치/[+] 버튼 상세 스펙 추가.
- 코드 변경 없음(Decision 단계) — 착수 시 `lib/models/style_log.dart`에 필드 추가, 카드 `PageView`를 3~10번 슬롯까지 확장하는 화면 구현 필요(스타일일지 열람 감사의 후속 구현 작업으로 BACKLOG에 등록 예정).

---

[Decision] 코디 편집기(Task A) — Editor Draft 모델 실제 적용 + `Composition.backgroundColor` 필드 추가 (Data/Architecture + UI/Screen, Decision)

결정:
- `composition_editor_screen.dart`(코디 만들기/편집)를 `docs/history/Decision.md`의 기존 "Editor 저장 모델 전환" 결정(Editor Draft + Commit/Cancel)에 맞춰 실제로 구현. `CompositionDraft` 모델 + `compositionDraftProvider`(family, compositionId별) 신설 — 아트보드 제스처(이동/회전/크기조절/삭제/배경색)는 전부 Draft에만 실시간 반영, Record(`compositionsProvider`)는 손대지 않는다.
- `EditorHeader`에 완료(✔) 버튼 추가(nullable `onCommit` 콜백, 다른 2개 Add/Create 스켈레톤 화면엔 영향 없음). 완료 시 Draft→Record 반영 후 Draft 폐기, 취소 시 Draft만 폐기(Record는 진입 이전 상태 그대로 — Rollback).
- `Composition`에 `ArtboardBackgroundColor? backgroundColor` 필드 신규 추가(기존 `season`/`weather`/`coverImagePath`와 동일한 `_unset` sentinel `copyWith` 패턴) — 배경색도 완료해야 저장되고 취소하면 사라지도록, Draft/Commit/Cancel 일관성을 배경색까지 확장.

사유:
Task A(옷장/코디 레이아웃 감사에서 발견된 "코디 상세에 아트보드 렌더링 없음" 갭 해소) 진행 중 Audit이 P1 발견: 처음 구현이 제스처마다 Record에 직접 저장하는 방식이었는데, 이는 기존 "Editor 저장 모델 전환" 결정 및 `_공통 규칙.md` §레코드 저장 원칙이 코디 편집기를 명시적으로 Editor Draft 대상으로 지정해둔 것과 정면으로 어긋남. 사용자가 즉시 Draft 모델로 리워크하기로 결정. 리워크 도중 Tester가 배경색이 완료해도 저장 안 되는 것(당시 `Composition`에 필드 자체가 없었음)을 발견 → 사용자가 필드 추가도 함께 결정(`00_DataSchema.md` Open Question #9가 이미 이 필드를 제안해둔 상태였음).

Impact:
- 신규: `lib/models/composition_draft.dart`, `lib/providers/composition_editor_providers.dart`(Draft provider 포함).
- 수정: `lib/models/composition.dart`(`backgroundColor` 필드), `lib/providers/composition_providers.dart`(`updateItems`/`add`), `lib/screens/composition_editor_screen.dart`(Draft 기반 전면 재작성), `lib/widgets/editor_header.dart`(`onCommit` 파라미터).
- `docs/reference/data/00_DataSchema.md` Open Question #9 — "제안" 상태에서 "실제 Dart 모델에 반영됨"으로 갱신.
- Worker→Review→Tester 사이클을 리워크 전/후 두 번, Audit도 두 번(최초 P1 발견 라운드 + 리워크 후 최종 재검토) 거쳐 통과 — 최종 Audit에서 남은 P2 다수는 `TechnicalDebt.md`/`BACKLOG.md`에 별도 기록.
- `ClothingItemDraft`/`StyleLogDraft`(다른 두 Editor 화면의 Draft)는 이번 스코프 밖 — 각 화면이 실제로 Editor 상호작용을 갖추는 시점에 개별 적용 예정.

---

[Decision] 코디 메인 [+] 버튼 — 분류별 자동 태그 적용 범위 확정, 라벨 전환은 보류 (UI/Screen, Decision)

결정:
- 분류(계절/날씨) 드릴다운 중 [+] 버튼으로 코디를 만들면, 보고 있던 분류값(season 또는 weather)을 새 코디에 자동 적용한다 — 두 기준 모두 동일한 방식으로 처리(계절이면 season, 날씨면 weather).
- 스펙(`02_코디 (가상 조합).md`)의 "라벨 [이 분류로 코디 만들기]로 전환" 요구는 **지금은 보류** — FAB은 아이콘 전용(`FloatingActionButton`) 그대로 유지, 텍스트 라벨 없음.

사유:
코디 메인 레이아웃/데이터 감사에서 발견 — 옷장 메인은 최소한 FAB 라벨 전환이라도 있었는데, 코디 메인은 그마저 없고 분류 자동 적용 로직 자체가 없었음. 사용자가 두 가지를 분리해서 판단: 자동 태그 적용 범위는 옷장과 같은 패턴으로 확정, 라벨 표시는 당장 필요 없다고 판단해 보류.

Impact:
- 코드 변경 없음(Decision 단계) — 실제 배선은 "코디 제작(에디터)" 착수 시점(현재 스켈레톤)에 함께 반영 예정, `docs/work/BACKLOG.md` "Editor Draft 구현" 항목에 포인터만 추가.
- 라벨 전환은 폐기가 아니라 보류 — 필요해지면 재검토.

---

[Decision] 동시 세션의 브랜치 체크아웃 충돌로 커밋 5개 고아화 — 병합으로 복구 (Data/Architecture, Decision — Operational process change / structural risk)

결정(사고 기록 + 복구):
- 이 세션이 설정화면 작업 중이던 사이, 같은 저장소 디렉토리에서 동작한 다른 세션이 `git checkout`으로 이 세션의 작업 브랜치(`feature/layout-data-audit`)를 `dev`로, 이어 새 브랜치 `feature/layout-data-audit-recovery`로 바꿔치기함 — 이 세션이 완료한 커밋 5개(설정화면 로그인/로그아웃 토글 구현 전체 사이클, Worker/Review/Tester 통과분)가 새 브랜치 히스토리에 없는 고아 상태가 됨(원격 미푸시 상태였음).
- `feature/layout-data-audit`(고아 커밋을 여전히 가진 로컬 브랜치)를 `feature/layout-data-audit-recovery`에 병합해 복구. 충돌은 `Decision.md`(둘 다 맨 위에 새 항목을 추가하는 로그 파일) 1개뿐, 커밋 타임스탬프 기준(이 세션 2026-08-04, 상대 세션 2026-08-05)으로 순서 정리해 해소. 코드 파일은 전부 무충돌 병합.

사유:
`Workflow_Project.md` §15는 이미 "저장소 안 worktree는 검색 중복을 일으킨다"는 이유로 병렬 세션을 저장소 바깥 형제 디렉토리에 두라고 규정하고 있었으나, 이번 사고는 그보다 더 심각한 위험(브랜치 체크아웃 자체가 서로를 덮어써 커밋을 고아로 만듦)을 보여줌. 복구 과정에서 발견한 커밋 `7f8b651`의 메시지도 유사한 "concurrent session's branch operations" 위험을 이미 한 번 언급하고 있어 반복되는 문제로 보임.

Impact:
- 코드 유실 없음(git object store에 남아있어 복구 가능했음) — 다만 로컬 전용 커밋이라 완전히 안전하진 않았던 상황.
- `feature/layout-data-audit`(구 브랜치)는 이제 `feature/layout-data-audit-recovery`에 완전히 포함됨 — 브랜치 삭제는 파괴적 작업이라 PM이 스스로 하지 않음, 사용자 판단 대기.
- 후속 검토 필요(사용자 판단): §15를 "검색 중복 방지"뿐 아니라 "브랜치 상태 충돌 방지"까지 포괄하도록 근거를 확장할지 — 서브에이전트 worktree뿐 아니라 사용자가 직접 여는 병렬 세션도 예외 없이 격리된 워크트리를 쓰도록 강제할지.

---

[Decision] `ClothingItem.lastWornDate`는 저장 필드가 아니라 파생값 (Data/Architecture, Decision) — `00_DataSchema.md` Open Question #3 해소

결정:
- `ClothingItem`에 `lastWornDate` 필드를 별도로 두지 않는다. 이 옷을 참조하는 `StyleLog` 중 `wornDate`가 null이 아닌 것들의 최댓값으로 클라이언트에서 파생시킨다(참조하는 `StyleLog`가 없거나 전부 `wornDate`가 null이면 마지막 착용일 없음).
- `TrashEntry`(§6)와 동일한 "파생 read model" 패턴 — write-time 집계(예: `wearCount`처럼 트랜잭션/배치로 갱신) 방식은 채택하지 않음.

사유:
옷 상세 화면 레이아웃/데이터 감사 중 "마지막 착용일 표시" 스펙 요구가 미구현으로 발견됨 — 확인해보니 `00_DataSchema.md` Open Question #3이 이미 같은 이슈를 "필드를 지금 미리 선언할지, 나중에 추가할지" 형태로 열어두고 있었음. 옷 상세 감사를 계기로 정확한 정의(연결된 스타일일지 중 최신 착용일)를 사용자가 직접 확정.

Impact:
- `docs/reference/data/00_DataSchema.md` §3/Open Question #3 갱신 완료(파생 규칙 명시).
- 코드 변경 없음(Decision 단계) — 착수 시 `lib/providers/closet_providers.dart` 또는 유사한 provider에 파생 로직 추가, `closet_item_detail_screen.dart`에 표시.

---

[Decision] 설정 화면 "로그인" 진입점 위치 확정 — 로그아웃 로우와 동일 슬롯에서 상태 전환 (UI/Screen, Decision — Implementation 태스크 중 결정, 사후 기록)

결정:
- 로그인 기능의 진입점 위치를 확정: 별도 화면/로우를 새로 만들지 않고, 설정 화면 "계정" 섹션의 기존 로그아웃 로우와 동일 슬롯을 재사용 — 로그인 상태면 "로그아웃"(destructive 스타일), 로그아웃 상태면 "로그인"(일반 스타일)으로 라벨/아이콘/색상만 전환.
- "로그인" 탭 시 실제 로그인 화면/인증 로직은 만들지 않고 "기능 준비 중입니다" AlertDialog만 노출(상태 변경 없음).
- `04_설정.md` §5가 "로그인 진입점 존재/위치는 범위 밖"으로 유보해뒀던 것 중 **위치**만 이번에 좁혀 확정 — 인증 연동/세션 무효화/계정연동/멀티기기 동기화는 여전히 Post-MVP(`00_MVP.md` §8) 범위 밖.
- 로그아웃→로그인 상태 전환 타이밍은 기존 C7 선례(`closet_main_screen.dart`의 `softDeleteMany`/`restoreMany`)와 동일하게 탭 즉시 낙관적 전환 + Undo 시 복원으로 통일(최초 구현은 Undo 만료 시점 전환으로 스펙과 반대로 구현됐다가 Review에서 P1으로 지적돼 정정).

사유:
사용자가 설정 화면에 로그인 버튼(준비중 팝업) 추가를 요청, 이어서 "로그인 상태면 로그아웃, 로그아웃 상태면 로그인으로 보이게" 토글로 구체화. Worker 구현 후 Review가 이 결정이 §5의 범위 유보와 충돌하는데도 문서/Decision.md에 반영이 안 됐음을 P1로 지적 — 새 화면/로우를 만들지 않고 기존 로그아웃 슬롯을 재사용하는 게 최소 변경이라 이 형태로 확정.

Impact:
- `lib/screens/settings_screen.dart`: `_isLoggedIn` state 신설, 로우 1개가 상태에 따라 분기, 전환 타이밍 정정.
- `docs/reference/plan/03_화면별UX명세서/04_설정.md` §2 로우4, §5 갱신(같은 세션에서 반영).
- 실제 로그인 인증/계정연동/멀티기기 동기화 스코프는 안 당겨짐 — 이 결정은 그게 착수되기 전까지 보여줄 placeholder UI 위치만 정한 것.

---

[Decision] §12.1 Data/API/Architecture×Decision 행에 §5 Decision-Stage Pipeline 적용 + `docs/reference/data/`·`docs/reference/architecture/` 폴더 신설 (Data/Architecture, Decision — Operational process change)

결정:
- `Workflow_Project.md` §12.1 표에서 Data/API/Architecture×Decision 행만 "Development Review (architecture), pre-review"에 머물러 있던 걸 UI/Screen·Logic/Feature Decision 행과 동일하게 "Development Review (architecture) + mandatory Audit before confirmation(크기 무관, §5 Decision-Stage Pipeline 적용)"으로 정정. §5 Pipeline 도입 시(2026-07-23, 아래 "설계/계획 확정 전 Audit 필수화" 결정) 이 행만 갱신이 누락돼 있었음.
- 같은 행의 Required Materials를 "Development workflow policy"(추상적)에서 "Plan reference docs(MVP/Needs/IA&UserFlow/화면별UX명세서) + `Decision.md`"로 구체화 — 화면에 노출되는 데이터 항목이 스키마 설계의 1차 입력이기 때문.
- Data/API/Architecture×Implementation 행 Required Materials에 "Finalized data model doc(`docs/reference/data/`)" 추가.
- `docs/reference/data/`(Firestore 컬렉션/필드 스키마 등 확정 데이터 모델 문서용) · `docs/reference/architecture/`(Auth/Storage 연동, 상태관리, 모듈 경계 등 앱 상위 구조 문서용, 현재는 빈 폴더) 신설. `docs/reference/design/`·`docs/reference/plan/`과 동급의 새 Reference 카테고리.
- `Workflow_Project.md` 버전 3.1 → 3.2 (§1.6 minor bump 대상: 표 내용 변경).

사유:
사용자가 DB 설계 세션과 화면별 기능 감사 세션을 병렬로 새로 착수하려던 중, PM이 기존 파이프라인이 이 두 산출물을 어디에 놓고 무슨 검증을 거치게 할지 점검 — Data/Architecture×Decision 행이 다른 두 Decision 행과 달리 확정 전 Audit 요구가 빠져 있었고, 그 결과물을 놓을 Reference 폴더 자체가 없었음을 발견. DB 스키마는 Firestore(이미 `00_MVP.md` §6에 결정됨)이므로 관계형 ERD가 아니라 컬렉션/문서 구조로 설계해야 함도 함께 확인.

Impact:
- 이번 세션은 정책/폴더 정비까지이며 코드 변경 없음.
- 후속: DB 설계 세션을 Layer=Data/Architecture, Stage=Decision으로 태깅해 §5 Pipeline(소단위 초안→Review→전체조립→Audit→확정)으로 착수 예정. 화면별 기능 감사는 기존 `audit` 서브에이전트 역할(Missing functionality 체크)을 그대로 재사용.

---

[Decision] 옷장 메인 레이아웃/데이터 감사 후속 — 핀치·검색·탭 애니메이션·정렬 UI 스펙 확정 (UI/Screen, Decision)

결정:
- 핀치 제스처(오므리기/벌리기)로 갤러리 밀도 조절 도입. 벌리면 밀도↓(타일 커짐)/오므리면 밀도↑. 기존 버튼과 동일한 3단계(`AppDensity.min/mid/max`)로 스냅하되, 버튼의 고정방향 순환(rotation) 로직은 재사용하지 않고 제스처 방향에 따라 자연스러운 순서로 이동 후 양 끝에서 clamp(래핑 없음). 제스처 중 실시간 확대/축소 피드백, release 시 임계값 기반 스냅. 스크롤 앵커링을 핀치+기존 밀도 버튼 둘 다에 신규 적용(현재 버튼엔 없던 기능). 롱프레스(다중선택)와 충돌 시 핀치 시작되면 롱프레스 타이머 취소.
- 검색 버튼(ExpandableSearchField) 인터랙션 확정: 원형 버튼이 오른쪽 가장자리를 앵커로 캡슐로 모핑, 왼쪽 툴바 컨트롤(분류/밀도)은 8~16px 밀리며 fade-out(자리 대체, 겹침 아님), 검색 아이콘은 애니메이션 내내 고정, 바운스 없음, 180~220ms `easeOutCubic`. 기존 `AppSpacing.searchExpand`=300ms 상수는 이 값으로 대체 필요.
- 툴바 레이아웃 재배치: 분류 캡슐+밀도 버튼(3/4 크기)을 왼쪽 그룹으로 묶고, 검색 버튼은 오른쪽 끝에 간격을 두고 단독 배치. `GalleryMainScreen` 공유 위젯이라 코디 메인에도 동일 적용됨.
- 탭 반응 애니메이션: 스케일다운(0.96~0.98배) 방식 확정, Material 리플 방식은 기각.
- 정렬 UI 구조: 분류 캡슐이 정렬 기준까지 겸하는 현재 구현 구조를 그대로 유지하기로 확정, `01_옷장.md`를 실제 구현 기준으로 갱신(정렬 전용 UI 분리안은 기각).
- 오름/내림차순 토글 버튼(↑↓)은 스펙에서 완전히 삭제 — MVP 이후로 미루는 게 아니라 기능 자체를 없앰. 정렬은 분류 캡슐의 고정 방향 기본값만 지원.

사유:
PR #20(Step⑦ Group B/C) 병합 후 사용자 승인 하에 진행한 "페이지별 레이아웃/노출 정보값 감사"에서 옷장 메인을 스펙(`01_옷장.md`)과 대조한 결과 핀치 제스처·텍스트 검색이 완전히 누락, 탭 반응 애니메이션 없음, 정렬 UI가 스펙과 다른 구조로 흡수 통합돼 있음을 발견(4건). 각각 사용자와 논의해 세부 동작을 확정. 정렬 방향 토글 버튼은 툴바 재배치 논의 중 처음엔 유지+축소 대상이었으나, 사용자가 이후 이 버튼 자체를 완전히 없애기로 결정(단순화).

Impact:
- 이번 세션은 감사+설계 확정까지이며 코드 변경 없음(구현은 별도 Worker 착수 예정).
- `docs/reference/plan/03_화면별UX명세서/01_옷장.md`: 분류+정렬 통합 서술로 갱신, 오름/내림차순 토글 언급 제거(사용자 직접 수정 포함).
- `docs/work/옷장메인_재설계_체크리스트.md`: "미착수(Task 4)" 섹션 및 "제스처 통합" 섹션에 위 스펙 반영.
- 착수 시 영향받는 코드: `lib/screens/closet_main_screen.dart`(밀도 로직/핀치 추가), `lib/widgets/gallery_main_screen.dart`(툴바 레이아웃 재배치, 정렬 버튼 제거), `lib/theme/app_spacing.dart`(`searchExpand` 상수값), `lib/providers/closet_providers.dart`(`closetSortAscendingProvider`/`ascending` 관련 정리) — `GalleryMainScreen` 공유 위젯이라 코디 메인도 함께 영향받음.

---

[Decision] Firestore 스키마 — 오프라인/로컬퍼스트 아키텍처 전면 확정 + 필드 4종 확장 (Data/API/Architecture, Decision) — 아래 "[Decision] 전체 앱 Firestore 데이터 스키마 설계 확정" 항목의 후속

결정:
- **Anonymous Auth 완전 폐기, 진짜 로컬퍼스트로 전환**: 이전 항목이 전제했던 "Anonymous Auth가 설치 즉시 uid 부여" 모델을 폐기 — 링크(소셜로그인: 구글/네이버/카카오/깃허브 후보, 미확정) 전엔 Firebase Auth 호출 자체가 없음. 대신 고정 로컬 placeholder 스코프(`unlinked_local` — 최초 제안 `__unlinked_local__`는 Firestore 예약 패턴(`__.*__`)과 충돌해 라운드2 Audit에서 발견·수정) + `disableNetwork()`로 완전 오프라인 동작, 링크 시점에 실제 uid로 문서 일괄 마이그레이션 + `enableNetwork()`. 상세: `00_DataSchema.md` §11.
- `wearCount` 집계: 기존 결정(client-side Firestore 트랜잭션)을 폐기 — 트랜잭션은 오프라인에서 동작 안 함. `WriteBatch`+`FieldValue.increment()`로 교체. 단, 같은 StyleLog를 여러 오프라인 기기가 동시 수정하면 카운터도 드리프트될 수 있음(라운드2 Review 발견, 배열 last-write-wins 문제와 별개) — 단일기기 전제라 지금은 추가 설계 안 함.
- 신규 필드: `User.lastActiveAt`/`lastSyncedAt`/`authProvider`, `ClothingItem.color`(자유텍스트→폐쇄형 enum 제안 전환)/`hasGraphic`/`hasPattern`(MVP 3택1 필드 대체)/`acquiredAt`/`analysisMetadata`+`analysisModelVersion`+`analyzedAt`(추천 알고리즘용 분석 버저닝, 내용은 미정), `Composition.tags`, `StyleLog.createdAt`+`wornDate`(nullable로 변경).
- `TrashEntry.createdAt`이 `StyleLog.wornDate`를 매핑하던 기존 코드 동작을 새 `StyleLog.createdAt`으로 옮기기로 확정(사용자 확인).
- 마이그레이션 시 이미지 파일(로컬 경로→실제 Storage 경로+업로드)도 별도 처리 필요함을 명시(라운드2 Audit 발견, 기존 "단순 문서 복사" 서술이 이미지 필드엔 안 맞았음).

사유:
사용자가 테이블별로 직접 리뷰(User→ClothingItem→Composition→StyleLog)하며 다수 필드를 확장/수정, 그 과정에서 "서버 연결 없이도 완전한 오프라인 로컬앱" 요구사항이 나와 §11을 두 차례 재작성. 리뷰 라운드2(Development Review architecture)가 P1 2건(§1 정당화 문구가 폐기된 Anonymous Auth 모델을 계속 인용/`wearCount` "안전하다" 주장이 동일 StyleLog 동시편집 케이스엔 안 맞음) 발견 후 수정·재검증 통과, 이어진 Audit 라운드2가 추가 P1 3건(`unlinked_local` 예약패턴 충돌/마이그레이션 시 이미지 처리 누락/이 Decision.md 항목이 낡음) 발견 — 앞 둘은 즉시 수정, 세 번째가 이 항목.

Impact:
- `docs/reference/data/00_DataSchema.md` 수정(경로도 `docs/reference/architecture/`에서 이동). 코드 변경 없음 — Decision 단계 문서만.
- 커밋(`feature/db-schema-design` 브랜치, 대표): `9bae16f`~`9f8fd9d`(라운드2 리뷰 대상 전체), `a2e1ac9`(Review 라운드2 수정), 이후 Audit 라운드2 수정 커밋.
- 후속 백로그: Open Question #11/#12(color enum, hasGraphic/hasPattern 실제 코드 반영)/#13·#19(Storage 오프라인 큐, 마이그레이션 시 이미지 처리)/#17(wornDate null 정렬 UI) — `docs/work/BACKLOG.md` 참고.

---

[Decision] 전체 앱 Firestore 데이터 스키마 설계 확정 (Data/API/Architecture, Decision)

결정:
- `docs/reference/data/00_DataSchema.md` 신설 — User/ClothingItem/Composition/StyleLog 4개 도메인의 Firestore/Cloud Storage 스키마를 정식화. `00_MVP.md` §5의 낡은 초안 대신 현재 `lib/models/*.dart`를 필드 형태의 소스오브트루스로 삼음.
- **최대 결정**: 사용자 스코프 서브컬렉션(`users/{uid}/clothingItems`, `.../compositions`, `.../styleLogs`) 채택 — flat 컬렉션+`userId` 필드 대신. 근거: Anonymous Auth가 설치 즉시 `uid`를 부여(부트스트래핑 공백 없음)/추후 계정 연결 시 `uid` 불변(마이그레이션 불필요)/보안 규칙이 구조적으로 더 안전(`userId` 필터 누락 위험 자체가 없음)/현재 교차유저 쿼리 필요 없음(향후 필요해지면 collection-group 쿼리로 커버 가능).
- 소프트삭제/휴지통: 별도 Trash 컬렉션 없음 — 3개 서브컬렉션의 `isDeleted`/`deletedAt` 필드로 클라이언트 쿼리(`where isDeleted==true`) 파생, 기존 `trashEntriesProvider` 패턴과 동일.
- `wearCount` 집계: 클라이언트 사이드 Firestore 트랜잭션 채택(Cloud Function 트리거 아님) — 1인 개발/개인용 우선 앱이라 배포 파이프라인 오버헤드가 정당화 안 됨.
- `Composition.items`(≤15개 상한 기확정)는 embedded array 유지, 1MiB 문서 한도 문제 없음(15개×~200byte≈3KB).
- `Composition.backgroundColor`(`ArtboardBackgroundColor` enum) 필드 추가 — Development Review가 최초 누락 발견(P1), 수정 후 재검증 통과.
- Editor Draft(`editor_drafts`) 토폴로지: 2026-07-15 결정("`editor_drafts` 컬렉션, `{recordType, recordId}` 키")이 멀티테넌시를 고려하지 않았던 점을 재확인, `users/{uid}/editorDrafts/{recordType}_{recordId}`로 중첩하는 안을 제안(§1 토폴로지와 일관) — 최종 확정 아님, 문서 내 Open Question으로 유지.

사유:
사용자가 Firestore 실제 백엔드 전환에 앞서 전체 데이터 모델 설계를 요청(2026-08-02). Worker 초안 → Development Review(architecture, 1라운드: P1 backgroundColor 누락/P3 낡은 인용 → 수정 후 재검증 통과) → Audit(홀리스틱, Decision-stage 확정 전 크기무관 필수) 순서로 진행. Audit이 추가로 P1 2건(Editor Draft 토폴로지 미반영 — 이 세션에서 즉시 수정/ `Workflow_Project.md` §5·§12.1 정책 문서 자기모순 — 사용자 판단으로 백로그 최우선 등록, 지금 안 고침)과 P2(텍스트검색 아키텍처 미기술)/P3(Open Question #5 목록 불완전)를 발견. P2/P3는 일반 백로그.

Impact:
- 신규 파일: `docs/reference/data/00_DataSchema.md`. 커밋(`feature/db-schema-design` 브랜치): `87f7b4f`(초안) → `588c136`(Review fix) → `6ba82b1`(Audit fix).
- 코드 변경 없음 — Decision 단계 문서만, 실제 Firestore 마이그레이션 구현은 별도 후속 Task.
- 후속 백로그: `Workflow_Project.md` §5/§12.1 Audit-필수 문구 누락 수정(P1, 최우선), 텍스트검색 아키텍처 보강(P2), Open Question #5 목록 보완(P3) — 전부 `docs/work/BACKLOG.md` 참고.

---

[Decision] 프로스티드 글래스 블러/채도/하이라이트 값을 원본 목업 CSS 기준으로 정정 (UI/Screen, Decision)

결정:
- `GlassPill`/`GlassCircleButton`/`AppDetailScaffold`(더보기 버튼) 3개 공용 글래스 프리미티브의 `BackdropFilter`를 `lib/theme/app_effects.dart`의 `AppGlassEffect.backdropFilter()`로 통일.
- 블러: `sigmaX/Y: 12` → `AppGlassEffect.blurSigma = 1.5`. 근거: 목업 CSS `backdrop-filter: blur(3px)`, CSS blur-radius ≈ 2×Gaussian-sigma(브라우저 구현 통용 근사) → 3÷2=1.5. 기존 값은 역산하면 CSS `blur(24px)`에 해당 — 목업 대비 8배 과블러였음.
- 채도: 기존엔 아예 없었음 → `AppGlassEffect.saturationBoost`(표준 SVG `feColorMatrix type="saturate"` 공식, s=1.8=180%)를 `ImageFilter.compose(outer: saturationBoost, inner: blur)`로 blur 다음에 적용(CSS 필터 리스트 `blur(3px) saturate(180%)`의 좌→우 적용 순서와 일치).
- Inset 하이라이트: `GlassInsetHighlight`(1px, `rgba(255,255,255,0.16)`) 신규 — 목업 CSS `inset 0 1px 0 rgba(255,255,255,0.16)`을 `BoxDecoration`이 지원 안 해서 별도 `Positioned` 레이어로 흉내.
- 부수 발견·수정: `category_toggle_dropdown.dart`/`classification_drilldown_capsule.dart`의 헤더 트리거 텍스트가 스타일 미지정으로 기본값(14/w500)을 상속 중이었음 — 목업(16px/700, 13px/600~700)에 맞춰 로컬 `.copyWith`로 좁게 수정(공용 `AppTypography.textTheme` 자체는 안 건드림).

사유:
사용자가 실제 앱을 구동해 Visual Review 하던 중 "프로스티드 글래스 효과가 전혀 유리 같지 않다"고 지적, 이전에도 여러 번 수정 요청했었다고 함 — PM이 원본 목업(`참고자료/목업/옷장 메인/옷장 메인.html`+스크린샷+`옷장 메인 화면.txt`)의 실제 CSS/스펙 값을 코드와 직접 대조해 정량적 원인을 확정. 배경색(`rgba(247,246,243,0.38)`)은 이미 정확히 일치했었고, 블러 강도·채도·인셋 하이라이트 3가지가 실제 원인이었음.

Impact:
- `lib/theme/app_effects.dart`(신규), `lib/widgets/glass_inset_highlight.dart`(신규), `glass_pill.dart`/`glass_circle_button.dart`/`app_detail_scaffold.dart`/`category_toggle_dropdown.dart`/`classification_drilldown_capsule.dart` 수정.
- Worker→Review(findings 없음, saturate 행렬/`ImageFilter.compose` 타입 직접 검증)→Tester(97개 케이스, 다른 화면들까지 폭넓게 재확인) 통과, 커밋 `f5b3b38`.
- 후속 홀리스틱 Audit이 무관한 기존 버그(Group B Task 7의 "선택" 버튼 스타일 누락, P1)를 추가 발견 — 별도 항목 없이 이번 세션에서 바로 수정, 커밋 `7a7bed5`. 상세는 `docs/work/BACKLOG.md` Last Completed 참고.

---

[Decision] 다크모드 `AppSemanticColors.primaryLight` 값 정정 — `colorScheme.primary`와의 충돌 해소 (UI/Screen, Decision)

결정:
- `lib/theme/app_colors.dart`의 `AppSemanticColors.dark.primaryLight`를 `0xFF93B5CC`(다크 `colorScheme.primary`와 완전히 동일했던 버그값) → `0xFF263F50`로 변경.
- `gray800`(=다크 `colorScheme.surface`) 재사용안은 기각 — `category_toggle_dropdown.dart`/`classification_drilldown_capsule.dart`의 팝업 메뉴 배경이 이미 `surface` 기반이라, 그 값을 쓰면 이 두 위젯의 "선택됨" 하이라이트가 메뉴 배경에 파묻힘.
- 대신 `primary`의 HSL(H≈204.2°, S≈35.8%)을 유지한 채 명도(L)만 23%로 낮춰 새 값 도출 — `TextButton` 기본 전경색(`colorScheme.primary`) 대비 5.09:1(AA), `onSurface` 텍스트 대비 9.08:1을 확보.

사유:
2026-07-29 Visual Review 세션에서 사용자가 발견한 "GlassToast 실행취소 버튼 가시성 부족"/"휴지통 필터칩" 수정 2건이 둘 다 `primaryLight`를 배경색으로 쓰는 `TextButton`이었는데, 다크모드에서 이 토큰이 `colorScheme.primary`(기본 텍스트색)와 완전히 같은 값이라 텍스트가 안 보였다 — 그 배치 완료 후 홀리스틱 Audit이 발견(P1). 라이트모드 값(`primary300`=0xFFC5D3C7)은 애초에 `primary500`(텍스트, 0xFF394550)과 별개 값이라 문제없었는데, 다크모드 값만 "기존 dark primary 재사용" 식으로 대충 채워져 있던 게 원인(이전 결정 기록 참고).

Impact:
- `lib/theme/app_colors.dart` — `primaryLight` 다크값만 변경, 나머지 팔레트 불변.
- 영향받는 4개 소비처(`GlassToast`, `trash_main_screen.dart` 필터칩, `category_toggle_dropdown.dart`, `classification_drilldown_capsule.dart`) 전부 실기기 다크모드 구동으로 재확인 완료(Tester) — 원래 버그(GlassToast/필터칩) 해소, 부수 개선(드롭다운/캡슐의 onSurface-on-primaryLight 대비가 기존 1.78:1→9.08:1로 개선, 원래 별개의 미달 이슈였음).
- 커밋 `0c16786`.

---

[Decision] Group B(다중선택 진입/실행 + 휴지통 복원·영구삭제·비우기) 구현 완료 — `GalleryMainScreen<T>` 제네릭 셸 아키텍처 채택 (Data/Architecture + UI/Screen, Decision)

결정:
- `docs/superpowers/specs/2026-07-21-multi-select-and-trash-design.md`를 Task 1~11(Task 12는 Group C에서 이미 만족돼 스킵, Task 13은 이 항목 자체)로 구현 완료.
- Main형 4개 화면(옷장/코디/스타일일지/휴지통)의 공용 로직(다중선택 모드 토글, 선택 id 집합, FAB 노출)을 `lib/widgets/gallery_main_screen.dart`의 `GalleryMainScreen<T>` 제네릭 셸 하나로 통합. 분류(그룹형 드릴다운) 기능은 `ClassificationConfig<T>?`로 옵트인 — 옷장/코디는 제공, 스타일일지는 `null`(플랫+필터), 휴지통은 `GalleryMainScreen<T>` 자체를 안 쓰고 `AppMainScaffold` 직접 배선(2버튼 헤더+필터칩 구조가 달라서).
- 다중선택 상태는 전역 provider가 아니라 `GalleryMainScreen`의 로컬 `State` — 화면을 벗어나면 자동 초기화.
- 3개 모델(`ClothingItem`/`Composition`/`StyleLog`) 전체에 `deletedAt`(nullable) 필드 + `copyWith` sentinel 패턴 확장, `TrashEntry.remainingDays`를 `daysUntilPurge`로 명명 변경.
- 휴지통은 별도 mock provider(`mockTrashEntries`)를 없애고 3-domain 파생 집계(`trashEntriesProvider`)로 전환 — 삭제/복원/영구삭제가 각 도메인 provider(`softDeleteMany`/`restoreMany`/`purgeMany`)에서 바로 반영됨.
- 영구삭제는 실제 데이터 제거 + 안전가드 3곳(코디 커버이미지 폴백/아트보드 렌더링 skip/스타일일지 연결끊김 처리) — 캐스케이드 배지 UX는 "Editor Draft 구현" 후속 이관 유지.
- Detail 3화면(옷/코디/스타일일지 상세)의 "더보기" 메뉴에 실제 [삭제] 연결 — 옷은 코디 사용중이면 확인다이얼로그, 코디/스타일일지는 즉시삭제(코디 자체를 참조하는 다른 엔티티 개념이 없어서, `TechnicalDebt.md`의 "사용 중 경고 없음" 항목 참고).
- 소프트삭제된 항목이 다른 도메인의 크로스 레퍼런스(옷↔코디, 코디↔스타일일지)에 여전히 정상처럼 보이고 탭되는 문제를 발견 즉시 수정하는 정책을 이 라운드에서 확립: **목록/슬롯에서 제외하지 않고, `StatusBadge('삭제됨')` 오버레이 + 탭 차단.** 실제 3개 지점(코디 상세의 "사용된 옷", 스타일일지 열람의 "착용 옷"/"연결된 코디")에 전부 적용 완료.

사유:
Group B 스펙(review 2회 통과)과 구현계획(review 1회+홀리스틱 Audit 1회 통과, 13 Task)을 그대로 따라 진행. 4개 Main형 화면이 다중선택/휴지통 로직을 각자 중복 구현하지 않고 제네릭 셸로 통합하는 게 유지보수 비용을 줄인다는 판단은 계획 확정 시점에 이미 내려짐(이 Decision은 그 계획이 실제로 끝까지 구현됐음을 기록). 소프트삭제 크로스 레퍼런스 배지 정책은 사용자가 2026-07-29 세션 중 명시적으로 확정(제외 옵션과 비교해 "삭제됐다는 사실 자체를 숨기지 않는" 쪽을 선택).

Impact:
- `lib/widgets/gallery_main_screen.dart`(신규), `lib/screens/{closet,composition,style_log,trash}_main_screen.dart`(전면 재작성), `lib/screens/app_detail_scaffold.dart`+Detail 3화면(더보기 메뉴 실배선), `lib/providers/{closet,composition,style_log}_providers.dart`(`softDeleteMany`/`restoreMany`/`purgeMany`+`trashEntriesProvider`), `lib/models/*.dart`(`deletedAt` sentinel), `lib/widgets/glass_toast.dart`(신규), `lib/widgets/status_badge.dart` 재사용(삭제 배지).
- 관련 커밋(대표): `72366f2`/`540ee83`(Task1) `d2c3e3e`(Task2) `14c0ec0`+`029641e`(Task3) `1e1ae17`(Task4) `4487d29`(Task5) `a890c61`(Task6) `7763214`(Task7) `0c5360d`(Task8) `c0e173e`(Task9) `03b7c64`(Task10) `6a0125c`(Task11) — 상세 경위는 `docs/work/BACKLOG.md` git 이력 및 각 커밋 메시지 참고, 이 항목은 요약만 유지.
- **밀린 Visual Review(Typography Pass 3 이후 누적된 신규 화면/컴포넌트 대상, `Workflow_Design.md` §2.1)는 이 시점에도 아직 트리거 안 됨** — 2026-07-21에는 "Group B 완료 시점에 트리거"라고 사용자 확정했었지만, 실제 트리거 방식(PM 셀프 판정 vs 사용자 직접 확인)은 아직 미정(`docs/work/Questions.md` 참고, 2026-07-29 세션이 사용자 부재로 보류함). Design Tokens는 계속 provisional 상태 유지.

---

[Decision] `GlassToast`/`UndoableActionToast` 2종 공존 확정 — 화면군별 시각 변형, 중복 아님 (UI/Screen, Decision)

결정:
- `lib/widgets/glass_toast.dart`(Overlay+`GlassPill` 기반)와 `lib/widgets/undoable_action_toast.dart`(`ScaffoldMessenger`+`SnackBar` 기반)를 하나로 통합하지 않고 그대로 공존시킨다.
- `GlassToast`는 Glass 셸 화면(옷장/코디/스타일일지 메인+Detail — 다중선택 삭제, Detail "더보기" 삭제)용, `UndoableActionToast`는 plain Utility 화면(설정 — 로그아웃)용으로 화면군에 따라 구분해서 쓴다.
- 두 위젯 모두 `06_Component Strategy.md`의 "C7 UndoableActionToast"(메시지+액션+자동소멸 타이머, record-level undo) 상호작용 계약을 구현하는 동일 패턴의 서로 다른 시각 변형이다 — 이름이 겹치는 건 우연이며 별도 통합 리네이밍은 하지 않는다(이미 각 소비 화면에 자연스럽게 자리잡은 이름 유지가 혼란이 적음).
- 공용화한 부분: 자동소멸 기본 지속시간만 `AppDurations.toastDefault`(`lib/theme/app_spacing.dart`)로 추출해 두 위젯이 공유. 그 외(시각 스타일/접근성 wiring 등)는 각자 구현 유지.

사유:
Group B Task 6(`GlassToast` 신설) Review가 두 위젯이 같은 인터랙션을 중복 구현한 것 아니냐고 P1 지적 — `GlassToast`를 규정한 스펙(`docs/superpowers/specs/2026-07-21-multi-select-and-trash-design.md` §5, 2026-07-21 작성, review 2회 통과)이 작성된 시점엔 코드베이스에 Toast/SnackBar 패턴이 전혀 없어 "이 앱이 이미 쓰는 글래스 팔레트와 일관된 커스텀 위젯을 신설한다"고 명시적으로 결정했었다. `UndoableActionToast`는 그보다 나중(Group C Task 1, 2026-07-27, 설정 로그아웃용)에 별도로 생겨 겹쳐 보이게 됐을 뿐 — 실제로는 화면군(Glass 셸 vs plain Utility, `03_화면별UX명세서.md`의 페이지 타입 분류상 근거 있는 구분)이 달라 시각 언어가 다른 게 맞고, 통합하면 오히려 Glass 셸 화면에 어울리지 않는 기본 `SnackBar`가 노출되거나 Utility 화면에 불필요한 Glass 스타일이 들어가는 역효과가 생긴다. PM이 두 스펙 문서(Component Strategy/multi-select-and-trash-design)를 대조해 확정, 사용자 확인 없이 진행(근거가 이미 승인된 문서에 명시돼 있어 새로운 판단이 아니라 기존 결정의 적용).

Impact:
- `lib/widgets/glass_toast.dart` — 접근성(A13 라이브 리전) 추가, docstring에 공존 사유 명시
- `lib/widgets/undoable_action_toast.dart` — `AppDurations.toastDefault` 참조로 소폭 변경(기존 동작 불변)
- `lib/theme/app_spacing.dart` — `AppDurations` 클래스 신설
- 향후 Task 7 이후(다중선택 삭제 플로우 실배선) 이 구분을 그대로 따를 것 — 헷갈리지 말고 Glass 셸 화면엔 `GlassToast`, Settings류 plain Utility 화면엔 `UndoableActionToast`

[Decision] 설정 화면 최종 로우 구성 확정 — 프로필 편집 제외, 다크모드/휴지통/로그아웃 확정 (UI/Screen, Decision)

결정:
- `SettingsScreen` 최종 로우 구성을 4개(알림 토글, 다크모드 토글, 휴지통 진입, 로그아웃)로 확정. "일반"(알림/다크모드/휴지통) + "계정"(로그아웃) 2섹션.
- "프로필 편집" 로우는 채택하지 않는다 — 이 앱에 사용자 프로필/로그인 개념 자체가 존재하지 않음(MVP 기획 어디에도 프로필 엔티티 없음). 기존 구현(`lib/screens/settings_screen.dart`)에 스펙 밖으로 임의 추가돼 있던 항목이었음.
- 다크모드 로우는 유지하되, 이 결정은 **UI 토글 로우의 존재만** 확정한다 — 실제 `ThemeMode` 전환(현재 `main.dart`가 `ThemeMode.light` 고정)은 별도 Logic/Feature 구현 태스크로 분리, `BACKLOG.md`에 등록.
- 휴지통 진입 로우 신설 — 기존에 이미 독립 존재하는 `TrashMainScreen`(`/trash`)으로의 진입 경로만 추가. 화면 신규 제작이나 라우트 재설계는 필요 없음(라우트가 이미 `settingsMain`/`trashMain`으로 분리돼 있어 구 스펙의 라우트 네이밍 충돌 우려는 이미 해소된 상태였음).
- 로그아웃 로우는 2026-07-09 원 승인 스펙(§2/§3, Toast+Undo 패턴)을 그대로 채택 — 지금까지 미구현 상태였던 것을 이번에 실제 구현 대상으로 확정.
- 위 결정에 따라 `docs/reference/plan/03_화면별UX명세서/04_설정.md` §2/§4/§6을 정정 각주 방식으로 갱신(원문은 취소선으로 보존).

사유:
`TechnicalDebt.md`에 P1로 기록돼 있던 "SettingsScreen이 승인 스펙과 어긋남" 항목(다크모드/프로필편집이 스펙 밖으로 추가돼 있고, 로그아웃 로우 자체가 없는 드리프트)의 최종 처리 방향을 사용자가 직접 결정 — 착수 조건이었던 "스펙대로 재구현 vs 현재 확장을 정식 스펙 갱신 대상으로 삼을지"에 대해 후자(확장 일부 정식 채택 + 프로필 편집만 제외)로 답함.

Impact:
- `docs/reference/plan/03_화면별UX명세서/04_설정.md`(스펙 갱신)
- `docs/history/TechnicalDebt.md`(해당 P1 항목 해소 처리)
- `docs/work/BACKLOG.md`(그룹 C 구현 태스크로 등록 — 화면 구현 + 다크모드 실동작 배선 + 프로필 편집 삭제 체크리스트)
- 구현 대상(다음 세션): `lib/screens/settings_screen.dart`, `integration_test/closet_main_screen_test.dart`, `integration_test/settings_trash_shell_test.dart`

Audit(2026-07-27, Decision-Stage 필수 게이트): P1 1건 — §4 문구가 "휴지통 복원/영구삭제/비우기가 이미 동작"하는 것처럼 읽혔으나 실제로는 `TrashMainScreen`의 해당 버튼이 전부 스텁(그룹 B Task 10 미착수)임을 지적, 즉시 정정 반영. 그 외 4개 파일 간 정합성/라우트 실재 여부/테스트 위치 전부 확인됨 — 확정.


[Decision] 라우터+앵커 재통합 부분 롤백 — 5개 중 2개(핫패스 참조 문서)는 서브파일 구조로 복귀 (Data/Architecture, Decision — 바로 아래 "라우터+앵커 구조 부모 문서 5종을 단일 파일로 재통합" 항목의 스코프 축소)

결정:
- `docs/reference/design/00_DesignPrinciples.md`(6개 서브파일)와 `docs/reference/plan/03_화면별UX명세서.md`(7개 서브파일) — 방금 병합했던 5개 중 이 2개만 서브파일 구조로 되돌린다. 나머지 3개(`Workflow_Project.md`/`Workflow_Design.md`/`Workflow_Development.md`)는 병합 유지.
- 이 2개를 되돌리는 이유: §12.1 Required Materials에 직접 걸려 있어 진행 중인 Flutter Hi-Fi 스프린트의 거의 모든 화면 Task마다 Worker/Review에게 "특정 섹션 하나만" 좁게 Read되는 핫패스 문서인데, `Read` 툴이 기본적으로 파일 전체(최대 2000줄)를 읽어들이는 구조상 병합 후엔 필요 없는 다른 5~6개 섹션까지 매번 컨텍스트에 딸려 들어와 오히려 토큰 낭비였음. 반면 정책 문서 3종은 PM이 스스로 전체를 훑는 빈도가 훨씬 높고 Worker에게 좁게 슬라이스해 넘기는 빈도는 낮아 병합 손해가 작음.
- 되돌린 2개 문서의 버전은 이번 세션에서 실질적으로 내용이 바뀐 게 없어(구조만 병합→복귀를 왕복) 2.0 그대로 유지 — 범프하지 않음.
- 이 2개 문서를 가리키던 ~30개 상호참조(lib/, integration_test/, docs/superpowers/, docs/work/, TechnicalDebt.md)도 전부 서브파일 경로로 재복귀. `Workflow_Project.md` §12.4 Task Manifest 예시도 원래의 서브파일 경로 예시로 되돌림.

사유:
사용자가 병합 직후 실사용 관점에서 재검토 — "토큰이 빨리 녹아서 요새 문제"라는 피드백. 열람 편의(원래 목적)와 토큰 비용을 다시 저울질한 결과, 5개를 뭉뚱그려 판단하지 않고 실제 사용 패턴(핫패스 vs PM 전용 정책 문서)에 따라 문서별로 다르게 판단하는 게 맞다고 확인.

Impact:
- `docs/reference/design/00_DesignPrinciples.md` + 6개 서브파일 복원
- `docs/reference/plan/03_화면별UX명세서.md` + 7개 서브파일 복원
- `.claude/policies/Workflow_Project.md` §12.4 예시 복원
- 위 두 문서를 가리키던 상호참조 전체 원복(약 30개 지점)

---

[Decision] 설계/계획 확정 전 Audit 필수화 — 크기 무관 신규 Decision-Stage Pipeline (Data/Architecture, Decision — Operational process change)

결정:
- `Workflow_Project.md` §5에 "Decision-Stage (Design & Plan) Pipeline" 신설: 설계 스펙(UI/Screen×Decision)·구현 계획(Logic/Feature×Decision) 모두, 크기 무관, "작은 단위 Review 반복 → 초안 조립 → Audit 1회(항상) → 확정" 흐름을 따른다.
- §12.1 표 두 행(UI/Screen×Decision(Design), Logic/Feature×Decision(Planning)) 모두 "+ mandatory Audit before confirmation (크기 무관)"으로 갱신 — §5 본문과 §12.1 표가 따로 놀아 어긋나는 걸(과거 "§7 vs §12.1 모순" 사례와 같은 유형) 미리 방지.
- Planning 단계의 "작은 단위 Review"는 `writing-plans` 스킬의 구조화된 Self-Review(Spec coverage/Placeholder scan/Type consistency) + 관련 정책 문서 대조 승인이 있으면 별도 `review` 서브에이전트 호출 없이 충족되는 것으로 인정(단, 이 경우도 확정 전 Audit은 예외 없이 돈다) — 이는 §1.1(Role Separation)이 요구하는 완전한 독립 검증은 아니라는 걸 인지한 상태의 의도적 트레이드오프다: (a) Design 단계는 이미 독립 Review가 강제되어 비대칭이 없고, (b) Audit이라는 두 번째 독립적 눈이 Planning 단계에도 항상 걸리며, (c) 매 plan 섹션마다 subagent를 부르면 오버헤드가 커져 원칙 자체가 실무에서 지켜지지 않을 위험이 크다는 실용적 판단.
- `.claude/agents/audit.md`의 frontmatter description과 "When you run" 섹션에 이 새 트리거 지점(설계/계획 확정 전, 크기 무관) 반영.

사유:
사용자가 이번 세션에서 직접 요청 — "작업 전에 항상 설계와 계획을 먼저 선행하고, 설계와 계획은 작은단위로 review, 확정 전 audit 검수 꼭 하기". 지금까지 Audit은 L/XL 구현 태스크가 끝난 뒤에만 자동으로 돌아, 설계/계획 단계의 결함(정책 충돌, 프로젝트 전체와의 불일치)이 구현 이후에야 발견되는 구조였음 — 발견이 늦을수록 재작업 비용이 커지므로, 확정 이전 시점에 Audit 게이트를 추가.
이 원칙 자체가 즉시 자기 자신에게 적용됨: 이 항목을 포함한 이번 세션 전체 작업 플랜이 실행 전에 `review` 1회(P0 없음, P1 2건/P2 3건 전부 반영) → `audit` 1회(P1 3건/P2 1건/P3 1건, P3 제외 전부 반영)를 거쳐 확정됐음 — 사용자가 "이 계획에 대해서부터 review, audit을 새 원칙대로 진행 가능해?"라고 명시적으로 요청.

Impact:
- `Workflow_Project.md` §5/§12.1
- `.claude/agents/audit.md`

---

[Decision] Task 완료 시 연속성 시뮬레이션 + `/clear` 권유 절차 신설 (Data/Architecture, Decision — Operational process change)

결정:
- `Workflow_Project.md` §3에 "Post-Completion Continuity Simulation & `/clear` Recommendation" 신설, §10 Definition of Done에 체크박스 추가. Task 단계가 완료됐고 PM이 "세션 내 후속 작업이 더 없다"고 판단하면, `docs/work/BACKLOG.md`(+ 방금 추가된 Decision.md/TechnicalDebt.md 항목)를 새 세션 입장에서 재검토해 연속성을 시뮬레이션하고, 문제 없으면 사용자에게 `/clear`를 (실행이 아니라) 권유한다. Task 크기(S/M/L/XL) 무관 적용 — 단, PM이 세션 내 후속 작업이 이미 대기 중이라고 판단하면 매번 반복하지 않는다.
- `CLAUDE.md` "필수 체크포인트"에 짧은 포인터 문장 추가.

사유:
사용자가 이번 세션에서 직접 요청 — "연속 작업이 필요 없을 것 같은 작업에 대해 BACKLOG 기록 후 새 세션 인계를 시뮬레이션해서 문제없으면 clear를 권유하는 멘트를 했으면 좋겠다". 기존 §3 "Skill-Internal Ledgers vs. Official Handoff"에 있던 "recorded so a future session can continue라고 보고하기 전 실제로 그 경로를 검증하라"는 원칙을 애드혹 체크에서 공식 필수 절차로 격상하고, 여기에 `/clear` 권유 액션을 결합했다.

Impact:
- `Workflow_Project.md` §3/§10
- `CLAUDE.md` 필수 체크포인트 목록

---

[Decision] 라우터+앵커 구조 부모 문서 5종을 단일 파일로 재통합 (Data/Architecture, Decision) — 2026-07-10 결정 일부 되돌림 + 미기록 분리 3건 통합

결정:
- `.claude/policies/Workflow_Project.md`(서브파일 8개), `Workflow_Design.md`(2개), `Workflow_Development.md`(1개), `docs/reference/design/00_DesignPrinciples.md`(6개), `docs/reference/plan/03_화면별UX명세서.md`(7개) — 총 24개 서브파일을 각 부모 파일 하나로 재병합하고 서브파일은 삭제.
- 이 중 2개(`Workflow_Project.md`/`Workflow_Design.md`)는 2026-07-10에 명시적으로 기록된 라우터+앵커 결정(아래 관련 항목 참고)을 되돌리는 것이고, 나머지 3개(`Workflow_Development.md`/`00_DesignPrinciples.md`/`03_화면별UX명세서.md`)는 같은 시기 같은 패턴으로 분리됐으나 그 분리 자체를 기록한 Decision.md 항목이 애초에 없었던 것을 이번에 통합한 것 — 두 성격을 구분해 기록한다.
- 5개 파일 모두 §1.6 기준 구조 변경(major)으로 버전 범프: `Workflow_Project.md` 2.6→3.0(같은 세션에서 바로 이어 진행한 §3/§5/§10/§12.1 내용 추가(아래 두 항목)까지 포함해 한 리비전 패스로 3.0 하나만 부여), `Workflow_Design.md` 2.2→3.0, `Workflow_Development.md` 1.3→2.0, `00_DesignPrinciples.md` 2.0→3.0, `03_화면별UX명세서.md` 2.0→3.0.
- `Workflow_Project.md`/`00_DesignPrinciples.md`/`03_화면별UX명세서.md`/`Workflow_Development.md` 4개 파일 상단에 목차(TOC) 추가 — `Workflow_Design.md`는 병합 순증이 적어(~15줄) TOC 없이도 스캔 가능해 생략.
- 저장소 전체(`lib/`, `integration_test/`, `.claude/`, `docs/superpowers/`, `docs/work/`)에서 옛 서브파일 경로/파일명을 참조하던 지점을 새 경로("파일 §섹션")로 갱신. `docs/history/Decision.md`는 과거 시점 기록이라 전혀 손대지 않음(옛 경로가 그대로 남아있는 게 정상 — 이 항목이 그 예). `docs/history/TechnicalDebt.md`는 원칙적으로 동일하게 두되, 아직 미해결(open) 상태인 항목들은 죽은 경로가 다음 세션 연속성을 실제로 해칠 수 있어 예외적으로 경로만(내용/판단은 불변) 갱신했다.
- `00_DesignPrinciples.md` Stage 2/3(Interaction/Layout Principles) 헤딩은 부모의 구 포인터 헤딩이 아니라 서브파일의 실제 헤딩("(Revised)"/"(Revised v2)")을 채택 — 서브파일 쪽이 최신 유효 버전이었음.

사유:
사용자가 이번 세션에서 "문서 세부항목 앵커화 되어있는 것 통합"을 직접 요청 — 목적은 Claude가 문서를 열람할 때 여러 파일을 오가지 않고 한 파일 안에서 맥락을 파악할 수 있게 하는 것. 2026-07-10 결정의 원래 근거("Task Manifest가 좁은 스코프만 넘길 수 있게")는 여전히 유효하지만, 병합 후에도 Task Manifest는 "파일 §섹션" 단위로 여전히 좁게 지정 가능해 그 이점이 크게 훼손되지 않는다고 판단한 반면, 여러 파일을 오가는 열람 비용은 이 시점에 더 크다고 사용자가 명시적으로 판단해 재우선순위화했다.

Impact:
- (파일별 세부 변경은 위 결정 문단 참고)
- 이 병합 작업 자체가 바로 위 두 항목이 신설한 "Decision-Stage Pipeline" 원칙을 스스로 적용받음 — `review` 1회(P0 없음, P1 2건/P2 3건 전부 반영) → `audit` 1회(P1 3건/P2 1건/P3 1건, P3 제외 전부 반영) 통과 후 확정.

---

[Decision] 헤더 드롭다운 텍스트 확대·중앙정렬, 설정 구분선 연한 색, 분류 캡슐을 단일 GlassPill+내부 구분선으로 재통합 (UI/Screen, Decision — Header/HUD Pinned Rule 예외 포함)

결정:
- `CategoryToggleDropdown` 메뉴: 옷장/코디/스타일일지 3항목 텍스트를 `titleMedium`(16, w600)으로 확대, 4항목(옷장/코디/스타일일지/설정) 전부 고정폭(120) 박스 안에서 가운데 정렬. "설정" 항목의 `PopupMenuDivider`는 `AppSemanticColors.gray200`(팔레트 기반 연한 회색)로 지정.
- `ClassificationDrilldownCapsule`: 직전 결정(바로 아래 항목)이 Header/HUD Pinned Rule 준수를 위해 독립 GlassPill 2개로 분리했던 것을 **다시 하나의 GlassPill로 통합**하고, 중분류/소분류 두 `DropdownButton` 사이에 얇은 세로 구분선(1px, `AppSemanticColors.gray200`)을 넣는 구조로 되돌린다.
- **Pinned Rule 예외 처리**: `glass_pill.dart` docstring 및 Pinned Rule 항목이 "여러 컨트롤을 하나의 GlassPill 안에 함께 담지 않는다 — 변경 시 사용자 승인 필수"라고 명시한 규칙에 대한 명시적 예외다. 사용자가 "캡슐 이미지 하나 쓰고, 중분류 소분류 사이 구분 사이선으로 구분해"라고 대화 중 직접 지시했고, 이 지시 자체가 필요한 사용자 승인으로 간주해 규칙 예외를 적용했다. `glass_pill.dart`의 규칙 서술 자체는 고치지 않음(일반 원칙은 유지, 이 캡슐 하나만 예외).

사유:
사용자가 실제 화면을 보고 직접 3가지 UI 조정을 지시(2026-07-20): 헤더 드롭다운 텍스트가 작아 보임, 설정 구분선이 너무 진함, 분류 캡슐이 두 개의 분리된 알약처럼 보이는 게 의도와 다름(하나의 캡슐 + 내부 구분선을 원함).

Impact:
- `lib/widgets/category_toggle_dropdown.dart` — 항목 스타일/정렬, `PopupMenuDivider` color.
- `lib/widgets/classification_drilldown_capsule.dart` — `Row(GlassPill, SizedBox, GlassPill)` → `GlassPill(Row(...))`, 내부에 `Container` 세로 구분선 추가.
- `test/widgets/classification_drilldown_capsule_test.dart` — `AppSemanticColors` extension을 쓰는 위젯이라 `MaterialApp(theme: AppTheme.light)` 누락 시 null-check 에러가 남을 발견, 두 테스트 모두 테마 추가.
- 회귀 확인: `flutter analyze`/`flutter test`(66/66) 전체 통과, `integration_test/`(`app_main_scaffold_shell_migration_test.dart` 3/3 — 360px 좁은 뷰포트 오버플로 없음 확인, `closet_main_screen_test.dart` 28/28, `classification_drilldown_test.dart` 12/12, `selection_modal_test.dart` 7/7) 직접 실행 확인.

---

[Decision] 옷장·코디 메인 헤더 — 분류 기준 드릴다운 캡슐 + 설정 진입점 이동 (UI/Screen, Decision — Implementation 완료)

결정:
- `docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md`를 그대로 구현(Task 1~7, Worker→Review→Tester 사이클 전부 통과, Task 7 통과 후 Audit 1회 추가 — P0 없음). 옷장/코디 메인의 `groupingBar` skeleton을 `[중분류▾][소분류▾]` 2세그먼트 캡슐로 교체하고, 메인 그리드가 플랫/그룹개요(폴더카드)/드릴인 3상태를 갖도록 배선했다.
- 이 결정은 두 개의 이전 결정을 **대체**한다: (a) `2026-07-12-cross-screen-ui-shell-design.md` §2의 "그룹형 드릴다운" 설계(`GroupedMainViewMode` 3단계 enum, 계절 전용, `AppMainScaffold.groupingBar` 전체폭 밴드) — 최종 목업과 맞지 않아 폐기, 해당 문서 §2에 정정 각주 추가함. (b) `04_설정.md` §1(설정 진입점=프로필 아이콘) — 최종 목업에 프로필 아이콘이 없어 폐기, `CategoryToggleDropdown` 메뉴 최하단(구분선+작은 폰트)으로 대체, 해당 문서 §1에 정정 각주 추가함.
- **`ClassificationDrilldownCapsule`이 하나의 `GlassPill`이 아니라 독립된 `GlassPill` 2개를 `Row`로 나열하는 구조로 구현됨**: `glass_pill.dart` docstring이 "여러 컨트롤을 하나의 GlassPill 안에 함께 담지 않는다"(Header/HUD Pinned Rule)고 명시하고, 이 규칙 변경은 사용자 승인이 필요하다고 이 저장소가 이미 규정해뒀음(Pinned Rule 항목, "Layout Principle, 변경 시 사용자 승인 필수"). 최초 구현(Task 5)은 하나의 GlassPill에 두 DropdownButton을 담아 이 규칙과 충돌했고, Review가 이를 지적 — 승인을 구하는 대신 기존 규칙을 그대로 준수하는 구조(독립 GlassPill 2개)로 재구현해 예외 승인 자체를 우회했다. 시각적으로는 여전히 붙어 보이는 2세그먼트 캡슐.
- **정렬 방향(`ascending`) 의미 — "전역 단순 규칙" 채택**: 스펙 §3.2 "기본 정렬 순서" 표(옷종류=머리→발, 계절=봄가을→여름→겨울, 날씨=맑음→비→눈)와 §3.6의 provider 기본값(`ascending=false`) 사이에 스펙이 명시하지 않은 간극이 있었음(§3.6 주석은 날짜/착용빈도만 근거를 댐). 두 가지 해석 후보를 `docs/work/TO_사용자결정.md`에 기록해 사용자에게 직접 확인 — 사용자가 **"ascending=true는 모든 기준에서 예외 없이 index/날짜 오름차순"이라는 단일 전역 규칙**을 명시적으로 선택(코드 단순성 우선). 그 결과 옷종류/계절/날씨의 **기본 표시는 §3.2 표와 반대 방향**(발→머리, 겨울→여름→봄가을, 눈→비→맑음)이 된다 — 승인된 tradeoff, 재작업 대상 아님. Tester가 실제 화면에서 실측 확인(기본=내림차순 아이콘, 토글 1회=§3.2 표 순서로 전환).
- `AppMainScaffold.groupingBar`/`groupingBarHeight`/`defaultGroupingBarHeight`는 이 변경 이후 소비자가 0개가 되어 완전히 삭제(YAGNI).

사유:
`docs/work/BACKLOG.md` "Step⑦ 나머지 스코프" 그룹 A 항목("그룹형 드릴다운 실배선(옷장/코디 메인 2곳) + 설정 진입점 연결") 진행. 사용자가 제공한 최종 확정 목업을 근거로 기존 두 결정(그룹형 드릴다운 설계, 프로필 아이콘 진입점)을 대체하기로 확정(2026-07-19).

Impact:
- 신규: `lib/providers/classification_models.dart`(`DrilledValue<T>`/`ClassificationGroupSummary`/`compareNullableIndexLast`), `lib/widgets/classification_drilldown_capsule.dart`, `lib/widgets/classification_group_card.dart`/`classification_group_grid.dart`, `Weather` enum(`lib/models/enums.dart`), `ClothingItem.createdAt`/`Composition.createdAt`·`weather` 필드.
- 수정: `lib/providers/closet_providers.dart`/`composition_providers.dart`(`selectedSeasonFilterProvider`류 대체), `lib/widgets/category_toggle_dropdown.dart`(`DropdownButton`→`PopupMenuButton`, "설정" 항목), `lib/screens/closet_main_screen.dart`/`composition_main_screen.dart`(캡슐 배선), `lib/widgets/app_main_scaffold.dart`(`groupingBar` 슬롯 삭제), `lib/mock/mock_data.dart`(c12/comp02를 미분류 데모용으로 조정).
- 문서: 이 항목, `2026-07-12-cross-screen-ui-shell-design.md` §2 정정 각주, `04_설정.md` §1 정정 각주.
- 상세 경위(Task별 Worker/Review/Tester 로그, 진행 중 발견된 여러 plan 공백과 수정 내역)는 `docs/superpowers/plans/2026-07-19-classification-drilldown-and-settings-entry.md` 참고.
- Audit(2026-07-19, Task 7 직후)이 P0 없이 통과, P1 2건(BACKLOG.md Current 최신화 필요 — 이 커밋과 함께 반영, `2026-07-12` 스펙도 함께 정정 대상이었음 — 이 항목에서 함께 반영)은 이 문서 작업으로 해소. P2/P3(사소한 매직넘버 패딩, `02_코디 UX명세서` 문구 드리프트, lint 경고 인벤토리 누락 2건)는 `docs/history/TechnicalDebt.md`/`docs/work/BACKLOG.md`에 별도 기록.

---

[Decision] "연결된 스타일일지" 갤러리 — 기본 2열, 1장이면 1열(정사각형 유지, 확대 아님) (UI/Screen, Decision)

결정:
- `StyleLogCrossReferenceGallery`(옷 상세/코디 상세 공용)의 `SliverGridDelegateWithFixedCrossAxisCount.crossAxisCount`를 고정 `2`에서 `logs.length == 1 ? 1 : 2`로 바꾼다.
- `childAspectRatio: 1`(정사각형)은 그대로 유지 — 1열일 때도 타일 비율은 정사각형이며, 다만 열이 1개뿐이라 폭이 컨테이너 전체로 넓어져 타일 자체가 더 커 보이는 효과. 바로 앞 Decision("1개면 2칸 확대" 폐기)이 없앤 2:1 와이드 사각형 배치와는 다른 규칙 — 이번엔 스팬이 아니라 열 개수 자체를 줄이는 방식.

사유:
사용자가 두 화면 모두에서 스타일일지가 1장뿐일 때 2열 그리드의 절반이 비어 보이는 게 어색하다고 판단, 1장이면 1열로 표시해 달라고 직접 지시(2026-07-18).

Impact:
- `lib/widgets/style_log_cross_reference_gallery.dart` — `GridView.builder`의 `crossAxisCount`를 `logs.length` 기준 동적 값으로 변경.
- `lib/screens/closet_item_detail_screen.dart`, `lib/screens/composition_detail_screen.dart` — 변경 없음(공용 위젯만 수정, 두 화면 모두 자동 적용).
- `docs/reference/plan/03_화면별UX명세서/02_코디 (가상 조합).md` 19행 — "연결된 스타일 일지 목록(2열, 정사각형 타일)"을 "연결된 스타일 일지 목록(기본 2열, 1장이면 1열, 정사각형 타일)"로 갱신.
- 관련 통합테스트(`composition_detail_addtile_square_test.dart`, `detail_thumbnail_square_unification_test.dart` 등)가 1장 연결 케이스의 mock 데이터로 그리드 폭을 검증하는지 확인 필요 — Worker 구현 시 점검.

---

[Decision] 코디 상세의 "연결된 스타일일지" 썸네일도 정사각형(1:1)으로 통일 — "1개면 2칸 확대" 스펙 규칙 폐기 (UI/Screen, Decision)

결정:
- `02_코디 (가상 조합).md`가 명시했던 "연결된 스타일 일지 목록(2열, 스타일 일지 1개면 2칸 확대 배치)"의 "1개면 2칸 확대" 규칙을 폐기한다. 코디 상세도 옷 상세와 동일하게 연결된 개수와 무관하게 항상 정사각형(1:1) 타일로 표시한다.
- `StyleLogCrossReferenceGallery`의 `expandSingle` 파라미터(Task 9에서 두 화면의 차이를 표현하려고 도입)는 이제 두 화면 모두 `false`와 동일한 결과를 내므로 **파라미터 자체를 제거**하고 항상 정사각형 그리드 로직만 남긴다(죽은 분기 유지 안 함, YAGNI). 미연결 시 "+" 타일(`_AddTile`)의 비율도 2:1 → 1:1로 함께 맞춘다.
- `02_코디 (가상 조합).md` 문서 텍스트도 "1개면 2칸 확대 배치" 서술을 제거해 실제 구현과 일치시킨다.

사유:
사용자가 실제 화면을 보고 코디 상세의 스타일일지 썸네일 비율을 1:1로 바꿔달라고 직접 지시(2026-07-18). Task 9 당시엔 이 "1개면 확대" 규칙이 승인된 스펙이라 보존했으나, 사용자가 이번에 그 규칙 자체를 변경하기로 결정 — 문서(스펙)보다 최신 사용자 지시가 우선.

Impact:
- `lib/widgets/style_log_cross_reference_gallery.dart` — `expandSingle` 파라미터 제거, 항상 정사각형.
- `lib/screens/closet_item_detail_screen.dart` — 이제 불필요해진 `expandSingle: false` 인자 제거(동작 변화 없음, 이미 그 값이었으므로).
- `lib/screens/composition_detail_screen.dart` — 변경 없음(원래 파라미터를 안 넘기고 있었음, 이제 그 자리의 의미만 바뀜).
- `docs/reference/plan/03_화면별UX명세서/02_코디 (가상 조합).md` 텍스트 갱신.
- `integration_test/detail_thumbnail_square_unification_test.dart`의 "코디 상세는 여전히 2:1" 회귀 assertion을 "코디 상세도 이제 정사각형"으로 갱신 필요.
- `docs/superpowers/plans/2026-07-15-step7-detail-binding.md`에 Task 12로 추가.

---

[Decision] 옷 상세 코디 프리뷰를 `PageView` 캐러셀에서 "착용 옷"과 동일한 연속 스크롤 리스트로 교체 (UI/Screen, Decision — 아래 "옷 상세의 '연결된 코디' 캐러셀 타일을..." 항목의 최종 정정)

결정:
- `CompositionPreviewCarousel`(Task 6에서 신설, Task 9에서 `AspectRatio(1)` 풀블리드 정사각 페이지로 통일)이 채택했던 **"스와이프하면 페이지가 넘어가고 점 인디케이터로 표시하는" `PageView` 방식 자체를 폐기**한다. 대신 `style_log_viewer_screen.dart`의 "착용 옷" 섹션(페이지 개념 없이 그냥 옆으로 미는 연속 스크롤 `ListView.horizontal`, 코디 슬롯 `PageView`와는 완전히 별개 섹션)과 동일한 메커니즘으로 교체한다.
- 타일 콘텐츠는 여전히 "코디" 단위(이미지+이름, `CompositionPreviewCard` 그대로 재사용) — 코디에 포함된 개별 옷을 풀어놓지 않는다. 각 타일 크기는 "착용 옷" 타일과 동일(고정된 작은 정사각형, 화면 폭을 채우는 큰 정사각형 아님).
- 점 인디케이터/`PageController`/`onPageChanged` 상태는 전부 제거 — 페이지 개념이 없으므로 `StatefulWidget`일 필요도 없어져 `StatelessWidget`으로 단순화.

사유:
사용자가 옷 상세 화면을 실제로 보고 여러 차례 정정 — 처음엔 "코디 대표이미지 대신 착용옷처럼 실제 옷들을 캐러셀 타일로"라고 요청했다가(Task 10, 되돌려짐), PM이 "그럼 타일 크기를 스타일일지 캐러셀과 맞추자"고 재해석했으나 이 역시 어긋났음이 확인됐다. 최종적으로 사용자가 가리킨 "가로 캐러셀"은 스타일일지 열람의 코디 슬롯 `PageView`가 아니라 그 화면의 "착용 옷"(연속 스크롤 리스트)이었다 — 즉 옷 상세의 코디 프리뷰도 "여러 코디를 한 화면에 동시에 보여주고 옆으로 미는" 방식이어야 하며, "하나씩 스와이프해서 넘기는" 방식이 아니었다.

Impact:
- `lib/widgets/composition_preview_carousel.dart` — `StatefulWidget`(`PageView`+점 인디케이터) → `StatelessWidget`(`ListView.horizontal`, 고정 타일 크기)로 재작성. 파일/클래스명은 유지(호출부 변경 최소화).
- `lib/screens/closet_item_detail_screen.dart` 호출부는 변경 없음(같은 시그니처: `compositions`/`onTap`).
- `docs/superpowers/plans/2026-07-15-step7-detail-binding.md`에 Task 11로 추가.

---

[Decision] 옷 상세의 "연결된 코디" 캐러셀 타일을 단일 대표이미지에서 "사용된 옷" 가로 스크롤로 교체 (UI/Screen, Decision)

결정:
- 옷 상세(`closet_item_detail_screen.dart`)의 `CompositionPreviewCarousel` 각 타일이 지금까지는 `CompositionPreviewCard`(코디 대표이미지 1장 — `coverImagePath` 없으면 첫 옷 이미지로 폴백 — + 이름)만 보여줬는데, 이를 그 코디에 실제로 포함된 옷 전부를 가로 스크롤 스트립으로 보여주는 방식으로 바꾼다. 이 가로 스크롤 스트립 UI는 이미 `composition_detail_screen.dart`의 "사용된 옷"과 `style_log_viewer_screen.dart`의 "착용 옷"에 거의 동일한 형태로 두 번 존재하므로, 공용 위젯(`ClothingItemsRow`)으로 추출해 세 곳에서 재사용한다.
- 코디 이름은 타일 상단 라벨로 유지. 타일 안에서 **개별 옷 이미지를 탭하면 그 옷의 상세로**, **옷 이미지가 아닌 타일의 나머지 영역(이름 라벨 등)을 탭하면 기존처럼 코디 상세로** 이동한다 — 두 탭 대상이 공존해야 하므로 새 위젯(`CompositionItemsTile`)이 이 분기를 담당한다.
- **알려진 리스크(구현 후 Tester가 반드시 실측 검증)**: 캐러셀(가로 스와이프, 코디 간 이동)과 그 안의 옷 목록(가로 스크롤, 옷 간 이동)이 같은 축(가로)의 중첩 스크롤이라 제스처 경합이 생길 수 있다 — Flutter의 제스처 아레나가 터치 시작 위치 기준으로 대체로 잘 처리하지만, 옷 목록이 타일 전체를 채우면 "코디 간 스와이프"를 시작할 빈 공간이 부족해질 수 있음. 실측 결과에 따라 후속 조정(예: 타일 상단 라벨 영역을 스와이프 전용 구역으로 넉넉히 두기) 검토.
- `CompositionPreviewCard`는 이제 스타일일지 열람의 코디 슬롯(단일 카드) 전용으로 좁혀진다 — docstring 갱신.

사유:
사용자가 옷 상세 화면을 보고 "코디 이미지를 그냥 단일 이미지로 넣지 말고, 스타일일지 열람의 착용 옷 캐러셀처럼 실제 옷들을 캐러셀의 타일 콘텐츠로 넣어달라"고 지시(2026-07-16→17). 단일 대표이미지(코디에 포함된 첫 옷 하나만 임의로 대표하는 방식)보다 실제 구성 옷 전부를 보여주는 편이 정보량이 많고, 이미 두 화면에 있는 패턴을 재사용하면 구현 비용도 낮다고 판단.

Impact:
- 신규 `lib/widgets/clothing_items_row.dart`(`ClothingItemsRow`), `lib/widgets/composition_items_tile.dart`(`CompositionItemsTile`).
- `composition_detail_screen.dart`/`style_log_viewer_screen.dart`의 기존 인라인 가로 스크롤 코드를 `ClothingItemsRow`로 교체(동작 변경 없음, 순수 리팩터).
- `composition_preview_carousel.dart`가 `ConsumerStatefulWidget`로 전환(`closetItemsProvider` watch 필요), `closet_item_detail_screen.dart` 호출부에 `onItemTap` 파라미터 추가.
- `docs/superpowers/plans/2026-07-15-step7-detail-binding.md`에 Task 10으로 추가.

**[정정, 2026-07-18]** 위 결정은 사용자 지시를 잘못 해석한 것으로 확인되어 되돌림(`git revert cc49ad2` + `git revert 5a4c704`). 처음엔 "타일 콘텐츠를 코디 대표이미지에서 옷 목록으로 바꾼 게 문제였고, 크기만 스타일일지 캐러셀과 맞추면 된다"고 판단했으나(이 판단도 부분적으로만 맞음), 대화를 더 거친 끝에 사용자가 가리킨 "가로 캐러셀"이 스타일일지 열람의 **2페이지 `PageView`+점 인디케이터 카드 영역이 아니라, 그 아래의 "착용 옷" 섹션(페이지 넘김 없이 연속 스크롤되는 `ListView.horizontal`)**이었음이 최종 확인됐다 — 상세는 아래 "옷 상세 코디 프리뷰를 PageView 캐러셀에서 착용 옷과 동일한 연속 스크롤 리스트로 교체" 항목 참고.

---

[Decision] 스타일일지 열람 카드 구조를 스펙 원문대로 정정(대표이미지/코디 슬롯 2페이지 캐러셀) + 옷장 상세 정사각형 통일 + `crossReferenceEntries` 폐기 (UI/Screen, Decision — 아래 "Detail 화면 상호참조를..." 항목을 부분 정정)

결정:
- **스타일일지 열람 = 2페이지 스와이프 캐러셀**: `03_스타일 일지.md` 23번 줄 "카드 구조: 대표이미지(1번, 고정) → 코디 슬롯(2번, 고정)"을 문자 그대로 구현한다. Task 7에서 구현했던 "커버 이미지 + 하단에 별도 `CompositionPreviewCard`/칩" 방식은 이 스펙을 어겨 폐기 — **직전 Task 7 작업 중 이 방식으로 진행하라고 한 지시가 있었다면 그 지시는 전부 무효**(사용자 확인, 2026-07-16). 대표이미지(1페이지)와 코디 슬롯(2페이지, 연결됨=`CompositionPreviewCard`/미연결="+" 플레이스홀더)을 하나의 스와이프 가능한 `PageView`(정사각형, 풀블리드, 2개뿐이라도 페이지 인디케이터 점 표시)로 묶는다. 화면 하단에 별도로 코디 이미지/칩이 있으면 안 됨.
- **"추가 사진" 라벨 정정 → "착용 옷"**: `StyleLog.additionalImagePaths`는 실제로는 이 스타일일지에서 착용한 옷들의 이미지다(mock 데이터 확인: `log01.additionalImagePaths`가 `c11`/`c07`의 `imagePath`와 동일값) — Task 7이 "추가 사진"으로 잘못 이름 붙였을 뿐 기능 자체는 이미 있었다. 라벨을 "착용 옷"으로 바꾸고, 각 이미지를 탭하면 `ClothingItem.imagePath` 역참조로 해당 옷을 찾아 옷 상세로 이동하도록 배선한다(모델 필드 추가 없이 기존 데이터로 충분 — 매칭 안 되면 탭 비활성).
- **옷장 상세의 코디 캐러셀/스타일일지 갤러리는 정사각형으로 통일**: `CompositionPreviewCarousel`(옷 상세의 연결된 코디)은 고정 높이(200)+피크 뷰포트(0.82) 대신 `AspectRatio(1)`+풀블리드 페이지로 바꿔 항상 정사각형 카드가 되게 한다(스타일일지 열람의 코디 슬롯과 동일한 시각 언어). `StyleLogCrossReferenceGallery`(옷 상세의 연결된 스타일일지)도 옷 상세에서 쓰일 때는 개수와 무관하게 항상 정사각형(2열 그리드, 1개면 그냥 1칸만 채움)이 되도록 새 파라미터(`expandSingle`, 기본값 `true`)를 추가한다 — **코디 상세**(같은 위젯을 "연결된 스타일일지"에 재사용, `02_코디 UX명세서`의 "2열, 1개면 2칸 확대" 규칙이 이미 승인된 스펙)는 `expandSingle: true`(기존 동작 그대로) 유지, **옷장 상세만** `expandSingle: false`로 호출해 정사각형 강제.
- **`AppDetailScaffold.crossReferenceEntries`/`CrossReferenceLinkBar` 폐기**: 위 스타일일지 열람 재구현이 끝나면 이 파라미터를 실제로 쓰는 화면이 하나도 안 남는다(코디 상세는 이미 `onAddTap`으로 갈아탔고, 옷 상세는 애초에 안 씀) — 죽은 계약을 남겨두지 않고 `AppDetailScaffold`에서 파라미터 자체를 제거하고 `CrossReferenceLinkBar`/`CrossReferenceLinkEntry` 위젯 파일도 삭제한다(TechDebt로 남겨뒀던 "`crossReferenceEntries` 계약이 애매해졌다"는 Audit 지적의 근본 해결).

사유:
Audit(2026-07-16)이 스타일일지 열람의 코디 바인딩 UI가 코디 상세와 다르게 생겼고 스펙의 카드 순서(대표이미지→코디 슬롯→추가사진)와도 어긋난다고 P1로 지적. 사용자가 직접 화면을 보고 "2번째 페이지가 코디 슬롯이어야 하고 하단에 코디 이미지가 따로 있으면 안 된다"고 스펙 원문 근거로 정정 지시, 동시에 "추가 사진"이 사실 "착용 옷"이라는 것과 옷장 상세의 코디/스타일일지 썸네일이 정사각형이어야 한다는 것도 함께 확인.

Impact:
- `docs/superpowers/plans/2026-07-15-step7-detail-binding.md`에 Task 8(스타일일지 열람 카드 캐러셀 재구현)/Task 9(옷장 상세 정사각형 통일 + crossReferenceEntries 폐기) 추가.
- `docs/history/TechnicalDebt.md`의 "`CrossReferenceLinkBar` 계약 애매해짐"/"`composition_preview_carousel.dart` 매직넘버"(고정 height/viewportFraction 상수 자체가 이번에 사라짐) 항목 갱신.

---

[Decision] Detail 화면 상호참조를 텍스트 칩 → 썸네일 캐러셀/갤러리로 확장, `Composition.coverImagePath` 필드 신설, 코디 아이템 개수 상한 15개 (UI/Screen, Decision)

결정:
- **상호참조 표시 방식 확정**: 옷 상세/코디 상세의 "연결된 코디"/"연결된 스타일일지" 영역을 기존 `CrossReferenceLinkBar`(하단 텍스트+아이콘 pill 칩)에서, 이미지가 보이는 body 내 섹션으로 바꾼다.
  - 옷 상세: 연결된 코디 → 이미지 캐러셀(여러 개면 스와이프), 그 아래 연결된 스타일일지 → 2열 갤러리(1개면 1열로 확대). 둘 다 읽기 전용(바인딩 액션 없음), 리스트가 비면 그 섹션 자체를 숨긴다.
  - 코디 상세: 연결된 스타일일지 → 옷 상세와 동일한 2열/1열 갤러리. 단, 미연결(0개) 상태에서는 갤러리 자리에 "+" 추가 타일 하나가 대신 뜨고(기존 "스타일일지 연결하기" 바인딩 동작 유지, `_bindStyleLog` 그대로), 1개 이상이면 + 타일은 사라지고 실제 항목만 그리드로 보인다(`02_코디 UX명세서`가 이미 이 조건부 배치를 명시하고 있었음 — `CrossReferenceLinkBar`는 그 자리에 들어간 축약판이었을 뿐).
  - 스타일일지 열람의 "연결된 코디"(단일, `linkedCompositionId`)도 일관성을 위해 캐러셀의 카드 콘텐츠(이미지+이름)와 동일한 시각 언어로 렌더링한다 — 다만 최대 1개뿐이라 페이징 캐러셀은 불필요, 카드 하나만 그대로 쓴다. 미연결 시의 "+코디 연결하기" 바인딩 동작(`_bindComposition`)은 변경 없음.
  - `CrossReferenceLinkBar`/`CrossReferenceLinkEntry` 자체는 폐기하지 않는다 — 이번 변경의 대상이 아닌 다른 "+연결" 단일 액션 자리에서 계속 쓸 수 있는 범용 컴포넌트로 유지.
- **`Composition.coverImagePath` 필드 신설**: `String?`, 기본 `null`.가치 로직(사용자가 대표 이미지를 고르는 Editor UI)은 이번 라운드에 포함하지 않는다 — `isIncomplete`와 동일한 "필드만 먼저" 패턴. `null`일 때의 표시 이미지는 코디에 포함된 첫 번째 옷의 `ClothingItem.imagePath`로 폴백한다(파생 provider로 해결, Record에 값을 쓰지 않음). 코디 메인 그리드의 `CompositionGalleryTile`(현재 텍스트 전용)은 이번 라운드에 함께 갱신하지 않는다 — 이 작업으로 해소 가능해졌다는 사실만 TechnicalDebt에 기록하고 착수는 별도 판단.
- **코디 아이템 개수 상한 15개로 확정**: `Composition`은 옷장 전체가 아니라 1:1 아트보드 위의 단일 코디 표현이라, 상의/하의/아우터/신발/가방/모자/스카프/벨트/액세서리 등을 헤비 레이어드룩까지 감안해도 15개면 충분하다고 판단(30개는 아트보드 겹침 터치 선택 UX에 부담). 값 자체는 이번 커밋에서 코드에 반영하지 않음 — 실제 상한 검증 로직은 코디 만들기(Editor) 화면 구현 시점에 적용 대상.

사유:
사용자가 옷 상세 화면에서 연결된 코디/스타일일지가 텍스트만 있는 걸 보고 "썸네일 이미지 추가"를 요청(2026-07-16). PM이 `Composition`에 이미지 필드 자체가 없다는 걸 확인해 표시 이미지 소스를 사용자에게 확인받음 — "필드는 지금 추가하되 로직(선택 UI)은 나중" 옵션을 선택. 코디 상세의 "연결된 스타일일지 2열/1열 갤러리"는 실은 `02_코디 UX명세서`(Step① 이전부터 존재)가 이미 명시했던 내용이라, `CrossReferenceLinkBar`가 그 자리를 임시로 대신하고 있었을 뿐임이 드러났다.

Impact:
- `docs/superpowers/plans/2026-07-15-step7-detail-binding.md`에 Task 6(모델 필드+파생 provider)/Task 7(캐러셀/갤러리 위젯+옷 상세·코디 상세 재배선) 추가, Task 5의 스타일일지 열람 코드도 카드 콘텐츠 공유 위젯을 쓰도록 소폭 수정.
- `docs/history/TechnicalDebt.md`에 "`CompositionGalleryTile` 텍스트 전용" 항목 갱신(coverImagePath 필드 생겨 착수 비용이 낮아짐), 코디 개수 상한 15 값은 Editor 구현 시 반영 필요 항목으로 별도 등록.
- `docs/work/BACKLOG.md` Current 갱신.

**정정(2차 Audit, 2026-07-16)**: 위 Impact의 "Task 6/Task 7" 번호는 이 결정을 작성하던 시점의 초안 번호다 — 실제 최종 Plan 번호는 **Task 5**(모델 필드+파생 provider)/**Task 6**(캐러셀/갤러리 위젯+재배선)이며, Task 7은 이후 삽입된 "원래 Task 5"(스타일일지 열람 바인딩)가 밀린 번호다. `docs/work/BACKLOG.md`/`docs/history/TechnicalDebt.md`는 전부 최종 번호를 쓰고 있음 — 이 항목만 예외였다.

---

[Decision] Editor 저장 모델 전환 — Record Real-time Save + Editor Draft/Commit/Cancel (Data/Architecture, Editor Draft 구현은 Step⑦ 이후 별도 후속 작업으로 분리)

결정:
- 기존 "상시 저장(드래프트 없음)" 정책을 **Record(실 데이터)와 Editor 세션(편집 버퍼)의 분리**로 대체한다:
  1. **일반 정보(Real-time Save, 기존과 동일)**: Detail 화면에서 이뤄지는 일반 필드 수정(옷 태그/계절/위치/메모, 코디 제목/계절, 스타일 일지 메모/연결 코디 등)은 지금처럼 즉시 실제 Record에 저장. 별도 저장 버튼/사용자 관리 Draft 없음 — 이 부분은 변경 없음.
  2. **Editor Draft(신규)**: 옷 추가(배경제거/크롭/마스킹), 코디 만들기(아트보드 배치/이동/회전/크기) 등 전용 Editor 화면의 편집은 더 이상 Record를 직접 수정하지 않는다. Editor 진입 시 해당 Record에 연결된 Editor Draft를 생성(또는 기존 미커밋 Draft가 있으면 재사용)하고, 이후 모든 변경은 Draft에만 실시간 자동저장.
  3. **Commit/Cancel**: 우상단 완료(✔)는 Draft → Record 반영(Commit) 후 Draft 삭제. 취소(✕)/뒤로가기는 Draft를 폐기(Record는 Editor 진입 이전 상태 그대로 유지) — 진짜 의미의 편집 취소(Rollback)가 됨.
  4. **"미완성" 배지 판정 기준 변경**: 기존엔 "필드 미입력"이 판정 대상이었으나, 앞으로는 **해당 Record에 연결된 미커밋 Editor Draft가 존재하는가**만이 기준이다(제목/태그/계절/메모 미입력은 더 이상 미완성 사유 아님). `ClothingItem.isIncomplete`/(신설 예정) `Composition.isIncomplete`/`StyleLog.isIncomplete` 저장 필드 자체는 유지 — 값을 채우는 로직만 이 기준으로 재정의.
- **작업 분리**: BACKLOG "Flutter Hi-Fi 화면" 스프린트의 Step⑦(기능 구현)은 이 Editor Draft/Commit/Cancel 메커니즘을 포함하지 않는다. Editor 3화면(옷 추가/코디 만들기/스타일일지 추가)의 실제 저장 로직 배선은 Step⑦ 완료 후 **별도 후속 작업("Editor Draft 구현")**으로 진행한다(사용자 제안 원문의 "Phase 1.5"에 해당 — `00_MVP.md`가 이미 쓰고 있는 프로젝트 로드맵 Phase 1/1.5/2/3 번호 체계와 이름이 겹쳐 혼동을 피하려고 문서에는 별도 명칭으로 기록). Gallery "미완성" 배지 UI 및 "이어서 편집" 진입 UX는 그다음 후속 작업으로, Draft 버전 관리/다중 Draft/Editor 공통화는 더 뒤로 유지(사용자 원 제안 Phase 2/Phase 3에 각각 대응).
- **Recovery 범위 축소**: 앱 강제종료 후 복원(사용자 원 제안 §5)은 "Editor Draft 구현" 후속 작업의 필수 목표에서 제외한다 — 현재 프로젝트에 영속 계층 자체가 없어(모든 Record가 인메모리 Riverpod 상태) Draft만 강제종료 후 살아남게 만드는 건 의미가 약함. 대신 **인터페이스는 나중에 로컬/Firestore 영속화 어댑터로 교체 가능하게 준비**해둔다(아래 Draft 구조 참고) — 이번엔 실제 로컬 저장 패키지(Hive 등)는 추가하지 않음. 세션 내 복원(에디터 재진입 시 기존 Draft 로드)은 Riverpod 상태만으로 자동 충족되므로 별도 구현 불필요.
- **Draft 데이터 구조**: 기존 Record notifier(`closetItemsProvider` 등)에 필드를 얹지 않고, 도메인별 독립 `draftsProvider`(`ClothingItemDraft`/`CompositionDraft`/`StyleLogDraft`, `Map<recordId, Draft>` 형태)를 신설한다 — Draft는 조회 패턴(갤러리 목록/필터 대상 아님, 휘발성, 단일 소유자)이 Record와 근본적으로 달라 분리가 맞고, 향후 Firestore에서도 별도 컬렉션(`editor_drafts`, `{recordType, recordId}` 키)으로 갈 것이므로 지금부터 그 경계를 맞춘다.

사유:
사용자가 "Policy Revision Proposal — Editor Draft Strategy & Save Model"로 직접 제안(2026-07-15). 기존 "상시 저장(드래프트 없음)" 정책이 Record와 편집 세션을 동일시해 실제 편집 취소(Rollback)가 불가능했던 구조적 한계를 해결하기 위함. PM 조사 결과 Editor 3화면이 아직 전부 skeleton 상태(Step①/⑤ 산출물만 존재, 실제 저장 로직 없음)라 마이그레이션 비용 없이 지금 방향을 바꾸는 게 가장 저렴하다고 판단, 세부 설계(Recovery 범위/Draft 구조/작업 분리 시점)를 PM이 정리해 사용자에게 확인받음.

Impact:
- `docs/reference/plan/03_화면별UX명세서/_공통 규칙.md` "상시 저장(드래프트 없음)" 섹션 리라이트(이 커밋에서 함께 처리).
- `docs/history/TechnicalDebt.md`의 "Composition/StyleLog isIncomplete 필드 부재" 항목 — 필드 신설 자체는 이 결정과 별개로 이미 확정(저장 필드, ClothingItem과 동일 패턴), 값 설정/해제 로직만 이 Draft 기준으로 갱신 필요하다고 함께 업데이트.
- `docs/work/BACKLOG.md` Current 섹션 — Step⑦ 스코프에서 Editor 3화면 저장 로직 배선 제외 명시, "Editor Draft 구현"을 Step⑦ 이후 후속 작업으로 별도 등록.
- 코드 영향은 전부 "Editor Draft 구현" 착수 시점 Implementation 태스크(신규 `lib/providers/*_drafts_provider.dart` 3종, `EditorHeader.onCancel`/`AutoSaveIndicator` 배선, Editor 3화면 실제 로직)로 예정 — 이번 라운드(Step⑦ 착수 전)는 모델 필드/문서만 정리.

---

[Decision] Typography Pass 3 확정 (Type Scale) + Brand Guide §3 코드 동기화

결정:
- **Brand Guide 동기화**: `docs/reference/design/01_BrandGuid.md` §3 "Font Families"가 "Body: KoPub돋움"을 확정으로 표시하고 있었으나, 실제로는 옷장 메인 재설계 때(위 "옷장 메인 재설계 — Design Tokens 확정" 결정) Body도 Pretendard로 단일화되고 KoPubDotum이 코드/`pubspec.yaml`에서 제거된 상태였다 — Decision.md엔 남아있었지만 Brand Guide 문서 자체가 갱신되지 않아 living document 원칙을 어기고 있었다. Header/HUD Stack 재설계 후 재개한 Visual Review에서 발견, 사용자 확인 하에 Brand Guide를 코드에 맞춰 "전 역할 Pretendard"로 수정.
- **Type Scale 확정**: 그동안 잠정값(Material 3 기본 스케일)으로 미확정 표시돼 있던 사이즈/굵기를 정식 확정값으로 승격. 사용자가 실제 3개 메인 화면(옷장/코디/스타일일지) 스크린샷을 보고 다음 2가지 조정을 지시:
  1. 갤러리 타일 배지/태그 텍스트(`labelSmall`, 원피스/하의 등 카테고리 태그·"미완성" 배지) — 11 → **13**으로 확대.
  2. "선택" 보조 액션 버튼 텍스트가 **앱 전체에서 가장 작은 텍스트**가 되도록 — 기존 `labelSmall`(11)이 비운 값을 재사용해 신규 역할 `actionMinimal`(**11**, M3 표준 15-role 밖의 추가 역할)을 도입, "선택" 버튼에 명시 적용. 나머지 역할(`display*`/`headline*`/`title*`/`body*`/`labelLarge`/`labelMedium`)은 기존 M3 기본값 그대로 확정.
- 확정값 전체 표는 `01_BrandGuid.md` §3에 기록(이 문서에 중복 전사하지 않음 — Reference 문서가 Source of Truth).

사유:
BACKLOG.md "다음 세션 작업" 1번(Header/HUD Stack 재설계 후 Main 3화면 스크린샷 재캡처 → Visual Review 재개, 보류 중이던 Typography Pass 3 포함)에 따라 재개한 Visual Review 중 사용자 직접 지시.

Impact:
- `docs/reference/design/01_BrandGuid.md` §3/§4 갱신 완료(이 세션에서 직접 수정).
- 코드 반영은 별도 Implementation 태스크: `lib/theme/app_typography.dart`(`labelSmall` 11→13, `actionMinimal` 11 신설)과 옷장/코디/스타일일지 메인 3개 화면의 "선택" `TextButton`(`lib/screens/closet_main_screen.dart`, `composition_main_screen.dart`, `style_log_main_screen.dart`)에 `actionMinimal` 명시 적용 필요 — Worker→Review→Tester 사이클로 진행 예정.
- `labelSmall`을 참조하는 다른 위젯(`status_badge.dart`, `selectable_gallery_tile.dart`, `style_log_gallery_tile.dart`, `composition_gallery_tile.dart`)은 role 참조만 하고 있어 자동으로 커진 값이 반영됨(별도 수정 불필요).

---

[Decision] Header/HUD Pinned Rule — 모든 조작 요소는 독립된 Floating Control, 단일 Toolbar/Capsule Bar/NavigationBar/SegmentedContainer로 병합 금지 (Layout Principle, 변경 시 사용자 승인 필수)

결정:
- 헤더/HUD의 조작 요소(카테고리 드롭다운, 계절 드롭다운, 밀도 버튼, 선택 버튼, ⋯더보기, 검색 등)는 **각각 물리적으로 독립된 컨테이너**(개별 프로스티드글래스 pill/circle)여야 한다. 시각적 스타일(블러/보더/그림자 톤)은 공유할 수 있지만, 하나의 Container/Row 안에 여러 요소를 함께 담아 하나의 Bar처럼 렌더링하는 것은 **프로젝트 전체에서 금지**한다.
- 이 결정 당시(2026-07-13) `lib/widgets/overlay_header.dart`(`OverlayHeader`)가 정확히 이 금지된 패턴이었다 — 배경/블러/보더/그림자를 가진 단일 `Container`가 `child`(드롭다운+타이틀)와 `actions`(선택 버튼 등)를 한 Row에 모두 담고 있었다. `AppMainScaffold`가 모든 Main 화면에서 이 `OverlayHeader`를 공용으로 쓰고 있어, 화면 단위로 개별 수정해도 셸 자체가 이 패턴이면 계속 재발하는 구조였다 — 이번 결정은 **셸 컴포넌트 자체의 재설계**를 요구했다(화면별 땜질 금지). **(주: `OverlayHeader`는 같은 날 Header/HUD Stack 재설계 작업으로 삭제됐다 — 이 문단은 그 시점의 문제 상황을 기록한 것이지 현재 코드 상태가 아니다.)**
- **Layer 분류**(`uiux-design-conventions` Layer Boundary Rule 기준): 이 규칙은 "헤더가 어떻게 배치되는가"를 정의하므로 **Layout Principle**에 속한다(Golden Question: UI가 어떻게 배치되는지 정의하는가? → YES → Layout).
- **변경 절차 고정**: 이 규칙과 다른 형태(요소를 하나의 컨테이너로 합치는 등)를 제안하려면, 먼저 "기존 Pinned Rule을 변경하는 제안"임을 명시하고 사용자 승인을 받은 뒤에만 반영한다 — Worker/PM이 임의로 되돌릴 수 없다.
- 이 규칙과 별개로, 사용자가 제공한 "옷장 메인 하이파이 디자인 주문서"(2026-07-13)의 세부 레이아웃(2번째 툴바 행, 계절 세그먼트, 원형 자리표시 버튼, 삭제 바, 토스트 등)은 `docs/reference/plan/03_화면별UX명세서/01_옷장.md`와 대조해 반영 — 세부 사항은 별도 Implementation 태스크에서 처리.
- **후속 확정(같은 날)**: 이 Pinned Rule과 Scroll Edge Gradient 문제(아래 TechDebt, 이후 이 항목과 통합)를 PM이 종합해 "헤더가 Column으로 콘텐츠를 도킹시키는 구조 자체가 근본 원인"이라고 진단했고, 사용자가 이를 확인하며 정식 스펙 원문(Scroll Container + Header/HUD 아키텍처)을 전달 — `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`에 그대로 기록. 이 Decision 항목의 상세 구현 지침은 이제 그 스펙 문서가 Source of Truth이며, 여기서는 "규칙이 언제/왜 생겼는지"만 남긴다.

사유:
사용자가 여러 차례 "독립된 Floating Control" 형태로 수정 요청했음에도 Bar 형태로 반복 회귀 — 근본 원인이 화면별 구현이 아니라 공용 셸 컴포넌트(`OverlayHeader`) 자체의 설계였음을 이번에 확인. 재발 방지를 위해 Pinned Rule로 명문화하고 변경 절차를 고정.

Impact:
- 상세 구현 지침·Impact 평가는 `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`로 이관(중복 방지) — `lib/widgets/app_main_scaffold.dart`/`overlay_header.dart`/`fading_scroll_edge.dart` 재설계, 옷장/코디/스타일일지 메인 3화면 전부 영향.
- 상세 구현은 별도 Implementation 태스크로 진행.

---

[Decision] 갤러리 그리드는 화면 가로폭 끝까지 사용(edge-to-edge) — HUD Scrollbar는 향후 Stack 기반 overlay로만 구현, Grid padding/inset 확장으로 자리 확보 금지

결정:
- `AppGalleryGrid`(`lib/widgets/app_gallery_grid.dart`)는 좌우 padding 없이 화면 가로폭을 끝까지 채운다. 수직 padding(상/하 여백)은 유지 가능하며, 타일 간 간격은 기존 `AppSpacing.galleryGap`(crossAxisSpacing/mainAxisSpacing)로 그대로 유지한다.
- 아직 미착수 상태인 HUD Scrollbar(`docs/work/BACKLOG.md` 파킹로트 항목 — "Scrollbar / Scroll Hint(`<`/`>`)")는 향후 구현 시 반드시 **Stack 기반 overlay**로 그리드 위에 얹는 방식으로 만든다. Grid의 padding이나 top inset을 늘려 스크롤바 자리를 미리 확보하는 방식은 금지 — 스크롤바 유무가 갤러리 콘텐츠의 레이아웃(타일 크기/위치)에 영향을 줘서는 안 된다.

사유:
사용자 지시(2026-07-13, Step③ 완료 후 대표 3화면 Visual Review 착수 중 발견).

Impact:
- `lib/widgets/app_gallery_grid.dart` 좌우 padding 제거 필요 — 소규모 Implementation 태스크로 진행.
- 이후 Scrollbar를 Component Library에 추가할 때(BACKLOG 파킹로트) 이 규칙(Stack overlay, Grid 비침습)을 따를 것.

---

[Decision] 그리드 밀도(`AppDensity`) 토글은 그룹형 Main 화면(옷장/코디) 전용 — 스타일일지 메인은 밀도 토글 없이 고정 밀도 사용

결정:
- `AppDensity`(`lib/theme/app_spacing.dart`)의 3단계 밀도 토글 UI는 옷장/코디 메인에만 적용한다. 스타일일지 메인(`style_log_main_screen.dart`)은 밀도 토글 아이콘/provider 없이 `StyleLogGalleryGrid` 내부에서 `AppDensity.mid`를 고정값으로 사용한다.
- 근거: `AppDensity` 클래스 자체의 기존 주석("T6(Density) — Grouped Main 그리드(옷장/코디) 전용 열 개수")이 이미 이 범위를 명시하고 있었고, `03_스타일 일지.md` UX명세서도 밀도 토글을 요구하지 않는다(플랫+필터형이라는 페이지 타입 확정과는 별개 개념).

사유:
Step③(코디/스타일일지 메인 적용, 2026-07-13) Worker가 이 기존 주석 근거로 스타일일지에 밀도 provider를 추가하지 않았고, Review·Audit이 코드-스펙 일치를 확인했다. 다만 이 판단이 코드 주석에만 있고 Decision.md에는 없어 Audit이 "다음 Worker/Reviewer가 오인할 위험"을 지적 — 그 근거로 이번에 정식 기록한다(코드 변경 없음, 문서화만).

Impact:
- 코드 변경 없음(이미 Step③ 커밋에 반영된 상태를 사후 문서화).
- 이후 Step⑥(휴지통 등 나머지 화면 적용) 때도 같은 기준(그룹형 여부로 밀도 토글 유무 판단)을 따를 것.

---

[Decision] Step②(Component Library) 1차 라운드 제작 범위 확정 + `AppMainScaffold` 내부 슬롯 구조 지시

결정:
- 이번 라운드(Task 2-A, 2026-07-13 완료) 제작 대상을 8개로 확정: Layout `AppMainScaffold`(Task 2-B로 이월), Header 계열 `FrostedBackButton`/`CategoryToggleDropdown`/`EditorHeader`/`AutoSaveIndicator`/`DetailHeaderActions`, Detail `CrossReferenceLinkBar`, Primitive `FadingScrollEdge`. Task 2-A에서 실제로 만든 건 `AppMainScaffold`를 뺀 7개 + Gallery 레이아웃 분리(`AppGalleryGrid`).
- **`AppMainScaffold` 내부 구조 지시(Task 2-B가 따라야 할 구속 조건)**: Scaffold는 레이아웃 조립만 담당하고, `Header`는 `Leading`/`Title`/`Actions(slot)`로 나뉘며 `Actions` 슬롯에 `DetailHeaderActions`(드롭다운+⋯메뉴, 재사용 가능한 별도 composite)가 꽂히는 구조로 만든다. 화면마다 Header를 따로 구현하거나 Detail 전용 별도 Scaffold를 새로 만드는 방향은 명시적으로 금지 — Detail은 Main과 동일한 셸에서 `groupingBar` 슬롯만 비우는 방식으로 처리한다.
- **Gallery 제네릭화는 이번 라운드에 전체로 하지 않음**: Grid 레이아웃(`AppGalleryGrid`)만 공용 컴포넌트로 분리하고, Tile(`SelectableGalleryTile`)은 Clothing 전용 구현을 유지 — Composition/Style Log/Trash로의 확장은 Step③ 몫으로 이월.
- **Scrollbar/Scroll Hint(`<`/`>`)는 이번 라운드에 제작하지 않고 향후 Component Library 확장 후보로만 유지**(프로젝트 전반 공통 디자인 예정).
- Component Hierarchy 참고 모델(사용자 제시, 향후 라운드에도 적용): `Primitive(Button/Scrollbar/Badge/Divider/FadeEdge) → Composite(GalleryTile/DetailHeaderActions/CrossReferenceLinkBar) → Layout(AppMainScaffold/EditorScaffold) → Screen`. 이번 라운드는 이 중 Primitive 일부 + Composite + Header 계열까지만 해당, Layout(`AppMainScaffold`/`EditorScaffold`)은 Task 2-B 이후.

사유:
Step①(전체 화면 Skeleton) 완료 후 PM이 스켈레톤을 훑어 후보를 리스트업했고, 사용자가 검수하며 범위를 확정 — 특히 Detail 헤더를 별도 Scaffold로 분기하지 않고 기존 `AppMainScaffold`의 슬롯 구조 안에서 흡수하도록 명시적으로 지시(불필요한 셸 중복 방지).

Impact:
- Task 2-A 산출물: `lib/widgets/{frosted_back_button,category_toggle_dropdown,detail_header_actions,editor_header,auto_save_indicator,cross_reference_link_bar,fading_scroll_edge,app_gallery_grid}.dart`, `grouped_gallery_grid.dart` 리팩터, `closet_main_screen.dart` 마이그레이션. 커밋 `56eb828`.
- `CrossReferenceLinkBar.height=64` 로컬 const는 `TechnicalDebt.md`에 등록(추후 `AppSpacing` 승격 검토).
- 다음 착수 대상: Task 2-B(`AppMainScaffold` 조립, 위 구속 조건 그대로 적용) — 상세: `docs/work/BACKLOG.md` Current.

---

[Decision] 화면 관통 공용 UI 셸 아키텍처로 전환, Task 8~15(화면별 순차 구현) 폐기 → 8단계 프로세스로 대체

결정:
- 뒤로가기 버튼/카테고리 토글/그룹형 드릴다운을 화면마다 개별 구현하던 기존 계획(플랜 Task 8~15)을 폐기하고, 공용 셸 위젯 `AppMainScaffold`(신설 예정)가 이 세 가지를 소유하는 구조로 전환 — 화면이 이 셸을 쓰기만 하면 뒤로가기/토글/그룹바를 빠뜨릴 수 없음(B안 채택). `FrostedBackButton`/`CategoryToggleDropdown`을 기존 코드에서 추출해 셸 하위 컴포넌트로 재사용, `groupingBar` 슬롯을 그룹형 드릴다운용으로 신설. Add/Create 3화면(옷 추가/코디 만들기/스타일일지 추가)은 이 셸을 쓰지 않고 자체 취소/저장 헤더 유지.
- 화면별 규칙 표(스펙 §1) 확정 — 그룹형 드릴다운은 옷장 메인/코디 메인 두 곳만 적용(스타일일지는 플랫+필터 유지). 선택 모달은 원 화면과 동일 사양으로 원 화면을 재사용(신규 화면 없음).
- 개발 프로세스를 화면별 Task 8~15에서 8단계로 재편: ①전체 화면 Skeleton → ②Component Library 구축 → ③Main 3개 적용 → ④Detail 적용 → ⑤Editor 적용 → ⑥나머지 적용 → ⑦기능 구현 → ⑧디테일 튜닝.
- 산출물: `docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md`(정식 스펙). `docs/work/전체화면_아키텍처_재설계_체크리스트.md`는 은퇴(append-only 보존, 내용은 스펙으로 이관).

사유:
옷장 메인 뒤로가기 버튼을 개별 구현하던 중 사용자가 "뒤로가기/카테고리 토글/그룹형 드릴다운은 화면 하나씩이 아니라 앱을 관통하는 공용 UI여야 한다"고 지적 — 화면별 순차 구현 방식이 이 전제를 반영하지 못해 같은 로직이 반복 구현·검증될 위험이 있었음.

Impact:
- 플랜 `docs/superpowers/plans/2026-07-08-flutter-frontend-hifi-screens.md`의 Task 8~15는 더 이상 유효하지 않음(Task 1~7은 유효).
- Step①(전체 화면 Skeleton)은 별도 플랜(`docs/superpowers/plans/2026-07-13-cross-screen-skeleton-step1.md`)으로 작성, 2026-07-13 Task A~F 전부 완료(상세: `feature/flutter-hifi-screens` 브랜치 커밋 `4778316`~`5ad6561`).
- 다음 착수 대상은 Step②(Component Library 구축).

---

[Decision] Worktree는 저장소 바깥 형제 디렉토리로만 생성 — `.claude/worktrees/`(기본 위치)는 검색 중복의 원인으로 확인돼 신규 생성 금지

결정:
- 별도 세션이 병렬로 쓸 worktree는 항상 `git worktree add ../Digital-Wardrobe-<목적> <branch>` 형태로 **저장소 바깥**에 만든다. `EnterWorktree` 툴의 기본 동작(`.claude/worktrees/` 안에 생성)은 이 프로젝트에서 쓰지 않는다.
- `Workflow_Project.md` §15 "Worktree Placement" 신설(v2.5→v2.6), `CLAUDE.md` 하네스 섹션에도 짧은 포인터 추가.
- 원인 조사 중 확인된 사실: 이 환경의 Grep/Glob 도구가 `.gitignore`를 전혀 참조하지 않음(검증: 명백히 gitignore 대상인 `.dart_tool/`도 Glob에 147개 파일이 그대로 매칭됨). `.claude/worktrees`가 `.gitignore`에 등록돼 있어도 소용없고, `.ignore`/`.rgignore` 같은 대체 ignore 파일도 같은 이유로 효과가 없을 것으로 판단(도구 자체가 ignore 파일을 안 읽으므로) — 그래서 물리적으로 저장소 트리 밖에 두는 것만이 구조적으로 확실한 해법.
- 부수: 고아 worktree 디렉토리 2개(`.claude/worktrees/policy-audit-fix`, `setting-ui-temp`) 발견·삭제. `setting-ui-temp`는 이미 2026-07-12에 "해소됨"으로 기록됐던 `policy-doc-versioning-audit` 메타데이터를 가리키는 죽은 `.git` 포인터를 갖고 있었음 — 즉 그 정리 이후로도 계속 남아 검색을 중복시키고 있었던 것으로 추정. `git worktree remove` 대신 `rm -rf`로 지워졌던 게 원인으로 보임(정상 명령을 안 쓰면 메타데이터만 pruned되고 디렉토리는 안 지워질 수 있음).

사유:
사용자가 "문서 재구조화를 다른 세션/worktree로 진행하면 이 세션 탐색 범위가 2배로 늘지 않냐"고 질문 → 실측 결과 실제로 이미 벌어지고 있던 문제였음이 드러남.

Impact:
- `.claude/policies/Workflow_Project.md`, `CLAUDE.md` 수정.
- 향후 모든 worktree 생성(문서 재구조화 세션 포함)이 이 규칙을 따라야 함.
- `.dart_tool`/`build` 등 다른 gitignore 대상도 평소 검색에 걸리고 있다는 부수 발견 — 이번 스코프에서 별도 조치는 안 함(필요시 후속 검토).

---

[Decision] 컬러 팔레트를 `ColorPalette` 데이터 클래스로 구조화, Palette 1/2 등록(비활성)

결정:
- `lib/theme/app_colors.dart`에 `ColorPalette` 데이터 클래스 신설(`name`/`gray50`/`gray100`/`primary300`/`primary500`/`accent`/`text` 6필드 + name). `bg`는 두 팔레트 모두 `gray50`과 동일해 별도 필드 없이 `gray50` 재사용.
- 팔레트 3개 등록: `ColorPalette.current`(기존 Brand Guide Pass 2 고정값을 그대로 옮긴 것), `ColorPalette.palette1`, `ColorPalette.palette2`(사용자가 이번에 준 팔레트 2종).
- `const ColorPalette activePalette = ColorPalette.current;` 한 줄로 전체 라이트 테마 팔레트를 전환할 수 있는 구조를 만듦. **이번 결정으로 색이 바뀐 것은 아니다** — `activePalette`가 여전히 `current`를 가리키므로 화면에 보이는 색은 리팩터 전과 동일.
- `AppColors.light`(ColorScheme)와 `AppSemanticColors.light`를 `activePalette` 기반 파생값으로 변경. `static const` → `static ... get`으로 바뀔 수밖에 없었음(런타임 평가가 필요해 `const` 유지 불가).
- `AppSemanticColors`에 신규 필드 `primaryLight`(← `activePalette.primary300`), `accent`(← `activePalette.accent`) 추가. 이에 따라 생성자가 두 필드를 `required`로 요구하게 되어, 값이 하드코딩된 `AppSemanticColors.dark`에도 값을 채워야 했음 — `dark`의 기존 `primary`/`secondary` 값을 그대로 재사용(`primaryLight: 0xFF93B5CC`, `accent: 0xFF8FA890`), dark의 다른 기존 필드 값은 전혀 건드리지 않음.
- `gray200`~`gray900`, `warning`, `success`, `AppColors.dark`, `AppSemanticColors.dark`의 기존 색상 값은 팔레트에 없는 role이거나 다크모드 데이터가 없어 손대지 않고 그대로 유지(특히 `gray200`은 갤러리 타일 배경으로 쓰이는 값이라 명시적으로 보존).

사유:
사용자가 컬러 팔레트를 코드 한 곳만 바꾸면 전체 테마가 바뀌도록 구조화해달라고 요청, 동시에 팔레트 후보 2종(Palette 1/2)을 등록해달라고 요청.

Impact:
- `lib/theme/app_colors.dart`만 수정, `lib/theme/app_theme.dart`는 이미 getter로 접근하고 있어 코드 변경 불필요.
- `activePalette`를 `palette1`/`palette2`로 바꾸면 별도 코드 변경 없이 라이트 테마 전체 색이 전환됨(다크 테마는 영향 없음 — 별도 구조).
- Palette 1/2는 현재 미사용(등록만 됨) — 실제 적용은 별도 Task에서 사용자 확정 후 진행.

---

[Decision] 옷장 메인 그리드 밀도 컬럼 수 1/3/5 → 1/2/4 변경 — 기존 "옷장 메인 재설계 — Design Tokens 확정" 결정 중 `AppDensity` 값 부분을 대체

결정:
- `lib/theme/app_spacing.dart`의 `AppDensity`: `mid=3`→`mid=2`, `max=5`→`max=4`로 변경(`min=1`은 유지). `levels = [min, mid, max]` 리스트 정의 자체는 변경 없음(값만 `[1, 2, 4]`로 바뀜).
- `lib/providers/closet_providers.dart`의 `closetDensityProvider` 기본값이 리터럴 `3`으로 하드코딩되어 있던 것을 `AppDensity.mid` 참조로 교체(전수 확인 중 발견 — 값 변경 시 새 밀도 집합 `{1,2,4}`에 속하지 않는 죽은 리터럴이 될 위험이 있었음).
- 순환 방향(내림차순, max→mid→min)은 그대로 유지 — 4→2→1→4로 순환.
- 이 결정은 아래 "옷장 메인 재설계 — Design Tokens 확정" 결정 중 `AppDensity`가 `min=1/mid=3/max=5`로 확정됐던 부분을 대체(supersede)한다. append-only 원칙에 따라 해당 항목 자체는 삭제·수정하지 않고 그대로 둔다(순환 방향 결정은 이번 변경 대상이 아니므로 그대로 유효).

사유:
사용자가 옷장 메인 그리드 밀도 컬럼 수를 1/3/5에서 1/2/4로 확정(사용자 직접 결정).

Impact:
- `lib/theme/app_spacing.dart`, `lib/providers/closet_providers.dart`
- `lib/screens/closet_main_screen.dart`는 `AppDensity.max`/`.mid`/`.min` 상수 참조만 쓰고 있어 코드 변경 불필요.
- `integration_test/closet_main_screen_test.dart`의 밀도 순환 관련 assertion 3건(기존 "3→1→5→3" 전제)이 실패 — Tester가 별도로 갱신 예정.

---

[Decision] 옷장 메인 재설계 — Design Tokens 확정(타이포/코너반경/모션/글래스 헤더/밀도 토글 방향)

결정:
- `lib/theme/app_typography.dart`: Body 계열(`bodyLarge`/`bodyMedium`/`bodySmall`)에 쓰던 `KoPubDotum`을 제거하고 `Pretendard`로 단일화(굵기는 기존 `FontWeight.w500` 유지). 코드 내 유일한 사용처였으므로 `pubspec.yaml`의 `KoPubDotum` `fonts:` 등록도 함께 제거.
- `lib/theme/app_spacing.dart`: `AppRadius`(`sm=16`, `pill=100`) 신설 — Design Tokens에 역할명조차 없던 코너 반경 값을 옷장 메인 목업 기준으로 처음 정의. `AppMotion`(`fast=200ms`, `searchExpand=300ms`) 신설 — Design Tokens의 `Motion.standard` 역할명에 값을 처음 채택, 다른 화면 재사용 전제.
- `lib/widgets/overlay_header.dart`: 글래스 헤더 배경 투명도를 `alpha: 0.7` → `alpha: 0.38`로 수정(목업 값 `rgba(247,246,243,0.38)`과 일치), 얇은 화이트 보더(`alpha 0.2`)와 약한 `BoxShadow`(`alpha 0.05`, `blurRadius 8`, `offset(0,2)`) 추가.
- `lib/screens/closet_main_screen.dart`: 그리드 밀도 토글 순환 방향을 오름차순(3→5→1→3)에서 목업 요구사항인 내림차순(5→3→1→5)으로 반전. 토글 아이콘도 밀도 단계별로 분기(5=`grid_view`, 3=`view_comfy`, 1=`crop_square`)해 시각적으로 구분되게 함.

사유:
Task 7(옷장 메인) 구현이 실제 목업과 어긋난 부분을 재설계하는 플랜(`옷장 메인 화면 재설계` 플랜 §2, Design Tokens 확정 Task) 진행 중, 목업 대조 결과 위 값들이 잠정값·오차·미정 상태였음을 확인해 이번 Task에서 확정.

Impact:
- `lib/theme/app_typography.dart`, `lib/theme/app_spacing.dart`, `lib/widgets/overlay_header.dart`, `lib/screens/closet_main_screen.dart`, `pubspec.yaml`
- `AppRadius`는 Brand Guide/Design Tokens 문서에 아직 정식 등재 안 됨 — `docs/history/TechnicalDebt.md`에 후속 조치 후보로 기록.
- 밀도 토글 방향 반전으로 `integration_test/closet_main_screen_test.dart`의 기존 순환 방향(3→5→1) 전제 assertion 3건이 실패 — Tester가 별도로 갱신 예정.

---

[Decision] Season enum 4종 → 3종 개편 (사계절 폐기, 간절기→봄가을 리네임) — 기존 "ClothingItem.category / Season(ClothingItem·Composition) 폐쇄형 어휘 확정" 결정 중 Season 부분을 대체

결정:
- `lib/models/enums.dart`의 `Season` enum을 `summer, winter, transitional, allSeason` 4종에서 `springFall, summer, winter` 3종으로 변경.
  - `allSeason`(사계절)은 폐기(제거) — 별도 계절값으로 존치하지 않음.
  - `transitional`(간절기)은 `springFall`(봄가을)로 리네임 — 개념은 유지하되 라벨과 식별자만 변경.
  - 선언 순서를 `springFall → summer → winter`로 고정(정렬 기본순서 표와 일치).
- 기존 `Season.allSeason`/`Season.transitional`로 태깅되어 있던 목업 아이템(`lib/mock/mock_data.dart`) 전부를 `Season.springFall`로 재태깅.
- `docs/reference/plan/03_화면별UX명세서/_공통 규칙.md`의 정렬 기본순서 표("계절" 행)를 "여름 → 겨울 → 간절기 → 사계절"에서 "봄가을 → 여름 → 겨울"로 갱신.
- 이 결정은 아래(§) "ClothingItem.category / Season(ClothingItem·Composition) 폐쇄형 어휘 확정" 결정 중 `Season` 4종("여름 / 겨울 / 간절기 / 사계절") 확정 부분을 대체(supersede)한다. append-only 원칙에 따라 그 항목 자체는 삭제·수정하지 않고 그대로 둔다.

사유:
옷장 메인 화면 재설계 작업 중 사용자가 실제 목업 데이터 모델을 화면과 대조하며 검토한 결과, "사계절"이라는 계절 구분이 실사용 맥락에서 불필요하고(모든 계절에 다 입는 옷은 "간절기" 또는 개별 계절로도 충분히 표현 가능), "간절기"라는 명칭보다 "봄가을"이 사용자에게 더 직관적이라고 직접 확정.

Impact:
- `lib/models/enums.dart`: `Season` enum 3종으로 축소, 선언 순서 변경
- `lib/mock/mock_data.dart`: 기존 `Season.allSeason`/`Season.transitional` 태깅 아이템·구성(Composition) 전부 `Season.springFall`로 재태깅
- `docs/reference/plan/03_화면별UX명세서/_공통 규칙.md`: 정렬 기본순서 표 갱신
- `test/`, `integration_test/`의 `Season.allSeason`/`transitional` 참조 갱신

---

[Decision] Design 워크플로우-Development 파이프라인 교차 트리거 신설 (Visual Review 누락 방지)

결정:
- `Workflow_Design.md` §2.1 "Cross-Workflow Trigger" 신설: 대표 Hi-Fi Sample(3~5개 화면)이 Development 파이프라인(Layer=UI/Screen, Stage=Implementation/Frontend)으로 만들어지는 경우, Development Review/Tester 통과가 Visual Review(타이포/색상/여백/시각적 위계 확인)를 대체하지 않는다. 대표 샘플이 Development 트랙에서 완성되면 PM이 Visual Review를 명시적으로 트리거해야 하고, 그 전까지 Design Tokens는 잠정값(freeze 안 됨)으로 취급한다. Version 2.1 → 2.2.
- `CLAUDE.md` 필수 체크포인트에 6번 "Design 마일스톤 교차 확인" 추가.

사유:
Task 7(옷장 메인 화면, 대표 Hi-Fi Sample의 첫 화면)이 `Layer=UI/Screen, Stage=Implementation(Frontend)`로 태깅되어 Worker→Review→Tester 사이클만 타고 완료 처리됐는데, 이 사이클 어디에도 Visual Review(타이포/색상/여백 등 "눈으로 봐야 아는 것")를 체크하는 지점이 없었음. `BACKLOG.md`의 "Next" 항목에 Typography가 "임시값 — 실제 화면 육안 확인 후 재검토 필요"라고 이미 적혀 있었는데도 PM이 명시적 체크포인트 없이 지나침. 사용자가 "리뷰 과정에 비주얼 리뷰 했어?"라고 물어 발견, Design/Development 두 워크플로우가 서로의 완료 조건을 모르는 구조적 공백으로 진단하고 즉시 정책 보완 지시.

Impact:
- `Workflow_Design.md` §2.1 신설, Version 2.2
- `CLAUDE.md` 체크포인트 6 추가
- Task 7의 실제 Visual Review는 아직 미실시 — 별도로 진행 예정

---

[Decision] feature 브랜치의 dev 동기화 주기 신설 (Task/Plan 완료 시점마다 pull)

결정:
- `Workflow_Project.md` §13.4 "Sync Cadence (feature ← dev)" 신설: Task 하나가 완료될 때(Worker→Review→Tester 사이클이 Complete에 도달)와, 여러 Task로 구성된 Plan 전체가 끝날 때, 각각 `git fetch origin && git merge origin/dev`로 feature 브랜치에 dev를 받아들인다.
- 이 merge 실행 자체는 feature 브랜치 안의 안전한 작업이라 사전 확인 불필요(§13.2 커밋 게이트와 동일 근거). 충돌이 나면 PM이 직접 해결(맥락을 아는 쪽이 처리)하고, 결과 diff를 사용자에게 보여준 뒤 확인받는다 — 결정문서/정책 문서가 충돌에 걸리면 특히.
- `CLAUDE.md` 필수 체크포인트에 5번으로 추가.

사유:
Tester 하네스 확장 작업 중, `feature/flutter-hifi-screens` 브랜치가 dev를 오래 안 당겨받은 사이 dev에 병합된 별도 PR(#6, 정책/레퍼런스 문서 폴더구조 개편 — `docs/knowledge/**` → `.claude/policies/`+`docs/history/`+`docs/reference/`)과 크게 갈라져, 실제로 4개 파일(`CLAUDE.md`, `Workflow_Project.md`, `Decision.md`, `BACKLOG.md`)에서 병합 충돌이 발생함(2026-07-10). 사용자가 이 사고를 계기로 "Task 완료 혹은 Plan 완료 시점마다 pull"을 명시적 프로세스로 만들 것을 지시 — 갈라짐을 작은 상태로 자주 해소해 충돌 규모를 최소화하는 것이 목적.

Impact:
- `Workflow_Project.md` §13.4 신설
- `CLAUDE.md` 체크포인트 5 추가
- 이번 사고 자체의 충돌 해결(4개 파일)은 PM이 직접 수행, 사용자가 최종 확인

---

[Decision] Audit 발견 사항 반영 — §1.7 문서 계층/오버라이드 원칙 신설 + §7/§12.1 모순 해소 + Role 중복 정리

결정:
- **§7 vs §12.1 모순 해소**: `workflow_project/12_Role Information Access.md` §12.1의 "Layer×Stage 태깅이 §7 Impact Scope 평가 도중 일어난다"는 문장을 수정 — 태깅(항상, 가벼움)과 §7의 정식 Change Impact 평가(L/XL만, 무거움)를 별개 개념으로 명확히 분리. §10/§11의 "항상 평가" 문구는 그대로 유지(그게 맞는 방향).
- **§1.7 "Document Hierarchy & Override" 신설** (`workflow_project/01_Core Principles.md`): `Workflow_Project.md`=부모(기본 규칙), `Workflow_Development.md`/`Workflow_Design.md`=자식(도메인별 override/elaboration), `Workflow_Frontend.md`=Development·Design 양쪽에서 파생되는 Flutter/Dart 구현 특화 문서. 자식이 특정 주제를 다루면 그 도메인에서 자식이 우선, 자식이 침묵하면 부모 규칙이 기본값. **단, "침묵 = 부모 따름"을 암묵적으로 기대하지 않고, 그 경우엔 반드시 명시적 포인터를 남기도록 못박음** — Task Manifest(§12.4)가 도메인 문서만 좁게 넘길 수 있어 진짜 침묵과 의도적 위임을 구분할 방법이 없기 때문.
- **Feature Audit 중복 해소**: `workflow_development/04_Roles.md`의 Feature Audit 섹션(Project 쪽과 체크리스트가 미묘하게 갈라져 있던 유일한 항목 — 개발 맥락 특화 내용이 실질적으로 없었음)을 `Workflow_Project.md` §2로 가리키는 명시적 포인터로 교체. PM/Worker/Review/Tester/Integrator는 Development 쪽에 실제 도메인 특화 내용(Review Areas 세부, Development/Product-UX Review 서브타입, Integrator "기본은 사람" 정책 등)이 있어 그대로 유지 — §1.7의 "자식이 elaborate하면 자식이 우선" 사례.
- **Role 체크리스트 문구 통일** (임시 조치, 위 포인터 전환으로 최종 해소): Feature Audit을 포인터로 바꾸기 전, 두 문서의 체크리스트가 다르게 갈라져 있던 걸("Design System consistency" vs "Requirements compliance") 먼저 통일했었음 — 최종적으로는 포인터 전환으로 중복 자체가 사라짐.
- **문구 정리**: `Workflow_Development.md` 헤더의 "Claude Projects" 표기를 "Claude Code"로 정정(Claude Projects는 이미 폐기됨). §2.1 Handoff 표의 "Tester 통과 시 handoff 없이 task completes" 문구가 M 사이즈에만 해당됨을 명시(L/XL은 Integrator로 진행).
- **BACKLOG.md stale 문구 정정**: "하드코딩 원칙이 정책 문서 상 명문화 안 됨, 재반영 미결"이라던 주의 문구를 "engineering-principles 스킬로 이미 재문서화 완료"로 갱신.
- **Version 범프**: `Workflow_Project.md` 2.2 → 2.3 (§1.7 신설, chapter-level), `Workflow_Development.md` 1.2 → 1.3 (여러 챕터급 수정, 한 리비전 패스 1회 bump).

사유:
사용자가 정책 문서 전반에 대한 Audit을 요청, 다음 항목들이 발견됨: (1) §7/§10/§11/§12.1의 Change Impact 평가 범위 모순 [P0], (2) `Workflow_Project.md`/`Workflow_Design.md`의 라우터+앵커 구조 전환 자체가 Decision.md에 기록되지 않음 [P1, 별도 항목으로 보완 — 바로 아래], (5) Role 정의가 Project/Development 두 곳에 있고 Feature Audit 체크리스트가 실제로 갈라져 있었음 [P2], (6)(7) 사소한 문구 오류 [P3], (8) BACKLOG.md stale 문구 [부수 발견]. (5)를 검토하는 과정에서 사용자가 애초에 "Project=기본, Development/Design=상세 override"라는 의도로 설계했었다고 확인 — 다만 그 의도가 문서 어디에도 명문화돼 있지 않아 우연한 드리프트(Feature Audit)를 막지 못했음. §1.7로 그 의도 자체를 성문화.

Impact:
- `workflow_project/01_Core Principles.md` §1.7 신설
- `workflow_project/12_Role Information Access.md` §12.1 문구 수정
- `workflow_development/04_Roles.md` Feature Audit → 포인터, 헤더 문구, Handoff 표 문구 수정
- `workflow_project/02_Roles.md` Feature Audit 체크리스트 일시 수정(포인터 전환으로 최종적으로는 Development 쪽만 영향, Project 쪽 "Requirements compliance" 추가는 유지 — 어차피 맞는 내용)
- `Workflow_Project.md` Version 2.2→2.3, `Workflow_Development.md` Version 1.2→1.3
- `docs/work/BACKLOG.md` stale 문구 정정

---

[Decision] `Workflow_Project.md`/`Workflow_Design.md`를 모놀리식 문서에서 라우터+앵커 구조로 전면 개편 (Version 2.0 major bump) — 사후 기록 (Audit 발견, 기록 누락 보완)

결정:
- 프로젝트 오너가 `Workflow_Project.md`, `Workflow_Design.md`를 각 섹션 헤딩 + `→ 경로` 포인터만 남기는 "라우터" 문서로, 20줄 이상 섹션 본문은 `workflow_project/`, `workflow_design/` 하위 개별 파일로 분리하는 구조로 직접 재작성함.
- 이 구조 변경 자체는 §1.6 기준 "문서 사용 패턴·전체 프레임워크 변경"에 해당해 두 문서 모두 Version 2.0(major)로 이미 반영됨 — 다만 그 판단 근거를 기록하는 Decision.md 항목이 누락돼 있었음(Audit에서 발견, 이 항목으로 사후 보완).
- 재정리 과정에서 발생한 회귀(계절 정렬값 오염, 깨진/누락 앵커 경로, `Workflow_Project.md` §7~§11 헤딩/본문 밀림 및 중복, 고아 파일)는 별도 세션에서 전수 점검 후 수정 — 관련 세부는 PR #6/#8 이력 및 이 파일 상단 근처 다른 항목들 참고.

사유:
Audit이 "문서 정책(Decision.md 기록 의무) 위반 — 구조 변경 자체를 기록한 항목이 없다"고 지적. `Workflow_Development.md` §5 Decision.md Policy("Workflow changes, Reference document policy changes는 기록 대상")에 해당하는 변경인데 실제로는 그 이후의 개별 수정(Frontend.md 재정의, Task Manifest 등)만 기록되고 최초 구조 개편 자체는 기록되지 않았음.

Impact:
- 기록 자체만 보완, 문서 내용 변경 없음

---

[Decision] `documentation-conventions`/`uiux-design-conventions` 스킬 실채택 — 보류됐던 TechDebt 해소

결정:
- 파일럿(`Digital-Wardrobe-testbed/localTestbed`, 이후 삭제됨 — 내용은 이전 파일럿 세션에서 이미 검증·기록됨)에서 시험만 되고 채택 보류 상태였던 두 스킬을 실제 채택.
- `documentation-conventions`: `Workflow_Project.md` §1.4(Living Documents)/§1.5(Concise Writing)를 원문 그대로 이전. `workflow_project/01_Core Principles.md`의 해당 두 섹션 본문을 포인터로 교체(헤더 번호 유지).
- `uiux-design-conventions`: `Workflow_Design.md`의 Layer Boundary Rule(`workflow_design/01_core principles.md`)과 Design Review/Visual Review 체크리스트(`workflow_design/06_design review.md`) 본문을 이전, 각각 포인터로 교체. 브랜드 값/원칙 텍스트는 복사하지 않고 `01_BrandGuid.md` 참조만 남김(제2의 Source of Truth 방지 원칙 유지).
- `Workflow_Project.md` §12.1 표에 두 스킬 등재: `uiux-design-conventions`는 UI/Screen×Decision(Design) 행, `documentation-conventions`는 3개 Decision-stage 행(UI/Screen, Logic/Feature, Data/API/Architecture) 전부 — Decision-stage 작업이 Reference 문서 신규/갱신 내용을 만들어내는 지점이라는 근거.
- Version 범프: `Workflow_Project.md` 2.1 → 2.2, `Workflow_Design.md` 2.0 → 2.1 (둘 다 챕터 단위 수정, §1.6 기준 minor).

사유:
`engineering-principles`/`flutter-implementation-conventions` 채택 이후 dev에 반영된 앵커 구조 정리 작업이 안정화됐고, 이 TechDebt 항목이 "채택 여부/타이밍 재검토 필요"로 남아있어 재검토한 결과 채택하지 않을 이유가 없다고 판단.

Impact:
- `.claude/skills/documentation-conventions/SKILL.md`, `.claude/skills/uiux-design-conventions/SKILL.md` 신설
- `workflow_project/01_Core Principles.md`, `workflow_design/01_core principles.md`, `workflow_design/06_design review.md` 본문 축소, 포인터 추가
- `Workflow_Project.md` §12.1 갱신, Version 2.1→2.2
- `Workflow_Design.md` Version 2.0→2.1
- `TechnicalDebt.md` 해당 항목 해결 처리

---

[Decision] BACKLOG.md 커밋 승인을 포맷 수정 vs. 진행 기록 수정으로 차등화

결정:
- `CLAUDE.md` "진행 중 작업 상태" 항목에 추가: BACKLOG.md의 **포맷(섹션 구조·배치) 수정**은 기존과 동일하게 일반 Edit 승인 흐름을 거친다. 반면 Current/Last Completed 등에 방금 끝난 작업을 반영하는 **진행 기록용 내용 수정**은 별도 확인 없이, 함께 진행 중인 작업 변경사항의 커밋에 묶어 커밋한다.

사유:
Tester 하네스 확장 작업 커밋 전, PM이 결정문서류 전체(Decision.md/BACKLOG.md 포함)를 습관적으로 커밋 전 확인받으려 했는데, 사용자가 BACKLOG.md의 일상적 진행 기록 갱신까지 매번 확인받는 건 과하다고 판단 — "작업 자체의 일부"로 이미 승격된 BACKLOG.md 갱신(§3 "Skill-Internal Ledgers vs. Official Handoff", 위 관련 Decision 참고)의 취지를 커밋 단계까지 일관되게 적용한 것. 단, 섹션 구조를 바꾸는 포맷 수정은 문서의 향후 가독성/일관성에 영향을 주므로 계속 확인 대상으로 남김.

Impact:
- `CLAUDE.md` "진행 중 작업 상태" 항목 갱신
- 향후 BACKLOG.md 내용(진행 기록) 수정은 관련 작업 커밋에 자동 포함, 포맷 변경만 별도 확인

---

[Decision] 하네스에 Tester 역할 신설 — Worker→Review→Tester→Worker 사이클로 확장

결정:
- 기존 PM/Worker/Review 3역할 구조에 **Tester**를 추가. Review는 정적 코드 리뷰(품질/구조/테스트 코드 존재 여부)만 하고 앱을 실제로 구동하지 않는다는 공백이 있었음 — Tester가 그 공백(런타임 동작 검증)을 담당.
- **실행 메커니즘**: Flutter `integration_test` 패키지. 위젯 트리를 코드로 직접 구동(`tester.tap`/`pump`)해 실제 Riverpod 상태·네비게이션·데이터 흐름을 검증. 이 환경엔 브라우저/GUI 자동화 도구가 없어 이게 유일하게 현실적인 수단.
- **파이프라인 위치**: `Worker → Review → Tester → Worker(수정) → Complete` (M/L/XL). S(단일 수정)는 기본 생략하되, 런타임 동작을 바꾸면 예외적으로 포함.
- **트리거 기준**: Task 크기 무관, 런타임 동작이 있는 모든 작업(`/verify` 스킬의 기존 스킵 규칙과 동일 원칙).
- **테스트 스크립트 소유권**: Tester가 시나리오를 직접 설계하고 `integration_test/`에 작성·커밋(Worker가 자기 구현의 검증 시나리오까지 짜면 셀프리뷰 사각지대 발생). `lib/`는 절대 건드리지 않음 — Tester의 Write 권한은 `integration_test/`로만 제한.
- Tester의 Do: 동작 결과 검사, 비정형 흐름 포함, 연결 기능 회귀 확인, 정의된 모든 상태(성공/로딩/빈상태/오류/재시도/취소 — 실제 구현된 것만) 확인, 화면 간 데이터 일관성, 이탈 후 데이터 유지(현재는 mock 데이터 단계라 in-memory 상태 범위로 한정, 실제 백엔드 영속성/네트워크 중복은 Firebase 연동 후 재적용), Reference 문서/정책 준수. Don't: 구현·리팩토링 제안·코드 스타일 평가 안함, 실제 사용자 시나리오만, Pass/Fail 보고 + 재현 절차 필수.

사유:
사용자가 "지금부터는 테스터가 있어야할 것 같다"며 구체적인 Do/Don't 스펙을 제시. 브레인스토밍으로 실행 메커니즘·파이프라인 위치·트리거 기준·스크립트 소유권 네 가지를 확정(각각 옵션 비교 후 사용자가 선택).

Impact:
- `.claude/agents/tester.md` 신설
- `Workflow_Development.md` §2.1/§2.2(handoff 표·템플릿), §4(Review의 Testing 항목 재정의 + Tester 역할 섹션) 갱신
- `Workflow_Project.md` §2(Roles), §5(Standard Pipeline), §10(Definition of Done), §12.1(Layer×Stage 자료 매핑) 갱신
- `CLAUDE.md` 하네스 운영 원칙 갱신(Tester 언급, Write 범위 제약, 사이클 명칭 변경)
- **환경 셋업 이슈 발견 → 해소**: `integration_test` 실행 검증이 처음엔 Windows desktop 빌드용 Visual Studio "Desktop development with C++" 워크로드 부재로 막혔음(웹 타깃은 `flutter test`가 integration test 미지원). 사용자가 VS C++ 워크로드 설치 완료 → `flutter test integration_test/app_smoke_test.dart -d windows` 실제 실행해 "All tests passed!" 확인, `39a2958` 커밋으로 확정. Android 툴체인은 별도로 계속 설치 진행 중(이 프로젝트가 `android/`/`ios/` 폴더를 가진 실제 모바일 타깃 프로젝트라 필요하지만, 이번 Tester 셋업 자체는 Windows desktop 경로만으로 완결됨 — Android는 향후 추가 디바이스 타깃 옵션).

---

[Decision] Task Manifest 신설 — Required Materials를 Read/Edit/Write 태깅된 구체 목록으로 변환

결정:
- `Workflow_Project.md` §11 Core Operating Principles 항목 11("PM must convert Required Materials into an explicit Task Manifest before spawning a Worker")이 그동안 근거 문서 없는 선언으로만 존재하던 것을, `workflow_project/12_Role Information Access.md`에 신설한 §12.4 "Task Manifest"로 실제 정의함.
- §12.1의 Required Materials는 추상적 카테고리("Plan reference docs" 등)일 뿐이고, PM이 Worker/Review를 스폰하기 직전에 이를 구체적 파일 경로 + 접근모드로 변환한 것이 Task Manifest. 접근모드 3종: **Read**(참고 자료, 수정 금지) / **Edit**(기존 파일 수정) / **Write**(신규 파일 생성). `Skill:` 항목은 항상 Read.
- `worker.md`/`review.md`에 이 태깅 규약을 지키라는 문장 추가(Worker: 도구 권한이 허용해도 Read 태그 파일은 건드리지 않음 / Review: 전부 Read, Edit/Write 계층 없음).
- `Workflow_Project.md` Version 2.0 → 2.1 (§12.4 신설은 chapter-level addition, §1.6 기준 minor bump).

사유:
"PM이 워커에게 일감·자료를 줄 때 Read/Edit/Write 권한이 따로 명시돼 있지 않다"는 지적에서 시작. 확인 결과 Task Manifest 항목 자체가 프로젝트 어디에도 실제로 연결/정의돼 있지 않은 선언뿐이었음 — 이번에 §12.4로 그 실체를 채움.

Impact:
- `workflow_project/12_Role Information Access.md` §12.4 신설
- `Workflow_Project.md` §11 항목 11에 "(see §12.4)" 참조 추가, Version 2.0 → 2.1
- `.claude/agents/worker.md`, `.claude/agents/review.md` 갱신

---

[Decision] `Workflow_Frontend.md`를 Frontend Implementation 단계의 §12.1 앵커(스킬 인덱스) 문서로 재정의 — 이전 minor bump 판단을 major로 정정

결정:
- `Workflow_Frontend.md`의 역할을 "프론트엔드 구현 원칙 문서"에서 "`Workflow_Project.md` §12.1의 UI/Screen×Implementation(Frontend) 행이 가리키는 단일 안정 앵커 문서 — 이 단계에 적용되는 Frontend 스킬 목록을 관리하는 인덱스"로 재정의. §1에 이 역할을 명시적으로 서술하는 문장 추가(기존 스킬 호출 pointer 문장은 그대로 유지).
- `Workflow_Project.md` §12.1 "UI/Screen | Implementation (Frontend)" 행에서 `**Skill: engineering-principles**`/`**Skill: flutter-implementation-conventions**` 개별 항목 제거 — `Workflow_Frontend.md`가 이미 그 두 스킬을 가리키므로 중복. 나머지 두 행(Logic/Feature Implementation, Data/API/Architecture Implementation)은 자기 몫의 앵커 문서가 아직 없어 `engineering-principles` 명시 참조를 그대로 유지.
- `Workflow_Frontend.md` Version 1.1 → 2.0 (MAJOR) — 문서의 근본 사용 패턴이 "재사용 가능한 원칙을 담는 문서"에서 "스킬 인덱스/라우팅 문서"로 바뀜, §1.6 기준 "usage pattern·framework/structure 변경"에 해당. 같은 브랜치 안에서 앞서 내려진 "Version 1.0 → 1.1 minor bump" 판단(아래 "Reference 문서 버전 넘버링 규칙 신설" 항목의 Impact)을 대체(supersede)함 — 그 판단 시점엔 §2~§6 원칙 본문을 스킬로 옮기고 pointer로 교체하는 것만 반영했고, 문서 자체의 역할이 "원칙 문서 → 인덱스 문서"로 바뀌는 것까지는 포함하지 않았음.

사유:
§12.1의 목적은 PM이 Layer×Stage별로 워커에게 필요한 최소 자료만 건네는 것. Frontend Implementation 행에 `Workflow_Frontend.md`와 그 문서가 이미 가리키는 두 스킬을 모두 나열하는 건 중복이었음 — `Workflow_Frontend.md` §1이 이미 "이 두 스킬을 호출하라"고 말하고 있으므로. 프로젝트 오너가 이 문서를 "Frontend 관련 스킬이 늘어나거나 더 세분화(예: 네비게이션/상태관리/테스트가 각각 별도 스킬로 쪼개짐)돼도 §12.1 표 셀은 절대 커지지 않고, 이 문서 하나만 계속 가리키면 되는" 안정적 앵커로 명시적으로 재정의하기로 함.

Impact:
- `Workflow_Frontend.md` §1 재작성(앵커/인덱스 역할 명시), Version 1.1 → 2.0
- `Workflow_Project.md` §12.1 UI/Screen·Implementation(Frontend) 행에서 스킬 2건 명시 참조 제거 (Version bump 없음 — 같은 리비전 패스 내 1.0→1.1 bump로 이미 커버됨, §1.6 "one revision pass = one bump")
- 아래 "Reference 문서 버전 넘버링 규칙 신설" Decision 항목의 `Workflow_Frontend.md` minor-bump 판단을 대체(supersede) — 그 항목 자체는 append-only 정책에 따라 소급 수정하지 않고 그대로 두되, 최신 판단은 이 항목을 따름.
- (감사 발견 반영) 같은 패스에서 `Workflow_Development.md`도 §4 Worker 섹션에 스킬 pointer 문장 추가로 Version 1.0 → 1.1(chapter-level modification) — 아래 "Reference 문서 버전 넘버링 규칙 신설" Decision의 Impact 목록에 최초 누락됐던 것을 여기 보완 기록.

---

[Decision] Reference 문서 버전 넘버링 규칙 신설 (§1.6)

결정:
- `Workflow_Project.md` §1.6 "Version Numbering" 신설: `> Version X.Y` 헤더를 가진 Reference 문서는 챕터 단위 추가/수정 시 점 뒤 숫자(minor)를, 문서의 사용 패턴·전체 프레임워크/구조 변경 시 점 앞 숫자(major)를 올린다. 한 리비전 패스는 그 안에 여러 챕터 단위 변경이 있어도 한 번만 bump한다.
- 이 패스에서 신설과 동시에 규칙을 자기 자신에게 적용 — `Workflow_Project.md`를 Version 1.0 → 1.1로 bump(신규 §1.6 추가 + §12.1 테이블 수정, 둘 다 챕터 단위 변경이지만 한 패스이므로 1회 bump).

사유:
Reference 문서 여러 개가 `> Version X.Y` 헤더를 갖고 있었으나 언제 major/minor를 올릴지 기준이 없어 매번 임의로 판단해야 했음. 프로젝트 오너가 시맨틱 버저닝과 유사한 규칙(챕터 단위 변경=minor, 프레임워크/사용 패턴 변경=major)을 명시적으로 제시해 성문화.

Impact:
- `Workflow_Project.md` §1.6 신설, Version 1.0 → 1.1
- 같은 패스에서 `Workflow_Frontend.md`도 이 규칙에 따라 Version 1.0 → 1.1 (챕터 단위 내용 교체는 수정이지 프레임워크 변경이 아니므로 minor bump)

---

[Decision] 재사용 가능한 원칙을 Workflow 문서에서 Claude Code Skill로 분리 채택 (engineering-principles, flutter-implementation-conventions)

결정:
- Workflow_*.md 정책 문서에 있던 재사용 가능한 원칙 콘텐츠를 `.claude/skills/<name>/SKILL.md` 형태의 Claude Code Skill로 분리하는 방식을 채택. Workflow 문서에는 흐름/역할/파이프라인만 남기고, 원칙 본문은 스킬이 갖고 스킬을 명시적 bare pointer 문장으로 호출하는 구조로 전환.
- 이번 패스에서 실제로 분리한 스킬 2개: `engineering-principles`(최초 신설명 `hardcoding-prevention`, 이후 리네임 — `Workflow_Development.md` §4 Worker 섹션에서 pointer), `flutter-implementation-conventions`(`Workflow_Frontend.md` §2~§6 원칙 본문을 추출).
- 같은 파일럿에서 함께 시험됐던 `documentation-conventions`, `uiux-design-conventions` 스킬은 이번 패스에서 채택하지 않음 — 아직 파일럿 초안 상태로 보류(`TechnicalDebt.md`에 후속 후보로 기록).

사유:
별도 worktree(`Digital-Wardrobe-testbed/localTestbed`, 브랜치 `feature/skill-extraction-testbed`)에서 PM/Worker/Review 팀으로 진행한 파일럿이 가설("원칙이 Workflow 문서에 인라인으로 쌓이면 텍스트량 때문에 오히려 안 지켜진다, 스킬로 분리하면 완화된다")을 검증함(`localTestbed/REPORT.md`). Verbatim 전사 요구사항(하드코딩 원칙 등)이 스킬 포맷 자체로 인한 드리프트 없이 지켜졌고, 유일한 리뷰 지적(P1: pointer 문장이 원칙을 재서술해 "제2의 Source of Truth" 실패 패턴을 재현)은 Worker 실행 실수였을 뿐 구조적 결함이 아니었으며 Review→Worker 1회전에서 자체 교정됨. `uiux-design-conventions` 스킬 초안은 verbatim 전사가 아닌 "방법론 추출"에도 이 포맷이 통한다는 것도 보였음(이번 패스에서는 미채택).

Impact:
- `.claude/skills/engineering-principles/SKILL.md` 신설(최초 신설명 `hardcoding-prevention`, 같은 패스 내에서 프로젝트 오너 요청으로 `engineering-principles`로 리네임 — 내용/스코프 변경 없음) — 원칙 원문은 파일럿 초안이 아니라 2026-07-09 최종 확정본("코드에 별도로 정의된 사전 합의된 const, enum, design token 등") 사용. 이 코드베이스에서 이미 확인된 위반 필드(`ClothingItem.category`/`season`/`material`, `Composition.season`) 참고용 메모 포함(조치는 별도 Step 3).
- `.claude/skills/flutter-implementation-conventions/SKILL.md` 신설 — `Workflow_Frontend.md` §2(네비게이션)~§6(Review 체크리스트) 원칙/AI Constraints 전량 이전.
- `Workflow_Development.md` §4 Worker 섹션에 engineering-principles bare pointer 추가.
- `Workflow_Frontend.md` §2~§6 본문을 스킬 pointer로 교체(헤더/번호는 유지). §1은 목적/스코프 내용은 그대로 유지하되 `engineering-principles`·`flutter-implementation-conventions` 두 스킬을 가리키는 pointer 문장이 새로 추가됨(§1 자체가 무수정으로 남은 것은 아님). §7은 무수정 유지. Version 1.0 → 1.1.
- `Workflow_Project.md` §12.1 Required Materials 컬럼에 두 스킬 등재(`engineering-principles`는 UI/Screen·Logic/Feature·Data/API/Architecture Implementation 행, `flutter-implementation-conventions`는 UI/Screen Implementation 행만), Version 1.0 → 1.1.
- `documentation-conventions`/`uiux-design-conventions` 채택은 보류 — `TechnicalDebt.md`에 후속 후보 task로 기록.

---

[Decision] ClothingItem.category / Season(ClothingItem·Composition) 폐쇄형 어휘 확정 — enum화 대상

결정:
- `ClothingItem.category` 8종(착용순서 정렬): 모자 / 상의 / 아우터 / 하의 / 원피스 / 양말 / 신발 / 가방·액세서리. `03_화면별UX명세서.md` §옷 종류의 예시 순서(모자→상의→아우터→하의→양말→신발→가방/액세서리 "등")를 근거로 하되, 그 목록이 "등"으로 비어있던 원피스를 현재 mock 데이터 실사용값 기준으로 추가해 확정.
- `ClothingItem.season` / `Composition.season` 4종: 여름 / 겨울 / 간절기 / 사계절. **`03_화면별UX명세서.md` §계절 정렬 기준("봄→여름→가을→겨울")과 다른 체계로, 이번 결정으로 대체함** — 봄/가을을 별도 계절로 구분하지 않고 "간절기"로 통합. 기존 mock 데이터의 '봄'/'가을' 값은 모두 '간절기'로 재매핑.
- 두 필드 모두 `docs/work/BACKLOG.md`에 기록된 하드코딩 원칙(위 항목 참고)에 따라 bare `String`이 아닌 실제 Dart `enum` 타입으로 구현(Step 3).

사유:
Step 2(하드코딩 원칙 문서화) 완료 후 Step 3(실제 enum화 구현) 착수 전, 폐쇄형 어휘 자체가 한 번도 명문화된 적이 없어(`category`는 예시 순서만, `season`은 이미 커밋된 테스트가 기획 문서와 다른 '사계절' 값을 사실상 확정값처럼 쓰고 있었음) PM이 사용자에게 직접 확인. 계절 체계는 사용자가 실제 옷장 태깅 관점에서 봄/가을 구분이 실익이 적다고 판단해 "간절기"로 통합하는 실용적 4종 체계를 선택.

Impact:
- `docs/work/BACKLOG.md` Step 3 항목에 확정값 기록
- `03_화면별UX명세서.md` §계절 정렬 기준 수정(사용지 직접)
- 실제 코드 구현(`lib/models/`, `lib/mock/mock_data.dart`, `lib/providers/`, 관련 테스트)은 이 결정 직후 별도 Worker 작업으로 진행

---

[Decision] BACKLOG.md 갱신을 "태스크 완료 시 후속조치"에서 "각 스텝 완료의 일부"로 승격

결정:
- `Workflow_Project.md` §3 "Skill-Internal Ledgers vs. Official Handoff": BACKLOG.md Current 갱신을 1차 방어선으로 승격 — 각 작업 스텝이 끝날 때마다(전체 태스크 완료 시가 아니라) 갱신하는 걸 그 스텝을 "완료"로 표시하는 행위 자체의 일부로 취급. 미완료 중단/세션 종료 시 옮겨 적는 기존 규칙과 Stop 훅(`check_backlog_freshness.py`)은 이 1차 방어선이 빠졌을 때의 백스톱으로 재배치.
- `Workflow_Project.md` §10 Definition of Done: 체크리스트가 "태스크 완료 시"뿐 아니라 태스크 내 개별 스텝마다 적용됨을 명시. "다음 태스크가 backlog에 추가됨" 항목을 "방금 끝난 스텝의 상태도 BACKLOG.md Current에 반영됨"으로 확장.
- `CLAUDE.md` "진행 중 작업 상태" 항목의 행동 지침을 "세션 종료 시"에서 "각 스텝 완료 시"로 앞당김.

사유:
Stop 훅(경고) vs block(강제) 두 방식을 검토하던 중, 사용자가 "기록은 다른 문서와 달리 작업 자체의 일부로 봐야 한다"는 대안을 제시함. 외부에서 사후 감지해 대응하는 hook 방식(경고=놓칠 수 있음, block=사용자 승인 없는 자동 행동 유발)보다, 애초에 기록을 스텝 완료 정의에 포함시켜 빠지면 "완료"로 안 치는 구조가 근본적으로 우월하다고 판단. SDD 스킬이 이미 "리뷰 통과 시 그 자리에서 장부에 한 줄 추가"하는 습관을 갖고 있었는데, 그 습관이 향한 대상(gitignore된 내부 장부)이 잘못됐던 것뿐이므로, 같은 습관을 BACKLOG.md로 재조준.

Impact:
- `Workflow_Project.md` §3, §10 갱신
- `CLAUDE.md` "진행 중 작업 상태" 항목 갱신
- Stop 훅(`check_backlog_freshness.py`)은 유지하되 역할이 "1차 방어선"에서 "백스톱"으로 재정의됨 (코드 변경 없음, 문서상 위상만 변경)

---

[Decision] Reference 문서 작성 원칙에 "간결성"(§1.5) 추가

결정:
- `Workflow_Project.md` §1.5 신설: Reference 문서는 정확한 의미를 해치지 않는 선에서 중복 없이 간결하게 작성.
- History 문서(`Decision.md`/`TechnicalDebt.md`)는 예외 — §1.3(대화 맥락을 대체해야 함)에 따라 Reference 문서보다 상세함이 허용되고, 이 원칙은 이미 기록된 History 항목에 소급 적용하지 않음(§6 append-only 원칙 유지).
- §3 "Skill-Internal Ledgers vs. Official Handoff"의 재현 가능성(self-containment) 요구와 충돌할 땐 재현 가능성이 우선 — 간결함을 이유로 필요한 내용을 링크로 대체하지 않음.

사유:
문서/지침 텍스트가 누적되면서 "지켜야 할 텍스트가 너무 많으면 오히려 안 지켜진다"는 우려가 제기됨. 다만 History 문서는 §1.3에 따라 의도적으로 상세해야 하는 반대 방향 원칙이 이미 있고, 오늘 신설한 §3 재현 가능성 요구와도 무차별 적용 시 충돌할 수 있어 예외/우선순위를 명시해 도입.

Impact:
- `Workflow_Project.md` §1.5 신설

---

[Decision] 세션 인계 브릿지 규칙 신설 — SDD 장부는 세션 내부용, BACKLOG.md가 공식 인계처

결정:
- 스킬이 쓰는 gitignore된 임시 작업 장부(예: `.superpowers/sdd/*`)는 세션 내부 복구용 캐시일 뿐, 세션 간 공식 인계 수단이 아님을 명문화. 그 안의 "완료 태스크→커밋" 매핑만 `git log`로 재구성 가능해 신뢰할 수 있고, 결정/사유/다음 계획 같은 프로즈는 별도로 tracked 문서에 옮겨적지 않으면 다음 세션에서 사라짐.
- 태스크가 완료되지 못한 채 일시중단되거나 세션이 끝날 때는, 그 시점까지의 핵심 결정과 다음 계획을 반드시 `docs/work/BACKLOG.md`(필요시 `Decision.md`)에 직접 옮겨 적어야 함. 기존 §10 Definition of Done의 "결정이 문서화되었는가" 체크는 태스크 완료 시점에만 발동하므로, 이 규칙은 그 체크가 커버 못 하는 "미완료 중단" 케이스를 메움.
- "기록해서 다음 세션이 이어갈 수 있게 했다"고 답하기 전에는, 실제로 새 세션이 `CLAUDE.md`→`BACKLOG.md` 경로만 따라가서 그 내용에 도달하는지 확인해야 함 — 내용 존재+정확성만으로는 부족.

사유:
2026-07-09, 동일 패턴의 세션 인계 실패가 3번째로 반복 확인됨. `.superpowers/sdd/progress-flutter-hifi-screens.md`에 정확한 일시중단 노트가 있었으나 gitignore돼 있고 BACKLOG.md에서 링크되지 않아 새 세션이 발견 불가능했음. 앞선 2회는 문제가 매번 그때그때의 특정 산출물만 패치되고 일반 규칙으로 기록되지 않아 재발함.

Impact:
- `Workflow_Project.md` §3 갱신 (신규 하위 섹션 "Skill-Internal Ledgers vs. Official Handoff")
- `CLAUDE.md` "진행 중 작업 상태" 항목에 행동 지침 + cross-reference 추가
- `TechnicalDebt.md`에 관련 항목 추가 (`.superpowers/sdd/` 플랫 파일명 충돌 건, 해당 파일 참고)
- Flutter Hi-Fi 스프린트 Task 7 일시중단 상세는 그 코드가 실제로 존재하는 `feature/flutter-hifi-screens` 브랜치의 `docs/work/BACKLOG.md`에 별도 커밋으로 반영 (dev 기반 브랜치에 넣으면 아직 dev에 없는 코드를 가리키는 참조가 생겨, 이번에 고치려는 것과 같은 종류의 실패를 재현할 위험이 있어 분리)

---

[Decision] ClothingItem에 재질(material) 태그 추가 — 18개 폐쇄형 어휘

결정:
- `ClothingItem`에 사용자 수정 가능한 `material` 필드 추가(단일 값, 필수).
- 값 범위는 섬유 성분(%) 기준이 아니라 **사람이 옷을 보고 부르는 방식** 기준의 폐쇄형 18개 어휘: 면 / 스판 / 데님 / 니트 / 플리스 / 리넨 / 모달·레이온 / 실크·새틴 / 시어서커 / 코듀로이 / 벨벳 / 패딩 / 나일론(바스락) / 가죽 / 퍼·무스탕 / 캔버스·패브릭 / 스웨이드 / 고무·러버.
- 카테고리(상하의/아우터/신발 등)를 가리지 않는 공용 필드로 둔다(예: 패딩 신발/패딩 바지도 허용). 카테고리별로 자주 쓰이는 값만 우선 정렬해 보여주는 건 UI 구현 시 처리(기존 "분류 기준별 정렬 기준표" 패턴과 동일).
- 옷장 메인 필터에는 추가하지 않는다 — 재질의 1차 목적이 사용자 탐색이 아니라 미래 추천 기능의 분석용 메타데이터라, 필터 추가는 추천 기능 설계 시점에 재검토.
- 니트/패딩처럼 "섬유 종류"가 아니라 "구성 방식(편물, 충전재+누빔)"을 가리키는 항목도 동일 리스트에 포함 — 이 리스트의 원칙 자체가 "질감/짜임으로 시각 구분 가능한가"이지 엄밀한 섬유과학 분류가 아님.

사유:
사용자가 미래에 "자주 입은 조합 분석 기반 옷 추천" 기능을 계획 중이며, 재질이 그 분석에 유의미한 메타데이터가 될 수 있다고 판단함. 다만 사진만으로 재질(특히 혼방 비율)을 정확히 파악하기는 사람도 AI도 어려움 — 실제로 이번 mock 이미지 매핑 중 3건(IMG_4261/4264/4276)에서 최초 추정과 실제 재질이 달라 사용자가 직접 정정함. 이는 기존 `mood_tags`가 "낮은 정확도, Phase 1.5 검증 필요"로 이미 플래그돼있는 것과 동일한 패턴이라, material도 같은 신뢰도 등급(AI 1차 추정 + 사용자 수정 가능)으로 취급하기로 함.

Impact:
- `docs/knowledge/reference/plan/00_MVP.md` §4.1(Auto-tagging fields), §5(Data Model) 갱신
- `lib/models/clothing_item.dart`에 `material` 필드 + `kClothingMaterials` 상수 추가
- `lib/mock/mock_data.dart` 12개 아이템에 재질 값 반영
- Task 10(옷 상세 화면) 스펙에 재질 표시 추가 예정 — 기존 "카테고리 · 색상 · 계절" 한 줄에 이어 붙이는 방식, 별도 섹션 신설 안 함. 반응이 별로면 나중에 뺄 수 있음(확정 아님).
- Follow-up: 재질 종류가 18개로 늘어나 Task 11(옷 추가하기) 드롭다운이 길어짐 — 구현 시 검색 가능한 드롭다운 등 UX 보완 검토 필요.

---

[Decision] PR-create 게이트를 main-base 전용으로 좁히고 gh pr merge 하드 블록 추가

결정:
- `gh pr create`는 base가 `main`일 때(또는 `--base` 미지정 시, 기본값이 `main`이므로)만 계속 게이트. feature→dev(`--base dev`) 등 non-main 대상은 자유롭게 허용.
- `gh pr merge`는 방향 무관 항상 하드 블록 — 확인 후 재시도 모델이 아니라 애초에 AI가 절대 실행하지 않는 액션.

사유:
PR #2(feature→dev) 오픈 후 검토하며, "PR 생성 시 확인받기"와 "merge 전 사람이 GitHub에서 다시 검토하기"가 같은 질문("이 내용을 반영해도 되는가")을 두 번 묻는 중복임을 발견. 실제 반영(dev/main 내용 변경)은 merge 시점에만 일어나므로, feature→dev처럼 merge 시 사람이 어차피 검토하는 경우는 생성 단계 게이트가 불필요. 반면 dev→main은 "지금 릴리즈할지"라는 타이밍 결정이 걸려있어 생성 단계에서도 확인이 의미 있음. 별개로, `gh pr merge`가 애초에 훅의 정규식 검사 대상이 아니어서 "사람만 merge한다"는 §13.3 원칙이 순수 서면 규칙에 불과했던 것도 이번에 기술적으로 막음.

Impact:
- `.claude/hooks/guard_git_actions.py` PR-create 로직 변경, `gh pr merge` 룰 추가
- `Workflow_Project.md` §13.2/13.3 갱신
- `CLAUDE.md` 체크포인트 3 갱신
- `worker.md` 문구 정확성 수정 (워커는 여전히 PR 생성/merge 안 함, 훅 스코프와 무관)

Follow-up (재검토 조건):
이 결정("feature→dev PR 생성은 자유")은 "PR 생성 자체는 아무 자동 동작도 촉발하지 않는다"는 전제에 의존한다. 나중에 PR이 열리기만 해도 자동으로 실행되는 CI/자동배포/자동병합 같은 자동화(예: `.github/workflows/`에 `on: pull_request`로 반응하는 워크플로 추가)를 도입할 때는, 그 작업이 이 전제를 깨는지 반드시 먼저 확인할 것. 깨진다면 feature→dev PR 생성도 다시 게이트가 필요한지 재검토해야 함.

---

[Decision] Git-flow 기반 브랜치/커밋/PR 정책 도입

결정:
- main(릴리즈 전용) ← dev(기본 작업 브랜치, PR 병합만) ← feature/<backlog-slug>(자유 커밋) 3단계 브랜치 구조 도입
- Worker도 feature 브랜치 안에서는 자유 커밋 가능 (기존 "Worker는 절대 커밋 안 함" 규칙 완화)
- dev/main 직접 커밋, gh pr create(feature→dev/dev→main 모두), main으로의 git push는 계속 리포트+사용자 확인 게이트
- `.claude/hooks/block-git-commit.sh`(정규식 기반 — 실측으로 확인된 버그: 커맨드 안에 `git commit`보다 앞서 따옴표가 나오면 매칭이 끊겨 차단이 뚫림)를 브랜치 인지형 Python 훅 `guard_git_actions.py`로 교체

사유:
매 커밋마다 리포트+확인을 받는 기존 방식은 작업량이 늘면서 확인 비용이 커짐. feature 브랜치 안에서의 저위험 커밋은 자유롭게 허용하고, 실제로 공유 상태(dev/main)에 반영되거나 외부에 보이는 행위(PR 생성, main push)에만 확인 게이트를 남기는 것으로 절충. 겸사겸사 기존 훅의 정규식 매칭 버그(따옴표 포함 커맨드에서 차단 실패)도 이번에 해소함.

Impact:
- Workflow_Project.md §13 신설
- CLAUDE.md 체크포인트 3 갱신
- worker.md 커밋 정책 갱신
- `.claude/hooks/block-git-commit.sh` → `guard_git_actions.py` 교체, settings.json 훅 커맨드 갱신
- GitHub Branch protection(main/dev)은 사용자가 별도로 웹 UI에서 설정 (이번 작업 범위 밖)

---

[Decision] 역할별 자료 접근권 원칙 추가 (Layer × Stage 기준)

결정:
- Workflow_Project.md §12 신설: 역할이 보는 자료는 직군이 아니라 "레이어(UI/기능/데이터·아키텍처) × 단계(결정/구현)"로 결정
- Worker/Review 자료는 동일하지 않음: 판단기준 문서(Reference + Decision.md/TechnicalDebt.md)는 공유, 원본 탐색 자료는 Worker 전용, 산출물(diff)은 Review 전용
- Review가 스코프 밖 자료가 필요하면 직접 접근하지 않고 PM에게 스코프 확장을 요청 → PM이 Impact Scope 재평가 후 승인

사유:
"프론트는 디자인 자료를 보고 백엔드는 안 본다"처럼 직군별로 규칙을 하드코딩하면 새 파이프라인마다 규칙을 새로 만들어야 함. 레이어×단계 매핑으로 일반화하면 어떤 파이프라인이 추가돼도 규칙 변경 없이 적용됨.

Impact:
- Workflow_Project.md §12 신설
- 하네스 에이전트 정의 작성 시 이 매핑을 그대로 반영 예정

---

[Decision] Claude Projects 사용 중단, Claude Code 단일 허브 전환 + 핸드오프 자동화

결정:
- 기획/논의를 별도 Claude.ai Project 채팅에서 하던 방식을 중단하고, Claude Code를 유일한 작업 허브로 사용
- Workflow_Project.md §3, §11 갱신: "모든 핸드오프는 사람이 수행" 원칙을
  "핸드오프는 PM 에이전트가 자동 중계하되, 필수 체크포인트는 여전히 사람 확인" 으로 변경
- 하네스 필수 체크포인트 확정 (설정 파일은 추후 별도 작성):
  1) PM의 작업 분배는 사람이 반드시 봄 (비차단 로그)
  2) 결정문서 수정은 diff를 사람이 반드시 확인
  3) git commit 전 리포트 작성 + 사람 확인 필수
  4) 작업↔리뷰 자동 순환, 완료 후 로그 열람 여부는 사람이 선택 (관례로 처리, 인프라 기능 아님)
  5) (드랍) 필수 확인 항목의 "다음부터 자동승인" 버튼 제거 — 권한 시스템 레벨에서 불가능 확인됨
- 작업 단위 = 스텝 (전체 산출물 단위 아님). 워커 인스턴스는 스텝 간 전문성이 같으면 유지, 다르면 새로 스폰 — PM이 그때그때 판단

사유:
Claude.ai Project와 Claude Code는 연동/동기화가 없음(Anthropic 자체 기능요청 #2511, #39051 모두 미구현 확인). 두 도구를 병행하면 Project 지식베이스가 항상 stale해지는 수동 동기화 부담이 발생해서, 논의+실행을 한 도구로 합침.

Impact:
- Workflow_Project.md §3, §11 갱신 완료
- CLAUDE.md에 폴더 안내 추가 완료
- 하네스 설정(.claude/agents/*.md, settings.json 훅)은 틀이 더 갖춰진 뒤 별도 작업 예정

---

[Decision] Design Workflow 순서 변경 — Hi-Fi Sample 선행 방식으로 전환 (기존 결정 대체)

결정:
- ref_정책_Workflow_Design.md §2 프로세스를 다음으로 변경:
  Brand Guide(방향) → Hi-Fi Sample(3~5화면, Wireframe 겸함) → Visual Review 
  → 사이즈/간격/컬러 조정 → Design Tokens 확정 → Component Library → 나머지 화면
- 기존 "PLACEHOLDER 병행 착수" 결정(Design System/Component Library를 Brand Guide와 
  병행 진행)은 본 결정으로 대체(superseded)

사유:
디자인 수치(사이즈/간격/컬러)는 실제 화면에서 육안 확인 후 픽스해야 한다는 판단.

Impact:
- ref_정책_Workflow_Design.md §2, §5 갱신 필요
- 기존 준비된 Task B(Design System/Component Library placeholder 착수) 보류

---

[Decision] Brand Guide Pass 2 확정 — Colors (T1~T3 실값)

결정:
- Pass 1 Visual Direction(아이보리~베이지 배경 + 블루뉴트럴 + 딥블루그레이) 기반
  Primary/Neutral/Accent 실값 확정
- On-Primary는 순수 흰색(#FFFFFF) 대신 오프화이트 적용 (T2의 흑백 회피 취지를
  Neutral 역할뿐 아니라 On-Primary에도 동일 적용)
- 다크모드 대비(WCAG 4.5:1/3:1) 1차 검증 완료

사유:
P6 "흑백 기피" 원칙을 텍스트/배경 역할 전반에 일관 적용. 별도 예외 규정 없음.

Impact:
Design System Stage 5 T1~T3 실값 확정. Task B(Design System 구축) 착수 조건 일부 충족.

Follow-up:
- T2 Gray 스케일 근사치 → 실제 색상 툴 재보간 필요 (Task B 착수 조건)
- Warning/Accent 등 미검증 대비 쌍 → Task B 진입 전 전수 재검증 필요
- 문서 파일명(Pass1+2 통합) 리네이밍 → Pass 3 완료 후 일괄 정리

---

[Decision] Brand Guide Pass 1 확정 — Essence/Personality/Visual Direction

결정:
- Brand Essence: E2 (자기 이해형 — "입어온 나를 돌아보는 기록")
- Brand Personality: 든든한 개인 기록자 (격식 있는 다정함, 반말/애칭/과한 감탄사 배제)
- Visual Direction: 아이보리~베이지 배경 + 블루뉴트럴, 딥블루그레이로 무게감,
  웜톤/핑크/그린 계열 액센트 배제

사유:
Needs 문서 ②(기억/취향 축)에 무게 실은 Essence 선택. Personality는 P1의
"경로별 표현 강도만 차등, 구조는 미분기" 원칙과 정합되도록 담백함 기반 단일 축 유지.

Impact:
Pass 2(컬러 실값), Pass 3(타이포)의 상위 제약. Design System Stage 5 실값 산정 시 참조.

Follow-up:
- Accent 색상 역할 미정 → Pass 2에서 결정
- 다크모드 대비(WCAG 4.5:1) 검증 → Pass 2 착수 조건
- 팔레트 5종 → 1종 압축 → Pass 2에서 확정

---

[Decision] Brand Guide 선행 없이 임시 토큰 값으로 Design System 착수

배경:
Brand Guide 확정 지연으로 Stage 5(Design Tokens) 실값 확보 시점 불투명.

결정:
- Design Tokens 역할 구조(Stage 5)는 유지, 실값 대신 PLACEHOLDER 값으로 Design System/Component Library 선행 진행.
- 모든 컴포넌트는 토큰 역할만 참조(하드코딩 금지). Brand Guide 확정 시 값만 일괄 교체.

사유:
Stage 5 문서에 이미 "역할만 정의, 값은 Brand Guide 대기"로 명시되어 있어 기존 설계 의도와 합치. 새 개념 도입 아님.

Impact:
Design System, Component Library. 화면/기획 문서 변경 없음.

Follow-up:
Brand Guide 확정 시 PLACEHOLDER 값 전수 교체 Task 필요 (TechnicalDebt.md 등록 대상 여부는 별도 확인).

---

[Decision] ClothingItem의 category/season/color/material 4개 필수 필드를 선택 필드로 전환(nullable화)

상태: **리토핑 완료(2026-07-19)** — 실제 영향 파일은 이 항목 최초 작성 시점의 grep(아래 Impact의 13개)이 과대 집계였음이 리토핑 과정에서 밝혀짐(`TrashEntry.category`/`AppDetailScaffold.category`는 `AppCategory` 타입이라 무관, `Composition.season`은 이미 nullable이라 무관) — 실제로는 `lib/models/clothing_item.dart`, `lib/mock/mock_data.dart`, `lib/screens/closet_item_detail_screen.dart`, `lib/widgets/selectable_gallery_tile.dart` 4개 파일만 수정. `lib/providers/closet_providers.dart`는 기존 필터 로직이 이미 null-safe해 변경 불필요로 확인. Worker→Review(1차 P0: mock 아이템 추가 방식이 기존 통합테스트 개수 assertion을 깨뜨림 → 전역 mock 대신 테스트 로컬 주입 패턴으로 재작업)→Review(2차 통과)→Tester(7개 시나리오 전부 통과, `integration_test/closet_item_nullable_fields_test.dart` 신설) 전체 사이클 완료. 커밋 `88cbea6`/`92d93ef`/`4c5c522`. Review가 발견한 P2(copyWith가 null로 명시적으로 되돌리는 걸 지원 안 함)는 `docs/history/TechnicalDebt.md`에 별도 기록, `closet_add_screen.dart` 구현 시점까지 의도적으로 미해결 보류.

배경:
`2026-07-19-main-header-classification-and-settings-entry-design.md` 스펙 작업 중 사용자가 "옷장 category/season이 지금 왜 non-nullable이냐"고 확인, 그 배경에서 제기됨.

결정:
- `ClothingItem.category`/`season`/`color`/`material` 4개 필드를 전부 `required` → nullable(선택 필드)로 전환한다.
- 대상은 `ClothingItem`뿐 — `Composition`/`StyleLog`는 이 결정 범위 밖(별도 검토).

사유:
앱의 본질적 가치는 "옷 등록 — 아카이브 사진 연결"이고, 종류/계절/색상/소재 같은 태그 정보는 부가적이라고 판단. AI 자동 라벨링(`01_옷장.md` "여러 장 한 번에 추가하기")이 보통은 채워주지만 (a) 사용자가 원하는 선택지가 폐쇄형 어휘에 없을 수 있고 (b) 태그를 건너뛰고 빠르게 등록만 하고 싶을 수 있음 — 두 경우 모두 저장 자체를 막아서는 안 된다는 게 사용자 판단.

Impact:
- 이미 이 4개 필드를 non-null로 전제하고 읽는 파일 13개가 리토핑 대상(grep 확인, 2026-07-19 기준): `lib/widgets/trash_gallery_tile.dart`, `lib/widgets/selectable_gallery_tile.dart`, `lib/widgets/composition_gallery_tile.dart`, `lib/screens/trash_main_screen.dart`, `lib/screens/composition_detail_screen.dart`, `lib/screens/closet_item_detail_screen.dart`, `lib/screens/app_detail_scaffold.dart`, `lib/providers/composition_providers.dart`, `lib/providers/closet_providers.dart`, `lib/models/trash_entry.dart`, `lib/models/enums.dart`, `lib/models/composition.dart`, `lib/models/clothing_item.dart`.
- **`2026-07-19-main-header-classification-and-settings-entry-design.md`(옷장·코디 메인 헤더 드릴다운 캡슐 스펙)와의 관계**: 그 스펙은 "옷장의 4개 분류 기준(날짜/종류/계절/착용빈도)은 대응 필드가 전부 non-nullable이라 미분류 카드가 없다"고 명시하는데, 이 결정이 실행되면 옷종류·계절 두 필드가 nullable이 되어 그 전제가 깨진다 — 옷장도 코디(계절·날씨)와 동일하게 미분류 그룹 카드가 필요해짐. 두 작업 착수 순서에 따라 어느 한쪽이 먼저 완료되면 나머지가 그 변경을 반영해야 한다.
- `closet_add_screen.dart`(아직 스켈레톤, 미착수) 구현 시 필수/선택 필드 검증 로직에 반영 필요 — 현재는 착수 전이라 즉시 영향 없음.

착수 방식: 별도 Decision + 리토핑 태스크로 분리한다(사용자 확정, 2026-07-19) — 위 헤더 드릴다운 스펙엔 포함하지 않고 진행 중인 채로 둔다. `docs/work/BACKLOG.md`에 후속 작업으로 등록.

---

[Decision] ClothingCategory "원피스" 값을 "한벌옷"(onePiece)으로 개명 + 착용순서 위치 변경

배경:
`_공통 규칙.md` "분류 기준별 정렬 기준표" 편집 중 사용자가 옷 종류 착용순서에 "한벌옷"(원피스+점프수트를 포괄하는 상위 개념)을 추가 — 기존 "ClothingItem.category ... 폐쇄형 어휘 확정" 결정(위 §)이 확정한 8종 중 `dress`("원피스")를 대체한다.

결정:
- `lib/models/enums.dart`의 `ClothingCategory.dress`(라벨 "원피스")를 **`ClothingCategory.onePiece`(라벨 "한벌옷")로 개명**한다. 영어 "dress"는 점프수트를 포함하지 않는 좁은 개념이라 넓어진 범위(원피스+점프수트)와 어긋나 식별자도 함께 바꿈("영어 dress → 원피스만, 한글 한벌옷 → 원피스·점프수트 포괄"이 서로 안 맞다고 판단, 사용자 확정).
- **선언 순서(=착용순서) 변경**: 기존 `hat, top, outer, bottom, dress, socks, shoes, bagAccessory`(원피스가 5번째, 하의 다음)에서 → `hat, onePiece, top, outer, bottom, socks, shoes, bagAccessory`(한벌옷이 2번째, 모자 다음)로 이동. `_공통 규칙.md`가 이미 이 순서로 편집됨(사용자 직접) — enum 쪽이 그 순서를 따라간다.

사유:
한벌옷(원피스/점프수트)은 상의+하의를 동시에 대체하는 옷이라 "이것부터 입으면 별도 상/하의가 필요 없다"는 논리로 착용순서 앞쪽(모자 다음)에 두는 게 사용자 판단상 자연스러움.

Impact:
- `lib/models/enums.dart` — enum 값 개명+재정렬, 라벨 텍스트 변경
- `lib/mock/mock_data.dart` — `ClothingCategory.dress` 참조 2건(`c01`, `c08`)을 `.onePiece`로 교체
- `integration_test/closet_item_detail_data_binding_test.dart` — `.dress` 참조 갱신
- `2026-07-19-main-header-classification-and-settings-entry-design.md`의 "ClothingCategory 선언 순서가 이미 착용순서와 일치해 추가 매핑 불필요" 서술은 이 변경 이후에도 여전히 유효(개명+재정렬 이후 순서가 착용순서 그대로이므로) — 별도 스펙 수정 불필요.
- 순수 rename+재정렬이라 런타임 동작 변화 없음 — Worker→Review만 진행(Tester 불필요, Task 1/5 선례와 동일 성격).

---

[Decision] 재검증 루프(Review/Tester 재시도)의 재검증 스코프를 diff 단위로 축소 (`Workflow_Project.md` §5, Version 3.0 → 3.1)

배경:
사용자가 "자동 작업 돌리면 1~2시간이면 토큰을 다 쓰는데 이 규모 프로젝트에서 보편적이냐"고 진단을 요청(2026-07-29). PM이 실측한 결과: `lib/`은 6,900줄(69파일)로 앱 코드 자체는 크지 않음. `test/`+`integration_test/`는 13,629줄로 앱 코드의 약 2배. `docs/`는 약 19,000줄. `.claude/policies`+`agents`+`skills`는 약 2,000줄. 전체 커밋 420개 중 192개(46%)가 docs/backlog/decision 전용 커밋. 결론: 프로젝트 규모나 Flutter 생태계 자체보다, 이 harness가 규정한 PM→Worker→Review→Tester→(Audit) 멀티에이전트 게이트 파이프라인 — 특히 "Tester 미통과 시 Review부터 전체 재수행"(§5 M/L/XL) 규칙이 재시도마다 원본 Task 전체를 처음부터 다시 판정하게 만드는 구조 — 이 최대 비용 요인으로 식별됨.

결정:
- §5 M/L/XL 파이프라인의 재검증 루프(Tester 미통과 → Worker fix → Review부터 재수행)에 새 하위 절 "재검증 루프의 재검증 범위"를 추가: 재검증 대상을 원본 Task 전체가 아니라 **Worker fix의 diff + 그 fix가 건드린 파일**로 좁힌다. fix가 원래 Task Manifest(§12.4) 밖의 파일까지 건드렸다면 그 확장분만 §12.3(Scope Escalation)으로 개별 승인. 검증 강도(Review·Tester 모두 통과할 때까지 반복)는 그대로 유지 — 낮추는 건 반복 실행 비용뿐.
- 에이전트를 새로 spawn할지 이어 쓸지는 별도 규칙을 만들지 않고, 이미 있는 CLAUDE.md "에이전트 인스턴스 수명" 원칙을 그대로 가리킨다(같은 Task 재검증 라운드는 그 원칙의 "연속된 스텝, 같은 전문성" 케이스에 해당).
- 문서 버전 3.0 → 3.1 (§1.6 챕터급 추가 기준 적용).

수정 이력: 최초 초안(2026-07-29)은 "에이전트 재사용" 규칙 자체를 이 문서에 다시 서술했으나, 사용자가 CLAUDE.md:37 "에이전트 인스턴스 수명"과 내용이 겹친다고 지적(2026-07-30) — 검토 결과 그 부분은 순수 중복이었고(§1.5 Concise Writing 위반), 실제로 CLAUDE.md에 없던 새 규칙은 "재검증 스코프를 diff로 좁힌다"뿐이었음을 확인해 중복 서술을 제거하고 참조로 대체.

사유:
diff 스코프 축소는 품질 게이트(Review/Tester 반복 통과 요구)를 전혀 낮추지 않으면서, 이미 통과한 부분을 라운드마다 다시 판정하는 낭비만 제거한다. 함께 검토했으나 기각한 대안:
- 문서화 의무(BACKLOG/Decision/TechnicalDebt 기록) 축소 — 커밋의 46%가 docs 전용인 건 실제 인시던트(세션 간 컨텍스트 유실, dev/정책 드리프트 — §3 "Skill-Internal Ledgers", §13.4 2026-07-10 사례)를 막기 위해 쌓인 규율이라, 되돌리면 그 실패를 재현할 위험이 큼.
- 문서량(`docs/` 약 19,000줄) 자체를 줄이거나 삭제 — §12(Layer×Stage 스코프 라우팅)로 이미 태스크별 최소 자료만 선별 전달되고 있어(전체를 통째로 읽는 구조가 아님), 텍스트 총량을 줄여도 실제 토큰 절감 효과는 작다고 판단.
- Audit 게이트(L/XL 완료 전, Decision-Stage 확정 전) 축소 — 이미 크기·단계 기준으로 좁게 게이트돼 있어(S/M 스킵, Decision-Stage는 항상 1회) 추가로 줄일 여지가 작다고 판단.

Impact:
- `.claude/policies/Workflow_Project.md` §5 수정, 버전 3.1로 상향.
- 기존 M/L/XL 재검증 문구는 그대로 유지, 새 하위 절 하나만 추가 — CLAUDE.md에 이미 있는 에이전트 재사용 원칙은 참조만 하고 재서술하지 않음.
- 앱 코드/런타임 동작 변화 없음 — Worker→Review만 진행(문서 전용 변경, Tester 불필요).

---

[Decision] 정책 문서 4종 + CLAUDE.md 간 중복 서술 통합 — 조항 구조는 유지, 반복 규칙만 참조로 대체 (`Workflow_Project.md` §9/§11 3.1→3.2, `Workflow_Development.md` §1/§4/§7 2.0→2.1, `Workflow_Design.md` §7/§12 3.0→3.1, `CLAUDE.md` 체크포인트 3/4/5/6/7 + "진행 중 작업 상태" 문단)

배경:
사용자가 "정책 문서들이 법전식(번호 매긴 조항, 중첩 예외, 상세 예시)이라 읽기 복잡하고 오히려 성능을 떨어뜨리는 것 같다, 미사여구 없이 간결해지면 좋겠는데 AI 입장에선 다른가"라고 문제 제기(2026-07-30). PM 판단: 조항식 구조·정밀한 용어 자체는 모호한 산문보다 AI에게 오히려 유리(추론에 의존하지 않아도 됨) — 문제는 형식이 아니라 **같은 규칙이 여러 문서/절에 다른 말로 반복 서술되는 것**. 근거: 바로 앞 Decision 항목에서 PM 본인이 쓴 조항이 CLAUDE.md:37과 중복인 걸 스스로 못 알아챈 사건. `audit` 서브에이전트에게 정책 문서 5개(CLAUDE.md + policies 4종)를 대상으로 중복 탐지 감사를 위임, 다음을 발견: CLAUDE.md 체크포인트 3~7과 "진행 중 작업 상태" 문단이 `Workflow_Project.md` §13.2/§13.3/§5/§13.4/§3을 재서술(P0/P1, CLAUDE.md는 세션마다 매번 읽혀 비용이 가장 큼); `Workflow_Development.md` §4의 PM·Tester가 `Workflow_Project.md` §2를 거의 그대로 복사(P0/P1, Worker/Review 스폰마다 읽힘); "Review identifies problems."/"Audit evaluates the project as a whole." 두 문장이 Project/Development/Design 세 문서에 토씨까지 동일하게 반복(P1); "Audit은 못 고치고 태스크만 만든다"가 `Workflow_Project.md` 안에서만 §2·§9 두 번 반복 포함 5곳에 반복(P2); `Workflow_Development.md` §1이 `Workflow_Project.md` §1.3을 그대로 베낌(P2); `Workflow_Project.md` §11이 같은 문서 내 다른 절 대부분을 재요약(P3, 위 세 문서 공통 문장 중복의 원인 뿌리). `Workflow_Frontend.md`는 findings 없음 — 스킬 참조 위임 패턴을 이미 올바르게 쓰고 있어 이게 목표 패턴으로 확인됨.

결정:
- 조항 번호·구조·정밀한 용어는 전부 그대로 유지한다 — 이번 통합은 문체를 산문으로 풀어쓰는 게 아니라, 중복된 규칙 서술을 "→ §X 참고" 포인터로 대체하는 것에 한정.
- `Workflow_Project.md` §9(Audit Principles)를 §2 Feature Audit로의 포인터로 축소. §11(Core Operating Principles)을 각 항목이 실제 정의된 절 번호를 가리키는 색인표로 전환(문서 내부 재요약 제거) — 버전 3.1→3.2.
- `Workflow_Development.md` §1(Source of Truth), §4의 PM·Tester를 `Workflow_Project.md` §1.3/§2로의 포인터로 축소하되, 각 역할의 dev 도메인 고유 추가사항(Tester의 `integration_test/` 작성 권한, PM의 "development 국한 아님" 비고 등 — Project.md에 없는 내용)은 그대로 유지. §7의 "Review identifies problems."/"Audit evaluates..." 두 줄을 `Workflow_Project.md` §11 참고 한 줄로 병합(9개 항목→8개) — 버전 2.0→2.1.
- `Workflow_Design.md` §7(Design Audit) 서두를 `Workflow_Project.md` §2로의 포인터로 축소(Design 고유 Review Areas 5개는 유지). §12의 동일 두 줄도 같은 방식으로 병합(10개 항목→9개) — 버전 3.0→3.1.
- `CLAUDE.md` 체크포인트 3(dev/main 커밋 게이트)·4(작업↔리뷰↔테스트 사이클)·5(dev 동기화)·6(Design 마일스톤)·7(연속성 시뮬레이션)과 "진행 중 작업 상태" 문단에서, `Workflow_Project.md`/`Workflow_Design.md`가 이미 전체 서술한 세부 규칙(Tester 실패 시 재수행 조건, PR 게이트 세부 조건, Decision-Stage Audit 게이트 조건, BACKLOG Current 갱신 원칙 등)을 걷어내고 "무엇을 언제 하는지" 한 줄 요약 + `Workflow_Project.md`/`Workflow_Design.md` 절 번호 포인터로 대체. 체크포인트 1·2는 이미 올바른 패턴이라 변경 없음.
- Worker instance 일반화 커밋(`8134b5f`, "워커 인스턴스 수명"→"에이전트 인스턴스 수명", feature/flutter-hifi-screens에서 사용자가 직접 커밋했으나 dev엔 미병합)을 이 브랜치로 cherry-pick — `Workflow_Project.md` §5의 재검증 루프 조항이 "CLAUDE.md 에이전트 인스턴스 수명"을 가리키는데, dev 기준 브랜치엔 그 일반화된 표현이 아직 없어 포인터가 어긋날 뻔한 걸 미리 바로잡음.

사유:
"조항 구조 유지 + 중복 제거"가 맞는 방향인 이유: 모호한 산문으로 풀면 여러 서브에이전트가 각자 콜드 스폰 상태에서 같은 문서를 다르게 해석할 위험이 커져, 이 하네스가 추적성을 위해 멀티에이전트 게이트를 쓰는 목적과 정반대로 간다. 반대로 중복 제거는 정밀도 손실 없이 (a) 읽기 복잡도와 (b) 매 서브에이전트 스폰마다 드는 토큰 비용을 동시에 줄인다. Development.md의 Worker/Review/Integrator 섹션은 감사가 "5개 역할 전부"를 제안했지만 실제로 비교해보니 Project.md의 더 짧고 일반적인 정의를 실질적으로 확장(dev 도메인 전용 세부 항목 다수 추가)하고 있어 진짜 중복이 아니었음 — PM 자체 재검증으로 스코프를 좁혀 PM/Tester만 손봄(감사 요약 문구도 "체크포인트 2~7"이라 했지만 실제 근거는 체크포인트 3~7+문단 43이었던 것과 같은 종류의 자체 과장 — Where 근거를 직접 대조해 실제 대상만 수정).

Impact:
- `.claude/policies/Workflow_Project.md`(§9, §11, 버전 3.2), `Workflow_Development.md`(§1, §4 PM/Tester, §7, 버전 2.1), `Workflow_Design.md`(§7, §12, 버전 3.1), `CLAUDE.md`(체크포인트 3/4/5/6/7, "진행 중 작업 상태" 문단) 수정.
- `Workflow_Frontend.md`는 변경 없음(findings 없었음).
- 그 어떤 조항의 **의미**도 바뀌지 않음 — 서술 위치와 중복 여부만 정리. 앱 코드/런타임 동작 변화 없음, Worker→Review만 진행(Tester 불필요).