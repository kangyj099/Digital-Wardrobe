# 설계 단계 구조 산출물 도입 (소유권 맵 + 크로스커팅 시퀀스)

> Status: **확정(2026-08-15)** — Review 2회 + Audit 3회 통과. 결정 기록은 `docs/history/Decision.md` 최상단 항목, 산출물은 `docs/reference/architecture/00_OwnershipMap.md`
> Layer: Logic/Feature + Policy · Stage: Decision

## 1. 배경 및 동기

동일 동작이 여러 화면에서 호출될 것이 명세에 드러나 있었는데도 각 화면이 독립적으로 구현한 사례가 확인됐다.

삭제 절차가 6개 진입점(메인 3 + 상세 3)에 복제됐다. 근거:

- `05_삭제 & 휴지통 (Main형, 플랫+필터 변형).md` 8-13행이 진입점을 두 부류로 명시한다 — 상세 화면 3개(옷 상세/코디 상세/스타일 일지 열람)를 이름으로 열거하고, 메인 갤러리를 하나의 항목으로 기술한다. 그리고 그 아래에서 동작을 하나로 통일해 규정한다("확인 모달 없이 즉시 휴지통으로 이동 + 토스트").
- `2026-07-21-multi-select-and-trash-design.md` §6 "화면 변경"이 상세 3화면과 함께 `app_detail_scaffold.dart`(공용 셸)를 나열하고, 그 항목의 서술은 "더보기 메뉴에 실제 `[삭제]` 연결"이다.
- 실제 결과는 `lib/screens/app_detail_scaffold.dart` 32-34행 독스트링이 명시한다 — "호출부가 자기 도메인의 `softDeleteMany({id})` + `context.pop()` + `GlassToast.show(...)`를 책임진다(이 Scaffold는 도메인을 모름)". 공용 셸은 진입점(메뉴)을 갖고, 동작 절차는 6개 호출부가 각각 가져갔다.

**명세 부재도 설계 부재도 아니다.** 명세는 진입점 부류와 통일 동작을 규정했고, 설계는 파일 단위 분해와 공용 위젯 신설까지 수행했다. 빠진 것은 **그 동작의 코드가 어느 한 곳에 사는가**라는 항목이다.

이 결함을 하류에서 잡을 수 없는 이유:

- Minimal Handoff(`Workflow_Project.md` §3)와 Task Manifest(§12.4)가 Worker의 파일 시야를 의도적으로 좁힌다. 한 진입점을 구현하는 Worker는 나머지 진입점을 볼 수 없다.
- Review는 한 태스크의 diff만 본다. N번째 복제 시점에도 그 diff에는 1곳만 보인다.
- Audit은 전체를 보지만 L/XL에서, 파이프라인 말미에 동작한다.

따라서 상류(Decision 단계)에서 결정되어야 한다.

**기존 규칙과의 관계**: 2026-08-15 커밋 `257601b`이 `Workflow_Development.md` §1에 "설계 산출물은 동작 절차의 **소유 계층**을 명시할 것"을 이미 추가했다. 이 제안은 그 규칙을 대체하지 않고 **소유 단위를 계층에서 파일 1개로 좁히고, 그 결정을 기록·전달하는 매체를 규정**한다. 규칙만 있고 산출물과 전달 경로가 없으면 준수 여부를 아무도 확인할 수 없다.

## 2. 도입 산출물

### 2.1 소유권 맵 (Living Document)

**위치**: `docs/reference/architecture/00_OwnershipMap.md`

이 폴더는 신설이 아니다. `Decision.md`(2026-08-02, 181행)가 `docs/reference/architecture/`를 "Auth/Storage 연동, 상태관리, **모듈 경계** 등 앱 상위 구조 문서용"으로 이미 신설·범위 지정했고 현재 비어 있다(git이 빈 디렉토리를 추적하지 않아 워킹트리에 안 보일 뿐이다). 소유권 맵은 그 "모듈 경계" 범위에 해당하므로 새 카테고리를 만들지 않고 기존 폴더의 첫 문서가 된다.

**형식**: 표 1개. 각 행은 하나의 크로스커팅 항목에 대해 소유 파일 1개를 지정한다.

**등재 대상**: 둘 이상의 화면/호출부에서 쓰이는 것 중 아래 둘 중 하나. 단일 화면 전용 로직은 넣지 않는다 — 넣으면 표가 코드 미러가 되어 즉시 노후화한다.

1. **동작** — `flutter-implementation-conventions`의 정의를 그대로 쓴다: "확인·상태변경·화면전환·피드백·되돌리기 중 둘 이상이 정해진 순서로 묶인 절차".
2. **화면이 로컬로 재구현할 수 있는 공용 컴포넌트** — 공용 셸/크롬, 그리고 여러 도메인이 공유하는 렌더링 경로. 판정 기준은 `flutter-implementation-conventions` Audit 체크리스트가 이미 쓰는 것과 같다("공용 셸을 안 쓰고 화면이 자체 구현을 새로 짰는지"). 그 점검이 참조할 정본이 필요하므로 컴포넌트도 등재 대상이다.

**모델·데이터 클래스는 제외한다** — `lib/widgets/` 아래 있더라도(예: `interactive_artboard/artboard_item.dart`, importer 다수) 소유 질문의 대상이 아니다. 이 맵은 동작과 컴포넌트만 다룬다.

**리프 프리미티브는 제외한다**(단, 리프라도 화면이 손으로 반복해 드리프트가 발생한 기록이 있으면 등재한다 — `selection_entry_button.dart`가 그 사례) — `glass_pill.dart`, `status_badge.dart`, `multi_select_checkmark.dart`, `gallery_meta_label.dart`처럼 화면이 "자체 구현으로 대체"할 성질이 아닌 말단 표현 위젯. 이 경계가 없으면 `lib/widgets/`에서 importer 2개 이상인 파일 27개가 전부 등재 대상이 되어, 표가 `ls lib/widgets/`와 같아지고 위 "코드 미러 금지"와 자기모순에 빠진다.

**규칙**

- 소유 파일은 정확히 1개다. 2개 이상이면 그 항목은 설계가 끝나지 않은 것으로 간주한다.
- **아직 소유 파일이 없는 항목은 "미정"으로 적되 행은 유지한다.** 행을 지우면 "미해결"과 "그런 항목이 없음"이 구분되지 않는다.
- **도메인별로 갈라지는 항목은 도메인당 1행으로 쪼갠다.** 한 행에 파일 여러 개를 적고 "도메인당 하나라서 단일"이라고 쓰지 않는다.
- **문서화된 의도적 예외가 있으면** 소유 파일은 1개로 유지하되 비고에 예외 대상과 근거 문서를 명시한다. 근거 없는 분기는 소유 파일을 2개로 적어 미해결임을 드러낸다.
- **행을 추가·수정할 때 소유 파일과 등재 자격은 grep으로만 확인한다.** 설계 문서나 명세의 열거를 근거로 삼지 않는다. 독스트링에 등장하는 심볼명을 호출부로 세지 않는다.
- **호출부 목록도 개수도 두지 않는다.** 호출부 열거는 `flutter-implementation-conventions`의 "공용 컴포넌트 도입 시 호출부 전수 확인"이 이미 grep을 기준선으로 규정하고 있고, 같은 커밋이 "스펙에 열거된 호출부 목록은 완전하다고 전제하지 않는다"고 못박았다. 개수도 목록과 동일한 노후화 특성을 가지며, 어차피 검증 시 grep으로 다시 세야 하므로 저장된 숫자는 중복이다. 이 맵이 답하는 질문은 "누가 소유하는가" 하나다.
- **다른 Reference 문서에 박혀 있는 소유권 서술과의 우선순위**: 소유 파일에 대해서는 이 맵이 정본이다. `00_DataSchema.md` §13.3(`lib/services/` 폴더 규칙)·§13.4(공유 판정 단일 정본)처럼 기능 문서 안에 들어 있는 소유권 규정은 근거로 참조하되, 소유 파일이 바뀌면 이 맵을 갱신한다.

**맵 파일은 위 규칙 블록을 자기 안에 싣는다.** 이 스펙은 §2.2가 규정한 대로 확정 후 이력이 되므로, 규칙이 여기에만 있으면 미래에 `00_OwnershipMap.md`를 편집하는 사람에게 전달되지 않는다. 규칙은 산출물과 함께 다녀야 한다.

**갱신 트리거**: 공유 동작의 소유 파일이 바뀌거나, 어떤 동작이 크로스커팅이 되거나 아니게 될 때. `Workflow_Development.md` §5의 Reference 갱신 트리거 목록에 이 항목을 추가해야 한다(§4.3) — 현재 목록(기획/API/DB/디자인시스템/정책 변경)에는 구조 소유권 변경이 없어, 추가하지 않으면 이 맵의 갱신 의무가 자기가 속한 문서 트리의 갱신 규칙과 모순된다.

### 2.2 크로스커팅 동작 시퀀스 (시점 스냅샷)

**위치**: 해당 기능의 설계 문서(`docs/superpowers/specs/*-design.md`) 안. 별도 파일로 분리하지 않는다.

**형식**: mermaid `sequenceDiagram` 코드블록. 이미지 파일 금지 — git diff가 가능해야 하고, 에이전트가 읽고 쓸 수 있어야 하며, GitHub/VSCode에서 그대로 렌더된다.

**대상**: 둘 이상의 진입점을 갖는 동작 1개당 1개.

**갱신 의무 없음.** `docs/superpowers/specs/`는 날짜가 붙은 시점 문서다. 이후 구조가 바뀌면 소유권 맵이 정본이고 이 다이어그램은 이력이다.

### 2.3 채택하지 않는 것

- **클래스 다이어그램**: 이 코드베이스의 모델은 상속 계층이 없는 순수 데이터 클래스이고, 실질 구조는 레이어 소유권이다. 2.1이 그 역할을 더 적은 유지비로 수행한다.
- **액티비티 다이어그램**: 화면별 UX 명세가 이미 사용자 플로우를 산문으로 기술하고 있어 중복이다. 분기가 복잡한 경우 2.2의 시퀀스에 흡수한다.

## 3. 적용 게이트

다음 중 하나에 해당하면 2.1·2.2가 Decision 단계 산출물의 필수 구성이다.

- Task 크기가 **L 또는 XL**
- 또는 **명세가 한 동작에 대해 2개 이상의 화면/진입점을 명시**한 경우(크기 무관)

여기서 "명세"는 그 Task의 Layer×Stage에 대한 §12.1 Required Materials를 가리킨다 — 스캔 대상 문서 집합이 Task마다 확정된다. **"모든 갤러리 화면", "각 상세 화면" 같은 복수형 집합 명사는 항목이 하나여도 2개 이상으로 센다** — 항목 수가 아니라 그 명세가 가리키는 화면 수가 기준이다.

단일 화면 범위의 S/M 작업은 이 게이트에서 면제한다 — 즉 Decision 단계 산출물로서의 2.1·2.2 작성 의무가 없다. 근거: 삭제 6중복은 자체 태깅 L/XL인 그룹 B 단일 태스크 안에서 전부 생성됐으므로(`2026-07-21-multi-select-and-trash-design.md` §6 말미) S/M 면제가 원인이 아니다.

**단, 소유권 맵 자체는 이 게이트와 무관하게 모든 Implementation Task에 전달된다(§4.6(d)).** S/M 작업이 기존 공유 동작에 호출부를 하나 더 붙이는 경로는 빈도가 가장 높은 중복 경로인데, §4.4의 Definition of Done은 "소유 파일이 바뀐 경우"에만 발동해 이 경우를 못 잡는다. 게이트로도 DoD로도 안 걸리는 구멍이 생기므로, 맵 전달은 게이트에서 분리한다.

## 4. 정책 문서 반영 지점

### 4.1 `Workflow_Development.md` §1 — 기존 문장 수정(추가 아님)

현재 문장(커밋 `257601b`)의 "The layer responsible for owning the procedure"를 파일 단위로 좁힌다. 새 문단을 덧붙이지 않는다 — 같은 섹션 안에 같은 규칙이 두 벌 생기는 것을 피한다.

> * The single file that owns the procedure. Listing the entry-point files is not sufficient.

### 4.2 `Workflow_Project.md` §5 Decision-Stage Pipeline — 판정 기준 추가

Logic/Feature 및 Data/Architecture의 Decision 단계에는 전용 Review 체크리스트 문서가 존재하지 않는다(`uiux-design-conventions`는 UI/Screen 전용, `flutter-implementation-conventions`는 Implementation 전용). 따라서 별도 체크리스트를 신설하지 않고, 이미 이 단계를 규정하고 있는 §5 본문에 판정 기준을 둔다.

**적용 범위는 세 Decision 행 전부**(UI/Screen · Logic/Feature · Data/API/Architecture)로 명시한다. §5 본문의 도입 문장이 앞 두 행만 열거하고 Data/Architecture는 §12.1 표를 통해서만 걸려 있어, 범위를 암묵으로 두면 같은 논쟁이 반복된다. 크로스커팅 소유권이 실제로 결정되는 곳이 Data/Architecture Decision(`00_DataSchema.md` §13.4의 단일 정본 술어 등)이라 특히 그렇다. 참고: `BACKLOG.md` Next의 [최우선] 항목이 이 §5 도입 문장 문제를 다루는데, 그중 §12.1 표 쪽은 2026-08-02에 이미 해소됐고 §5 본문 쪽만 남아 있다 — 이 수정으로 함께 해소되면 그 백로그 항목도 정리한다.

> Decision 단계의 small-unit review는 다음을 함께 판정한다. 이 판정은 `review` 서브에이전트가 수행하든, 위 대체 조건(`writing-plans` Self-Review 3항목 + 정책 대조 승인)으로 대체되든 동일하게 적용된다 — 대체 경로에서는 Self-Review의 네 번째 항목으로 수행한다.
> - 명세가 한 동작에 대해 복수의 진입점을 열거했는데 설계가 그 동작의 소유 파일을 지정하지 않았으면 P1.
> - 게이트(Task 크기 L/XL, 또는 명세가 한 동작에 대해 2개 이상의 화면·진입점을 명시)에 해당하는 Task인데 소유권 맵 갱신분이 산출물에 없으면 P1.

대체 경로에도 걸어야 하는 이유: §5는 Logic/Feature × Decision(이 제안 자신의 Layer/Stage)에서 `review` 서브에이전트 호출을 생략할 수 있게 허용하고, Self-Review 3항목(Spec coverage/Placeholder scan/Type consistency) 중 어느 것도 소유자 지정을 보지 않는다. 대체 경로에 안 걸면 정책이 권장하는 더 싼 경로에서 이 판정이 통째로 건너뛰어지고, 남는 것은 파이프라인 말미의 Audit뿐인데 그건 §1이 "너무 늦다"고 지적한 바로 그 위치다.

### 4.3 `Workflow_Development.md` §5 Reference Document Update Rules — 트리거 추가

> * Ownership of a shared behavior changes (the owning file moves, or a behavior becomes or ceases to be cross-screen)

이 항목이 없으면 "Implementation-only work should not modify the Reference documents"와 소유권 맵의 갱신 의무가 충돌한다.

### 4.4 `Workflow_Project.md` §10 Definition of Done — 체크 추가

> □ If this step changed which file owns a shared behavior, the ownership map has been updated

### 4.5 `Workflow_Project.md` §12.1 / §12.4 — 전달 경로 확보 (**이 제안의 핵심**)

위 4.1~4.4가 모두 갖춰져도, 소유권 맵이 Required Materials에 없으면 PM이 규정대로 Task Manifest를 조립할 때 Worker/Review 누구에게도 전달되지 않는다. §12.1 표의 어느 행에도 이 문서가 없으면 아무도 열지 않는다 — §1이 지적한 실패 구조가 이 제안 자체에 그대로 적용된다.

§12.1 표 아래에 행 단위 수정 대신 단서 1줄을 추가한다.

> 모든 Implementation 단계 Task, 그리고 게이트(Task 크기 L/XL, 또는 명세가 한 동작에 대해 2개 이상의 화면·진입점을 명시)에 해당하는 Decision 단계 Task는 Layer/Stage와 무관하게 `docs/reference/architecture/00_OwnershipMap.md`를 Required Materials에 포함한다.

행 단위 수정 대신 표 아래 단서를 쓰는 이유: 같은 문장을 6개 행에 복제하면 `documentation-conventions` §1.5(중복 금지)에 어긋나고, 표와 본문이 따로 갱신되며 어긋나는 기존 문제가 재발한다. §12.1 표 바로 아래에는 이미 세 개 행을 한꺼번에 덮는 괄호 주석 선례가 있다.

**§12.4 (Task Manifest)** — 위 단서는 Layer/Stage가 아니라 Task 속성을 키로 삼으므로, 실제로 자료가 에이전트에게 도달하는 지점인 §12.4에도 명시한다. **문안은 §4.6(d)에 있다** — 여기에 중복해 싣지 않는다(초안 검토 중 이 자리에 옛 게이트 버전이 남아 §4.6(d)와 모순된 적이 있다).

### 4.6 Implementation 단계 판정 기준 + 맵의 검증자 (**이 제안의 두 번째 핵심**)

4.1~4.5는 맵을 만들고 전달하지만, **구현 단계에서 그걸 보고 무엇을 판정할지는 아무 데도 없다.** §4.2는 Decision 전용이고, §4.4의 Definition of Done은 PM용 목록이라 `Workflow_Project.md`가 §12.1 어느 행의 Required Materials에도 없어 Worker/Review는 읽지 않는다. 중복은 Decision이 아니라 Implementation에서 물리적으로 생성되므로 그 지점에 판정 기준이 없으면 §4.5가 닫으려던 구멍이 한 칸 아래에서 그대로 열린다.

기존 "Rule of Three"는 이 역할을 못 한다 — 임계값이 3이고(맵은 **두 번째** 복제를 막는 물건), Flutter·UI/Screen Implementation 전용이다.

**(a) `flutter-implementation-conventions` Review 체크리스트 Architecture 행에 항목명만 추가**

규칙 본문은 아래 (b)에 두고, 여기서는 체크리스트 표의 기존 형식(체크 셀은 짧게, 근거 열이 출처를 지목)대로 가리키기만 한다 — `Workflow_Frontend.md` §1이 UI/Screen Implementation에도 `engineering-principles`를 호출하게 하므로, 두 스킬에 같은 규칙을 전문으로 두면 별도 관리되는 두 파일이 어긋난다.

> 소유권 맵 준수 여부(규칙 본문은 `engineering-principles` 참고). 위반 시 P1.

**(b) `engineering-principles` 스킬에 프레임워크 무관 판정 추가**

Logic/Feature × Implementation과 Data/Architecture × Implementation은 `engineering-principles`를 쓰는데 그 스킬에는 소유권·중복에 관한 내용이 전혀 없다. Flutter 전용 스킬에만 넣으면 이 두 Layer는 사각지대로 남는다.

**목적지가 `Workflow_Development.md` §4가 아니라 이 스킬인 이유**: §12.1 Required Materials에서 `Workflow_Development.md`("Development workflow policy")를 받는 행은 UI/Screen × Implementation 하나뿐이고, 그 행은 이미 (a)가 커버한다. 정작 대상인 두 Layer의 Required Materials에는 `engineering-principles`만 있다. §4에 넣으면 기준이 자기 청중에게 도달하지 않는 문서에 실리게 되고, 그건 §4.5가 닫은 것과 같은 결함이다.

> 소유권 맵(`docs/reference/architecture/00_OwnershipMap.md`)에 등재된 동작·컴포넌트를 그 소유 파일을 경유하지 않고 로컬로 재구현했으면 P1. 문서화된 의도적 예외(맵 비고에 근거 문서가 적힌 경우)는 제외한다.
>
> 소유 파일이 **미정**인 행은 P1 대상이 아니다 — 경유할 파일이 아직 없어 준수 가능한 경로가 존재하지 않는다. 대신 그 행에 구현을 하나 더 추가한다는 사실을 PM에게 보고하고, PM이 통합 Task를 앞당길지 복제를 의식적으로 수용할지 판단한다. 이 조항이 없으면 이 제안의 동기가 된 삭제 절차(소유 파일 미정) 자체가 판정 불가 상태로 남는다.

**(c) `flutter-implementation-conventions` Audit 체크리스트에 대조 항목 추가**

> - 소유권 맵의 각 행이 실제 코드와 일치하는지(소유 파일 존재 여부, 등재 기준인 "둘 이상의 호출부"를 여전히 만족하는지, 맵에 없는 새 크로스커팅 항목이 생겼는지)

이 항목이 **맵의 유일한 주기적 검증자**다. (a)/(b)는 변경을 만든 당사자의 자기 점검이라, 그것만으로는 맵이 코드와 어긋나도 아무도 발견하지 못한다. Audit은 이미 이 체크리스트를 읽으므로 한계비용이 거의 없다. 이 초안의 1차 시딩에서 7행 중 2행이 틀렸던 만큼, 노후화는 가설이 아니라 실증된 위험이다.

**(c)를 실제로 가능하게 하려면**: Audit에게도 맵이 전달돼야 한다. `.claude/agents/audit.md`의 수령 자료 목록에 `docs/reference/architecture/00_OwnershipMap.md`를 추가한다 — §4.5의 단서는 Worker/Review의 Task Manifest를 대상으로 하므로 Audit은 그 경로로 받지 못한다.

**(d) 전달 게이트 조정 — 맵은 모든 Implementation Task에 상시 전달한다**

(a)/(b)의 판정 기준에는 크기 게이트가 없으므로 모든 Implementation Review에 적용된다. 초안의 §4.5는 게이트에 해당하는 Task에만 맵을 전달했다 — S/M Task의 Review는 기준만 있고 파일이 없는 상태가 된다. 그리고 그 S/M 경로가 바로 **기존 공유 동작에 호출부를 하나 더 붙이는**, 빈도가 가장 높은 중복 경로다(§4.4의 DoD는 "소유 파일이 바뀐 경우"에만 발동하므로 7번째 복제에는 걸리지 않는다).

따라서 Task Manifest 규정을 다음으로 확정했다.

> PM은 **모든 Implementation 단계 Task**의 Task Manifest에 `docs/reference/architecture/00_OwnershipMap.md`를 **Read**로 포함한다(표 1개짜리 문서라 디스패치당 비용이 작다). 맵을 갱신해야 하는 Task에서는 **Edit**으로 포함한다. Decision 단계에서는 게이트(Task 크기 L/XL, 또는 명세가 한 동작에 대해 2개 이상의 화면·진입점을 명시)에 해당할 때 포함한다.

이렇게 하면 게이트는 Decision 단계의 **작성 의무**만 판정하고, **맵 전달**은 게이트에서 분리된다 — 맵 전달 여부에 대한 Task별 PM 판단이 사라진다.

## 5. 초기 소유권 맵 시딩

**시딩 규칙(이 절의 가장 중요한 부분)**: 모든 행의 소유 파일과 등재 자격은 **grep으로 확인해서만** 정한다(§2.1 규칙과 동일 — 여기 다시 적는 것은 아래 실패 사례와 짝지어 읽히게 하기 위함이다). 설계 문서나 명세의 열거를 근거로 삼지 않는다. 이 초안의 1차 시딩이 정확히 그 실수로 두 행을 틀렸다 — `2026-07-21-multi-select-and-trash-design.md` §6이 메인 4화면을 재작성 대상으로 나열한 것을 보고 "다중선택 = 4화면"으로 적었으나, 휴지통은 의도적으로 그 공용 셸을 쓰지 않는다. 커밋 `257601b`이 하루 전에 금지한 바로 그 패턴이다.

아래 표는 전부 grep 재확인(2026-08-15)을 거쳤다.

| 항목 | 소유 파일 | 비고 |
| --- | --- | --- |
| 삭제 절차(확인→소프트삭제→피드백→되돌리기) | **미정** — 현재 6곳 복제 | 통합 Task가 소유 파일을 결정(BACKLOG P2). 행을 유지해 미해결임을 드러낸다 |
| 소프트삭제/복원/영구삭제 상태변경 — 옷장 | `lib/providers/closet_providers.dart` | 3개 도메인 구현이 변수명만 다른 복붙이라 제네릭화 후보(BACKLOG P2). 제네릭화하면 3행이 1행이 된다 |
| 소프트삭제/복원/영구삭제 상태변경 — 코디 | `lib/providers/composition_providers.dart` | |
| 소프트삭제/복원/영구삭제 상태변경 — 스타일일지 | `lib/providers/style_log_providers.dart` | |
| 삭제된 옷 포함 판정(§13.4 공유 술어) | `lib/providers/composition_providers.dart` | `00_DataSchema.md` §13.4가 "단일 정본, 두 정의로 갈라지지 않을 것"을 명시. 소비자: 코디 그리드/타일(연결끊김 배지), 편집 진입 가드 |
| 커버 이미지 렌더링(에셋/로컬파일 분기) | `lib/widgets/composition_cover_image.dart` | |
| 정적 아트보드 렌더링 | `lib/widgets/interactive_artboard/static_artboard.dart` | 코디 상세 + 스냅샷 캡처. **BACKLOG P1(코디 상세를 스냅샷 표시로 전환)이 착수되면 1곳으로 줄어 등재 기준에서 빠진다 — 그 Task가 이 행을 제거할 것** |
| Glass 셸 화면의 Toast + 실행취소 | `lib/widgets/glass_toast.dart` | Utility 셸용 `undoable_action_toast.dart`는 현재 설정 로그아웃 1곳에서만 쓰여 등재 기준 미달이나, **의도적 공존이며 통합 대상이 아니다**(`glass_toast.dart` 8-13행 + `2026-07-21-multi-select-and-trash-design.md` §5) |
| 다중선택 모드 | `lib/widgets/gallery_main_screen.dart` | 옷장/코디/스타일일지 메인에서 사용. **휴지통은 의도적으로 이 셸을 쓰지 않고 로컬 구현**(`trash_main_screen.dart` 25-28행 독스트링 + plan Task 10) — 문서화된 예외 |
| 메인 셸 | `lib/widgets/app_main_scaffold.dart` | |
| 상세 셸 | `lib/screens/app_detail_scaffold.dart` | 같은 역할의 메인 셸이 `lib/widgets/`인데 이것만 `lib/screens/`에 있음(BACKLOG P2 이동 후보) |
| 스크롤 컨테이너 | `lib/widgets/app_scroll_container.dart` | |
| 갤러리 그리드 | `lib/widgets/app_gallery_grid.dart` | |
| 에디터 헤더(크롬) | `lib/widgets/editor_header.dart` | 옷 추가/코디 편집/스타일일지 추가 — 3도메인. `TechnicalDebt.md`에 Glass primitive 미사용·Pinned Rule 적용 미확정으로 이미 등록된 항목 |
| 분류 그룹 그리드 | `lib/widgets/classification_group_grid.dart` | 옷장·코디 메인 공유 |
| 스타일일지 크로스레퍼런스 갤러리 | `lib/widgets/style_log_cross_reference_gallery.dart` | 옷 상세·코디 상세 공유 |
| 메인 헤더 선택 액션(크롬) | `lib/widgets/selection_aware_header_actions.dart` | 메인 3화면 공유 |
| 추가 FAB(크롬) | `lib/widgets/expandable_add_fab.dart` | 옷장·스타일일지 메인 공유. 경계선 사례지만 화면이 로컬 재구현할 수 있는 크롬이라 포함 |

**제외한 것과 이유(전부 grep 확인)**

- 스냅샷 캡처·저장: 코디 편집기 1개 화면(`composition_editor_providers.dart`/`composition_editor_screen.dart`)이다. 2파일 중복은 실재하나 크로스커팅이 아니다.
- `InteractiveArtboard`: `composition_editor_screen.dart` 1곳에서만 쓰인다.
- `UndoableActionToast`: `settings_screen.dart` 1곳에서만 쓰인다(위 Glass Toast 행 비고 참고).
- 연결 바텀시트: 아직 구현되지 않아 소유 파일이 존재하지 않는다 — "소유 예정 위치"를 적는 것은 추측이다.
- `composition_preview_card.dart`: 커버 이미지 렌더링 행의 **소비자**라 그 행으로 이미 커버된다(커밋 `80f7e1a`가 이 파일의 미경유를 고친 사례). 소비자를 별도 행으로 올리면 표가 호출부 목록으로 변질된다.
- `artboard_item.dart`: 데이터 클래스(위 모델 제외 규칙).

**"전수 파악 완료"라고 주장하지 않는다.** 위 표는 이번 감사와 grep으로 확인된 범위이며, 누락이 있을 수 있다. 누락된 항목을 발견한 Task가 그때 추가한다.

## 6. 한계 (의도적으로 수용)

- 명세가 진입점을 **명시적으로 열거한** 경우에만 게이트가 걸린다. 암묵적으로만 시사되는 공통 동작은 놓친다.
- **`coverImagePath` 호출부 누락 계열은 이 제안이 막지 못한다.** 그 실패는 손으로 쓴 호출부 목록이 불완전해서 생겼고, 해법은 grep 기준선(`flutter-implementation-conventions`, 커밋 `257601b`)이다. 이 맵은 "누가 소유하는가"만 답한다.
- 프레임워크 함정 계열(빌드 중 `setState`, 이미지 디코드 타이밍)에는 효과가 없다 — `flutter-implementation-conventions`의 규칙과 TechDebt 승격 게이트가 담당한다.
- 등재 범위를 크로스커팅으로 좁혔으므로 단일 화면 내부의 구조 품질은 보장하지 않는다.
- **도메인당 정확히 1파일씩 복제된 중복은 이 맵에 안 잡힌다.** §2.1의 도메인 분할 규칙이 그런 행을 각각 "정확히 1개"로 만들어 통과시키기 때문이다. 소프트삭제 3행이 바로 그 상태다 — 비고에 "변수명만 다른 복붙"이라 적혀 있는데도 규칙상으로는 green이다. 이 코드베이스의 지배적 중복 형태가 3도메인 복제라 실질적인 사각지대다. **맵이 깨끗하다는 것을 "중복이 없다"의 근거로 인용하지 말 것.**
- 맵의 정확성은 §4.6(c)의 Audit 대조에만 의존한다. Audit이 도는 주기(L/XL 완료 시점, Decision 확정 시점) 사이에는 코드와 어긋난 채로 남아 있을 수 있다.
