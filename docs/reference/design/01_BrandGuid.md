# Brand Guide (확정)

## 1. Brand Identity

**Essence**: 입어온 나를 돌아보는 기록

**Personality**: 든든한 개인 기록자

- 관계 거리감: 거래처 파트너 수준 — 편안하되 사적이지 않음
- 어조: 상냥함, 반말·애칭·과한 감탄사 없음
- 표현 방식: 응원형 대신 관찰형 문구 ("오늘 조합, 이번 계절 두 번째예요")
- 유틸리티 경로(옷장): 담백함 위주
- 성찰 경로(스타일 일지): 관찰형 문구 비중 소폭 증가

**Visual Direction**: 아이보리~베이지 배경, 블루 뉴트럴 우세, 딥 블루그레이로 무게감. 웜톤/핑크/포근한 인상 배제. Accent는 세이지그린 1색 허용.

---

## 2. Brand Colors

### T1. Color Roles

| Role | Light | On-Light | Dark | On-Dark |
| --- | --- | --- | --- | --- |
| Primary | `#394550` | `#F7F6F3` | `#93B5CC` | `#232B31` |
| Secondary / Accent | `#C5D3C7` | `#2B2D30` | `#8FA890` | `#232B31` |
| Surface | `#F7F6F3` | `#2B2D30` | `#2C3841` | `#EDE9E1` |
| Background | `#F7F6F3` | `#2B2D30` | `#1D262D` | `#EDE9E1` |
| Error | `#A34B50` | `#F7F6F3` | `#D98A8E` | `#1D262D` |

### T2. Neutral / Gray Scale

| Step | Hex |
| --- | --- |
| Gray50 | `#F7F6F3` |
| Gray100 | `#DDD4C8` |
| Gray200 | `#CBC0B0` |
| Gray300 | `#B3A99A` |
| Gray400 | `#948E86` |
| Gray500 | `#6E7679` |
| Gray600 | `#52606A` |
| Gray700 | `#3E4C56` |
| Gray800 | `#2C3841` |
| Gray900 | `#1D262D` |

### T3. Semantic State Colors

| Role | Light | Dark |
| --- | --- | --- |
| Disabled | Gray300 (`#B3A99A`) | Gray700 (`#3E4C56`) |
| Warning | `#B98A3D` | `#D9A05C` |
| Error | `#A34B50` | `#D98A8E` |
| Success / Info | Primary (`#394550`) | Primary Dark (`#93B5CC`) |

---

## 3. Typography

### Font Families (확정)

| 역할 | 폰트 |
| --- | --- |
| 전 역할(Body 포함) | Pretendard |

Body에 KoPub돋움을 쓰던 초기안은 옷장 메인 재설계 중 Pretendard로 단일화됨(`Decision.md` 참고) — KoPubDotum은 코드/`pubspec.yaml`에서 제거된 상태.

### Type Scale (확정)

하이파이 샘플(옷장/코디/스타일일지 메인) 육안 확인 후 Material 3 기본 스케일을 기준값으로 확정. 굵기는 전부 Pretendard.

| Role | Size | Weight |
| --- | --- | --- |
| displayLarge | 57 | w400 |
| displayMedium | 45 | w400 |
| displaySmall | 36 | w400 |
| headlineLarge | 32 | w600 |
| headlineMedium | 28 | w600 |
| headlineSmall | 24 | w600 |
| titleLarge | 22 | w600 |
| titleMedium | 16 | w600 |
| titleSmall | 14 | w600 |
| bodyLarge | 16 | w500 |
| bodyMedium | 14 | w500 |
| bodySmall | 12 | w500 |
| labelLarge | 14 | w500 |
| labelMedium | 12 | w500 |
| labelSmall (배지/태그) | 13 | w500 |
| actionMinimal (보조 액션 버튼 전용, 예: "선택") | 11 | w500 |

`actionMinimal`은 M3 기본 15-role에 없는 역할로, 앱 전체에서 가장 작은 텍스트가 되도록 별도 고정한 값(`labelSmall`이 배지/태그용으로 커지면서 생긴 자리를 재사용). 갤러리 타일 배지/태그는 눈에 잘 띄어야 해서 키우고, "선택" 같은 보조 액션 버튼은 최소 크기로 눌러 시각적 위계를 분리한다.

---

## 4. 미확정 항목

- T2 Gray 스케일 세부 단계 재보간
- Warning / Accent 조합 대비 전수 검증