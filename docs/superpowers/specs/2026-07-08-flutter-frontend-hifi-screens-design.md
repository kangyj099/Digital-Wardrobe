# Flutter 프론트엔드 Hi-Fi 화면 10개 (2일 스프린트) — 설계

Date: 2026-07-08
Status: Approved (design), pending implementation plan
Deadline: 2026-07-10 (2일, 하루 8~10시간)

## 배경

사용자가 프론트엔드 개발 경험 없이, 기존 Digital Wardrobe 기획/디자인 문서(UX/Interaction/Layout/Accessibility Principles, Design Tokens 역할, Component Strategy C1~C12 — 전부 `docs/knowledge/reference/design/00_DesignPrinciples.md`에 이미 정의됨)를 실제 Flutter 화면으로 만들고 싶어함. 목적은 BACKLOG.md의 "Next: Hi-Fi Sample 제작" 단계를 실제로 수행하는 것과 사실상 동일.

기존 문서는 설계(무엇을 어떻게 만들지)는 Stage 6까지 끝나있지만, **실제 값**(Design Tokens Stage 5의 색상 외 나머지, Typography Pass 3)은 비어있고, 코드(`lib/`)는 기본 카운터 데모 스켈레톤뿐. 참고 목업은 `참고자료/`(gitignore 대상, 레퍼런스 전용)에 와이어프레임 3종 + 신규 목업(`참고자료/목업/`)이 있음.

## 스코프

**UI만 — 실제 Firebase/Remove.bg/Claude Vision 연동 없음, mock 데이터로만 동작.**

### 화면 10개 (빌드 순서 = 우선순위, 시간 부족 시 아래쪽부터 자름)

| # | 화면 | Page Type | 비고 |
|---|---|---|---|
| 1 | 옷장 메인 | Main(Grouped) | |
| 2 | 스타일일지 (열람) | Detail | |
| 3 | 코디 만들기 (에디터) | Add/Create | **정적 레이아웃만 — 드래그/회전/크기조절/z-index 로직 없음** |
| 4 | 옷 상세 | Detail | |
| 5 | 옷 추가하기 | Add/Create | AI 처리 단계는 정적 상태 표시만(실제 API 호출 없음) |
| 6 | 코디 상세 | Detail | |
| 7 | 설정/휴지통 | Utility + Main(Flat+Filter) | |
| 8 | 코디 메인 | Main(Grouped) | |
| 9 | 스타일일지 메인 | Main(Flat+Filter) | |
| 10 | 스타일일지 추가 | Add/Create | |

4~10번은 서로 순서 무관.

### 인터랙션 수준

- 코디 에디터의 캔버스 제스처(드래그/회전/크기조절/z-index)와 실제 AI 처리(배경제거/자동태깅)만 제외.
- 그 외(필터, 화면 간 네비게이션, 상세↔상세 크로스링크, 선택 모달 등)는 실제로 동작.

### 다크모드

색상 토큰은 Light/Dark 둘 다 정의하되, 이번 스프린트는 **Light UI만 실제로 빌드/검증**. 다크모드는 나중에 `ThemeMode` 연결만 하면 되는 상태로 준비.

### 이미지

- 옷/코디 샘플 사진: 사용자가 준비해서 `assets/images/mock/`에 제공.
- 기존 참고 목업(`참고자료/목업/` 등): gitignore 대상, 레퍼런스 전용, 앱에 번들되지 않음.

## 아키텍처

### 패키지 추가

- `flutter_riverpod` — 상태관리 (아래 "왜 Riverpod인가" 참고)
- `go_router` — 네비게이션 (`00_MVP.md` §6에 기존 기술 스택으로 이미 결정됨)

### 폰트

- Body: KoPub돋움 — 라이선스 확인 완료(상업적 사용 가능, 폰트 자체 재판매/수정만 금지). `resources/license/서체_라이선스.pdf` 참고.
- Display/Title/Label: Pretendard — 오픈소스(OFL).
- **실제 폰트 파일(.ttf)은 아직 저장소에 없음** — 구현 착수 전 확보해서 `assets/fonts/`에 배치, `pubspec.yaml` 등록 필요.

### 폴더 구조

```
lib/
  theme/      # 토큰 + ThemeData (ColorScheme: T1~T3 색상 / ThemeExtension: T4~T8)
  models/     # ClothingItem, Composition, StyleLog (00_MVP.md §5에서 백엔드 전용 필드 제외)
  providers/  # Riverpod provider — mock 데이터 + UI 상태(필터/선택 등)
  widgets/    # 재사용 컴포넌트 (Component Strategy C1~C12 매핑)
  screens/    # 화면 10개
  router/     # go_router 라우트 설정
```

### 왜 Riverpod인가 (Provider 대신)

Interaction Principles I7(AI 처리 → 재시도 → 실패 팝업 계약)이 이미 비동기 상태 패턴을 요구하고, 향후 실제 Firestore 스트림/Remove.bg/Claude Vision 연동이 예정돼 있음. Riverpod의 `AsyncValue`/`FutureProvider`/`StreamProvider`가 이 패턴에 직접 대응됨. Provider로 시작해서 나중에 Riverpod로 옮기는 건 화면마다 상태 구독 배선을 다시 손대야 하는 실질적 리팩터링이라, 처음부터 Riverpod로 가는 게 이후 재작업을 피함.

## 디자인 토큰 (임시 확정값 — Brand Guide Pass 3 정식 확정 전까지)

- **색상**: Brand Guide Pass 2(T1~T3) 값을 그대로 Flutter `ColorScheme`에 매핑. Light/Dark 세트 둘 다 정의(위 스코프 참고, Dark는 미검증).
- **Typography**: Material 3 기본 type scale 크기 채택 — Display 57/45/36, Headline 32/28/24, Title 22/16/14, Body 16/14/12, Label 14/12/11. Body 역할 → KoPub돋움, 나머지 → Pretendard.
- **Spacing**: `xxs=4, xs=8, sm=12, md=16, lg=24, xl=32` + 컴포넌트 전용 토큰 `Spacing.galleryGap=1`(갤러리 그리드 타일 간격 전용, 하드코딩 아님 — 명명된 토큰).
- **Density** (Grouped Main 그리드 전용: 옷장/코디): `Density.min/mid/max = 1/3/5`열.
- **Elevation/Motion**: 오버레이 헤더는 블러+옅은 그림자 1단계만, 기본 트랜지션 200ms. Reduced-motion 변형은 이번 스프린트에서 실제 적용/검증하지 않음(토큰 역할 자체는 존재).
- 모든 값은 코드에서 `Theme.of(context)...` 또는 named 상수로만 참조 — 화면 코드에 매직넘버/헥스값 직접 기입 금지. Brand Guide Pass 3가 정식 확정되면 이 토큰 정의만 교체(기존 Decision.md "Brand Guide 선행 없이 임시 토큰 값으로 Design System 착수" 결정과 동일한 방식).

## 컴포넌트 ↔ 화면 매핑

| # | 화면 | 주요 컴포넌트 |
|---|---|---|
| 1 | 옷장 메인 | C2 GroupedGalleryGrid, C1 SelectableGalleryTile, C4 OverlayHeader, C12 StatusBadge |
| 2 | 스타일일지 (열람) | C10 SequentialSlotCard (커버→코디→추가이미지 스와이프) |
| 3 | 코디 만들기 | C5 ArtboardCanvas+ArtboardItem (정적 레이아웃만) |
| 4 | 옷 상세 | C4 OverlayHeader, 이력 리스트(C1 변형) |
| 5 | 옷 추가하기 | C9 AiProcessingStatus (정적 상태만), 태그 폼 |
| 6 | 코디 상세 | 사용 아이템 리스트, 연결된 스타일일지 |
| 7 | 설정/휴지통 | C3 FlatFilterGallery, C11 DestructiveConfirmModal |
| 8 | 코디 메인 | 1번과 동일 컴포넌트 재사용 |
| 9 | 스타일일지 메인 | C3 FlatFilterGallery |
| 10 | 스타일일지 추가 | C6 BindingSelectionModal(옷장 재사용), 카드 구조 |

## 데이터/상태

- Mock 모델: `00_MVP.md` §5 Data Model에서 서버 전용 필드(id, user_id, image_url 서버 경로 등) 제외한 `ClothingItem`/`Composition`/`StyleLog`. 앱 시작 시 하드코딩된 mock 리스트로 초기화.
- Riverpod provider를 화면/도메인 단위로 노출 (예: `closetItemsProvider`, `selectedSeasonFilterProvider`). 화면 간 데이터 공유(옷장에서 추가한 아이템이 코디 선택 모달에도 보이는 등)는 이 provider들을 통해서만 이뤄짐 — 화면 간 직접 데이터 전달 금지.

## 테스트/검증 방침

- 주 검증 수단: 화면 하나 만들 때마다 에뮬레이터/기기에서 실제 실행해 눈으로 확인 (위젯 단위 TDD 아님 — 이번 작업은 로직보다 화면/시각 요소가 핵심이라 낮은 ROI로 판단).
- 필터/정렬처럼 위젯이 아닌 순수 로직에는 짧은 단위 테스트 추가.

## 명시적으로 제외한 것

- 실제 Firebase/Remove.bg/Claude Vision 연동
- 코디 에디터의 드래그/회전/크기조절/z-index 인터랙션 로직
- 다크모드 UI 실제 연결/검증 (토큰만 준비)
- Brand Guide Pass 3 정식 확정 (여기 값은 전부 임시)

## 후속 조치 필요 (구현 착수 전 사용자 준비 필요)

- **사용자**가 Pretendard, KoPub돋움 실제 폰트 파일(.ttf)을 확보해 `assets/fonts/`에 배치 — PM/Worker는 라이선스 파일 위치(`assets/fonts/license/`)만 참고하고 폰트 바이너리 자체를 대신 내려받지 않음(라이선스 조건 준수 확인은 사용자가 이미 완료했으므로 실제 파일 배치도 사용자 쪽에서 진행).
- **사용자**가 옷/코디 샘플 사진을 `assets/images/mock/`에 제공.
- 위 두 가지가 준비되기 전까지 구현 플랜의 폰트/이미지 의존 태스크는 착수 보류.
