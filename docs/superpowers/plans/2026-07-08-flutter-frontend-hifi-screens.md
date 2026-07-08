# Flutter Frontend Hi-Fi 화면 10개 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Digital Wardrobe MVP의 대표 화면 10개를, mock 데이터만으로 동작하는 실제 Flutter UI(재사용 컴포넌트 + 디자인 토큰 기반, 하드코딩 없음)로 구현한다.

**Architecture:** `flutter_riverpod`(상태) + `go_router`(내비게이션). `lib/theme/`에 색상(ColorScheme)·타이포·spacing·density 토큰을 정의하고 모든 위젯은 이 토큰만 참조한다. `lib/widgets/`에 Component Strategy(C1~C12) 기반 재사용 컴포넌트를, `lib/screens/`에 화면을 둔다. 코디 에디터의 제스처(드래그/회전/크기조절/z-index)와 실제 AI 처리는 이번 스코프에서 제외 — 정적 레이아웃/상태 표시만 구현.

**Tech Stack:** Flutter 3.44.4 / Dart 3.12.2, `flutter_riverpod`, `go_router`, Pretendard + KoPub돋움 폰트(사용자가 `assets/fonts/`에 배치).

## Global Constraints

- 색상/폰트/spacing/density 실제 값은 `docs/superpowers/specs/2026-07-08-flutter-frontend-hifi-screens-design.md`의 "디자인 토큰(임시 확정값)" 섹션 값을 그대로 사용 — 화면 코드에 색상 hex나 픽셀 숫자를 직접 쓰지 않는다. 전부 `Theme.of(context)` 또는 `lib/theme/` 상수 참조.
- Spacing: `xxs=4, xs=8, sm=12, md=16, lg=24, xl=32`, `galleryGap=1`.
- Density(Grouped Main 전용): `min=1, mid=3, max=5`열.
- Typography 크기: Display 57/45/36, Headline 32/28/24, Title 22/16/14, Body 16/14/12, Label 14/12/11. Body 계열 폰트 = `KoPubDotum`, 나머지 = `Pretendard`.
- 색상(Light): Primary `#394550`/OnPrimary `#F7F6F3`, Secondary `#C5D3C7`/OnSecondary `#2B2D30`, Surface `#F7F6F3`/OnSurface `#2B2D30`, Background `#F7F6F3`/OnBackground `#2B2D30`, Error `#A34B50`/OnError `#F7F6F3`. Gray50~900: `#F7F6F3 #DDD4C8 #CBC0B0 #B3A99A #948E86 #6E7679 #52606A #3E4C56 #2C3841 #1D262D`. Warning `#B98A3D`, Success `#394550`(Primary와 동일).
- 색상(Dark): Primary `#93B5CC`/OnPrimary `#232B31`, Secondary `#8FA890`/OnSecondary `#232B31`, Surface `#2C3841`/OnSurface `#EDE9E1`, Background `#1D262D`/OnBackground `#EDE9E1`, Error `#D98A8E`/OnError `#1D262D`. Warning `#D9A05C`, Success `#93B5CC`.
- 코디 에디터 화면(Task 8)은 드래그/회전/크기조절/z-index 로직을 구현하지 않는다 — 정적 배치만 표시.
- `옷 추가하기`(Task 10)의 AI 처리 단계는 실제 API 호출 없이 고정된 성공 상태만 표시한다.
- 폰트 파일은 사용자가 아래 정확한 파일명으로 `assets/fonts/`에 직접 배치한다 (PM/Worker가 대신 다운로드하지 않음):
  - `assets/fonts/Pretendard-Regular.otf`, `Pretendard-Medium.otf`, `Pretendard-SemiBold.otf`, `Pretendard-Bold.otf`
  - `assets/fonts/KoPubDotum-Medium.ttf`, `KoPubDotum-Bold.ttf`
- 옷/코디 샘플 이미지는 사용자가 `assets/images/mock/`에 배치한다. 파일명 규칙: `item_01.jpg` ~ `item_12.jpg` (Task 3의 mock 데이터가 이 이름을 참조).
- 테스트 방침: 화면/위젯은 `flutter run`으로 직접 확인(위젯 단위 TDD 아님). 순수 로직(필터/정렬 함수)에는 `flutter test`로 단위 테스트 작성.

---

### Task 1: 프로젝트 셋업 (패키지, 에셋 등록)

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:** 없음 (다른 Task가 의존하는 설정 파일 변경만)

- [ ] **Step 1: 패키지 추가**

```bash
flutter pub add flutter_riverpod go_router
```

Expected: `pubspec.yaml`의 `dependencies`에 `flutter_riverpod`, `go_router`가 자동으로 추가됨 (버전은 pub.dev 최신 호환 버전으로 자동 선택).

- [ ] **Step 2: 에셋 폴더 확인**

```bash
ls assets/fonts/ assets/images/mock/
```

Expected: `assets/fonts/`에 `Pretendard-Regular.otf`, `Pretendard-Medium.otf`, `Pretendard-SemiBold.otf`, `Pretendard-Bold.otf`, `KoPubDotum-Medium.ttf`, `KoPubDotum-Bold.ttf` 6개 파일. `assets/images/mock/`에 `item_01.jpg` ~ `item_12.jpg`.

**만약 파일이 없다면**: 이 Task를 여기서 멈추고 PM에게 보고한다 — Global Constraints에 명시된 대로 사용자가 직접 배치해야 하는 파일이라 Worker가 대신 만들 수 없다.

- [ ] **Step 3: `pubspec.yaml`의 `flutter:` 섹션에 assets/fonts 등록**

`pubspec.yaml`의 `flutter:` 섹션(현재 `uses-material-design: true`만 있는 상태)을 다음으로 교체:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/mock/

  fonts:
    - family: Pretendard
      fonts:
        - asset: assets/fonts/Pretendard-Regular.otf
        - asset: assets/fonts/Pretendard-Medium.otf
          weight: 500
        - asset: assets/fonts/Pretendard-SemiBold.otf
          weight: 600
        - asset: assets/fonts/Pretendard-Bold.otf
          weight: 700
    - family: KoPubDotum
      fonts:
        - asset: assets/fonts/KoPubDotum-Medium.ttf
        - asset: assets/fonts/KoPubDotum-Bold.ttf
          weight: 700
```

- [ ] **Step 4: 빌드 확인**

```bash
flutter pub get
```

Expected: 에러 없이 완료. 폰트 파일이 없으면 `Error: unable to find asset...` 에러 발생 — 그 경우 Step 2로 돌아가 사용자에게 파일 배치를 요청.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml
git commit -m "chore: add flutter_riverpod, go_router; register fonts and mock image assets"
```

---

### Task 2: 디자인 토큰 (색상/타이포/spacing/density)

**Files:**
- Create: `lib/theme/app_colors.dart`
- Create: `lib/theme/app_spacing.dart`
- Create: `lib/theme/app_typography.dart`
- Create: `lib/theme/app_theme.dart`

**Interfaces:**
- Produces: `AppTheme.light`, `AppTheme.dark` (둘 다 `ThemeData`) — Task 4(`main.dart`)가 소비. `AppSpacing`, `AppDensity`(둘 다 `lib/theme/app_spacing.dart`의 static const 필드들 — `AppDensity`도 이 파일에 있음, 별도 `app_density.dart` 파일 없음) — 이후 모든 화면/컴포넌트 Task가 `AppSpacing.md`처럼 직접 참조. `AppSemanticColors`(ThemeExtension, `warning`/`success`/`gray50`~`gray900` 필드) — `Theme.of(context).extension<AppSemanticColors>()!`로 접근.

- [ ] **Step 1: `lib/theme/app_colors.dart` 작성**

```dart
import 'package:flutter/material.dart';

/// Brand Guide Pass 2(T1~T3) 값을 Material 3 ColorScheme으로 매핑.
/// 값 자체는 임시 확정값 — Brand Guide Pass 3 정식 확정 시 이 파일만 교체.
class AppColors {
  AppColors._();

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF394550),
    onPrimary: Color(0xFFF7F6F3),
    secondary: Color(0xFFC5D3C7),
    onSecondary: Color(0xFF2B2D30),
    surface: Color(0xFFF7F6F3),
    onSurface: Color(0xFF2B2D30),
    error: Color(0xFFA34B50),
    onError: Color(0xFFF7F6F3),
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF93B5CC),
    onPrimary: Color(0xFF232B31),
    secondary: Color(0xFF8FA890),
    onSecondary: Color(0xFF232B31),
    surface: Color(0xFF2C3841),
    onSurface: Color(0xFFEDE9E1),
    error: Color(0xFFD98A8E),
    onError: Color(0xFF1D262D),
  );
}

/// T2(Neutral Gray) + T3(Semantic State) 역할 — Material 3 ColorScheme에
/// 없는 역할이라 ThemeExtension으로 별도 정의.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.gray50,
    required this.gray100,
    required this.gray200,
    required this.gray300,
    required this.gray400,
    required this.gray500,
    required this.gray600,
    required this.gray700,
    required this.gray800,
    required this.gray900,
    required this.warning,
    required this.success,
  });

  final Color gray50;
  final Color gray100;
  final Color gray200;
  final Color gray300;
  final Color gray400;
  final Color gray500;
  final Color gray600;
  final Color gray700;
  final Color gray800;
  final Color gray900;
  final Color warning;
  final Color success;

  static const light = AppSemanticColors(
    gray50: Color(0xFFF7F6F3),
    gray100: Color(0xFFDDD4C8),
    gray200: Color(0xFFCBC0B0),
    gray300: Color(0xFFB3A99A),
    gray400: Color(0xFF948E86),
    gray500: Color(0xFF6E7679),
    gray600: Color(0xFF52606A),
    gray700: Color(0xFF3E4C56),
    gray800: Color(0xFF2C3841),
    gray900: Color(0xFF1D262D),
    warning: Color(0xFFB98A3D),
    success: Color(0xFF394550),
  );

  static const dark = AppSemanticColors(
    gray50: Color(0xFFF7F6F3),
    gray100: Color(0xFFDDD4C8),
    gray200: Color(0xFFCBC0B0),
    gray300: Color(0xFFB3A99A),
    gray400: Color(0xFF948E86),
    gray500: Color(0xFF6E7679),
    gray600: Color(0xFF52606A),
    gray700: Color(0xFF3E4C56),
    gray800: Color(0xFF2C3841),
    gray900: Color(0xFF1D262D),
    warning: Color(0xFFD9A05C),
    success: Color(0xFF93B5CC),
  );

  @override
  AppSemanticColors copyWith({
    Color? gray50,
    Color? gray100,
    Color? gray200,
    Color? gray300,
    Color? gray400,
    Color? gray500,
    Color? gray600,
    Color? gray700,
    Color? gray800,
    Color? gray900,
    Color? warning,
    Color? success,
  }) {
    return AppSemanticColors(
      gray50: gray50 ?? this.gray50,
      gray100: gray100 ?? this.gray100,
      gray200: gray200 ?? this.gray200,
      gray300: gray300 ?? this.gray300,
      gray400: gray400 ?? this.gray400,
      gray500: gray500 ?? this.gray500,
      gray600: gray600 ?? this.gray600,
      gray700: gray700 ?? this.gray700,
      gray800: gray800 ?? this.gray800,
      gray900: gray900 ?? this.gray900,
      warning: warning ?? this.warning,
      success: success ?? this.success,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      gray50: Color.lerp(gray50, other.gray50, t)!,
      gray100: Color.lerp(gray100, other.gray100, t)!,
      gray200: Color.lerp(gray200, other.gray200, t)!,
      gray300: Color.lerp(gray300, other.gray300, t)!,
      gray400: Color.lerp(gray400, other.gray400, t)!,
      gray500: Color.lerp(gray500, other.gray500, t)!,
      gray600: Color.lerp(gray600, other.gray600, t)!,
      gray700: Color.lerp(gray700, other.gray700, t)!,
      gray800: Color.lerp(gray800, other.gray800, t)!,
      gray900: Color.lerp(gray900, other.gray900, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
```

- [ ] **Step 2: `lib/theme/app_spacing.dart` 작성**

```dart
/// T5(Spacing Scale) + 갤러리 그리드 전용 gap 토큰.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// GroupedGalleryGrid(C2) 타일 간 간격 전용 — 다른 곳에서 재사용 금지.
  static const double galleryGap = 1;
}

/// T6(Density) — Grouped Main 그리드(옷장/코디) 전용 열 개수.
class AppDensity {
  AppDensity._();

  static const int min = 1;
  static const int mid = 3;
  static const int max = 5;

  static const List<int> levels = [min, mid, max];
}
```

- [ ] **Step 3: `lib/theme/app_typography.dart` 작성**

```dart
import 'package:flutter/material.dart';

/// T4(Typography Roles) — Material 3 기본 type scale 크기 채택.
/// Body 계열 = KoPubDotum, 나머지(Display/Headline/Title/Label) = Pretendard.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color onSurface) {
    const pretendard = 'Pretendard';
    const koPub = 'KoPubDotum';

    TextStyle style(String family, double size, FontWeight weight) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        color: onSurface,
      );
    }

    return TextTheme(
      displayLarge: style(pretendard, 57, FontWeight.w400),
      displayMedium: style(pretendard, 45, FontWeight.w400),
      displaySmall: style(pretendard, 36, FontWeight.w400),
      headlineLarge: style(pretendard, 32, FontWeight.w600),
      headlineMedium: style(pretendard, 28, FontWeight.w600),
      headlineSmall: style(pretendard, 24, FontWeight.w600),
      titleLarge: style(pretendard, 22, FontWeight.w600),
      titleMedium: style(pretendard, 16, FontWeight.w600),
      titleSmall: style(pretendard, 14, FontWeight.w600),
      bodyLarge: style(koPub, 16, FontWeight.w400),
      bodyMedium: style(koPub, 14, FontWeight.w400),
      bodySmall: style(koPub, 12, FontWeight.w400),
      labelLarge: style(pretendard, 14, FontWeight.w500),
      labelMedium: style(pretendard, 12, FontWeight.w500),
      labelSmall: style(pretendard, 11, FontWeight.w500),
    );
  }
}
```

- [ ] **Step 4: `lib/theme/app_theme.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, AppSemanticColors.light);
  static ThemeData get dark => _build(AppColors.dark, AppSemanticColors.dark);

  static ThemeData _build(ColorScheme colorScheme, AppSemanticColors semantic) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: AppTypography.textTheme(colorScheme.onSurface),
      extensions: [semantic],
    );
  }
}
```

- [ ] **Step 5: 컴파일 확인**

```bash
flutter analyze lib/theme/
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/theme/
git commit -m "feat(theme): add color/typography/spacing/density design tokens"
```

---

### Task 3: Mock 데이터 모델 + 초기 데이터

**Files:**
- Create: `lib/models/clothing_item.dart`
- Create: `lib/models/composition.dart`
- Create: `lib/models/style_log.dart`
- Create: `lib/mock/mock_data.dart`
- Test: `test/mock/mock_data_test.dart`

**Interfaces:**
- Produces: `ClothingItem`(필드: `id, name, category, color, season, location, memo, imagePath, wearCount, isIncomplete, isDeleted`), `Composition`(필드: `id, name, backgroundColor, items: List<CompositionItemPlacement>, season, isDeleted`), `CompositionItemPlacement`(필드: `clothingItemId, x, y, scale, rotation, zIndex`), `StyleLog`(필드: `id, coverImagePath, linkedCompositionId, additionalImagePaths, wornDate, location, isDeleted`) — 이후 모든 Task가 소비. `mockClothingItems`, `mockCompositions`, `mockStyleLogs`(각 `List<...>`) — Task 4 provider가 소비.

- [ ] **Step 1: `lib/models/clothing_item.dart` 작성**

```dart
class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.season,
    required this.imagePath,
    this.location = '',
    this.memo = '',
    this.wearCount = 0,
    this.isIncomplete = false,
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final String category;
  final String color;
  final String season;
  final String imagePath;
  final String location;
  final String memo;
  final int wearCount;
  final bool isIncomplete;
  final bool isDeleted;
}
```

- [ ] **Step 2: `lib/models/composition.dart` 작성**

```dart
class CompositionItemPlacement {
  const CompositionItemPlacement({
    required this.clothingItemId,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
  });

  final String clothingItemId;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int zIndex;
}

class Composition {
  const Composition({
    required this.id,
    required this.name,
    required this.items,
    this.season = '',
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final List<CompositionItemPlacement> items;
  final String season;
  final bool isDeleted;
}
```

- [ ] **Step 3: `lib/models/style_log.dart` 작성**

```dart
class StyleLog {
  const StyleLog({
    required this.id,
    required this.coverImagePath,
    required this.wornDate,
    this.linkedCompositionId,
    this.additionalImagePaths = const [],
    this.location = '',
    this.isDeleted = false,
  });

  final String id;
  final String coverImagePath;
  final DateTime wornDate;
  final String? linkedCompositionId;
  final List<String> additionalImagePaths;
  final String location;
  final bool isDeleted;
}
```

- [ ] **Step 4: `lib/mock/mock_data.dart` 작성 (12개 아이템 — 12번은 미완성 상태로)**

```dart
import '../models/clothing_item.dart';
import '../models/composition.dart';
import '../models/style_log.dart';

final List<ClothingItem> mockClothingItems = [
  const ClothingItem(id: 'c01', name: 'padding jacket', category: 'outer', color: 'navy', season: '겨울', imagePath: 'assets/images/mock/item_01.jpg', location: '옷장 1단', wearCount: 5),
  const ClothingItem(id: 'c02', name: 'long coat', category: 'outer', color: 'beige', season: '겨울', imagePath: 'assets/images/mock/item_02.jpg', location: '옷장 1단', wearCount: 2),
  const ClothingItem(id: 'c03', name: 'knit', category: 'top', color: 'ivory', season: '겨울', imagePath: 'assets/images/mock/item_03.jpg', wearCount: 8),
  const ClothingItem(id: 'c04', name: 'scarf', category: 'accessory', color: 'gray', season: '겨울', imagePath: 'assets/images/mock/item_04.jpg', wearCount: 1),
  const ClothingItem(id: 'c05', name: 'gloves', category: 'accessory', color: 'black', season: '겨울', imagePath: 'assets/images/mock/item_05.jpg', wearCount: 0),
  const ClothingItem(id: 'c06', name: 'fleece pants', category: 'bottom', color: 'gray', season: '겨울', imagePath: 'assets/images/mock/item_06.jpg', isIncomplete: true),
  const ClothingItem(id: 'c07', name: 'boots', category: 'shoes', color: 'brown', season: '겨울', imagePath: 'assets/images/mock/item_07.jpg', wearCount: 3),
  const ClothingItem(id: 'c08', name: 'cardigan', category: 'top', color: 'camel', season: '겨울', imagePath: 'assets/images/mock/item_08.jpg', wearCount: 4),
  const ClothingItem(id: 'c09', name: 'beanie', category: 'accessory', color: 'black', season: '겨울', imagePath: 'assets/images/mock/item_09.jpg', wearCount: 2),
  const ClothingItem(id: 'c10', name: 'wool socks', category: 'accessory', color: 'gray', season: '겨울', imagePath: 'assets/images/mock/item_10.jpg', wearCount: 6),
  const ClothingItem(id: 'c11', name: 'denim jeans', category: 'bottom', color: 'blue', season: '사계절', imagePath: 'assets/images/mock/item_11.jpg', wearCount: 12),
  const ClothingItem(id: 'c12', name: 'white sneakers', category: 'shoes', color: 'white', season: '사계절', imagePath: 'assets/images/mock/item_12.jpg', wearCount: 9),
];

final List<Composition> mockCompositions = [
  const Composition(
    id: 'comp01',
    name: '겨울 데일리',
    season: '겨울',
    items: [
      CompositionItemPlacement(clothingItemId: 'c01', x: 40, y: 40, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c03', x: 60, y: 120, zIndex: 1),
      CompositionItemPlacement(clothingItemId: 'c11', x: 60, y: 260, zIndex: 2),
      CompositionItemPlacement(clothingItemId: 'c07', x: 80, y: 380, zIndex: 3),
    ],
  ),
  const Composition(
    id: 'comp02',
    name: '포멀 코디',
    season: '겨울',
    items: [
      CompositionItemPlacement(clothingItemId: 'c02', x: 40, y: 40, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c08', x: 70, y: 140, zIndex: 1),
    ],
  ),
];

final List<StyleLog> mockStyleLogs = [
  StyleLog(
    id: 'log01',
    coverImagePath: 'assets/images/mock/item_01.jpg',
    wornDate: DateTime(2026, 1, 5),
    linkedCompositionId: 'comp01',
    additionalImagePaths: const ['assets/images/mock/item_03.jpg', 'assets/images/mock/item_11.jpg'],
    location: '집',
  ),
  StyleLog(
    id: 'log02',
    coverImagePath: 'assets/images/mock/item_02.jpg',
    wornDate: DateTime(2026, 1, 10),
    linkedCompositionId: 'comp02',
    location: '회사',
  ),
];
```

- [ ] **Step 2 (test): `test/mock/mock_data_test.dart` 작성**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/mock/mock_data.dart';

void main() {
  test('mock 데이터는 최소 1개 이상의 미완성 아이템을 포함한다', () {
    expect(mockClothingItems.any((item) => item.isIncomplete), isTrue);
  });

  test('모든 Composition의 items는 실제 존재하는 ClothingItem id를 참조한다', () {
    final validIds = mockClothingItems.map((e) => e.id).toSet();
    for (final composition in mockCompositions) {
      for (final placement in composition.items) {
        expect(validIds.contains(placement.clothingItemId), isTrue,
            reason: '${placement.clothingItemId} not found in mockClothingItems');
      }
    }
  });

  test('모든 StyleLog의 linkedCompositionId는 실제 존재하는 Composition id를 참조한다', () {
    final validIds = mockCompositions.map((e) => e.id).toSet();
    for (final log in mockStyleLogs) {
      if (log.linkedCompositionId != null) {
        expect(validIds.contains(log.linkedCompositionId), isTrue);
      }
    }
  });
}
```

- [ ] **Step 3: 테스트 실행**

```bash
flutter test test/mock/mock_data_test.dart
```

Expected: `3 tests passed`

- [ ] **Step 4: Commit**

```bash
git add lib/models/ lib/mock/ test/mock/
git commit -m "feat(models): add ClothingItem/Composition/StyleLog models and mock data"
```

---

### Task 4: Riverpod Provider

**Files:**
- Create: `lib/providers/closet_providers.dart`
- Create: `lib/providers/composition_providers.dart`
- Create: `lib/providers/style_log_providers.dart`
- Test: `test/providers/closet_providers_test.dart`

**Interfaces:**
- Consumes: `mockClothingItems`, `mockCompositions`, `mockStyleLogs` (Task 3), `ClothingItem`/`Composition`/`StyleLog` (Task 3)
- Produces: `closetItemsProvider`(`StateNotifierProvider<ClosetItemsNotifier, List<ClothingItem>>`), `selectedSeasonFilterProvider`(`StateProvider<String?>`), `filteredClosetItemsProvider`(`Provider<List<ClothingItem>>`), `closetDensityProvider`(`StateProvider<int>`, 기본값 `AppDensity.mid`), `compositionsProvider`(`StateNotifierProvider<CompositionsNotifier, List<Composition>>`), `styleLogsProvider`(`StateNotifierProvider<StyleLogsNotifier, List<StyleLog>>`) — 모든 화면 Task가 소비.

- [ ] **Step 1: `lib/providers/closet_providers.dart` 작성**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clothing_item.dart';
import '../mock/mock_data.dart';
import '../theme/app_spacing.dart';

class ClosetItemsNotifier extends StateNotifier<List<ClothingItem>> {
  ClosetItemsNotifier() : super(mockClothingItems);

  void softDelete(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          ClothingItem(
            id: item.id,
            name: item.name,
            category: item.category,
            color: item.color,
            season: item.season,
            imagePath: item.imagePath,
            location: item.location,
            memo: item.memo,
            wearCount: item.wearCount,
            isIncomplete: item.isIncomplete,
            isDeleted: true,
          )
        else
          item,
    ];
  }
}

final closetItemsProvider =
    StateNotifierProvider<ClosetItemsNotifier, List<ClothingItem>>(
        (ref) => ClosetItemsNotifier());

/// null = 전체 시즌.
final selectedSeasonFilterProvider = StateProvider<String?>((ref) => null);

/// 삭제되지 않았고, 선택된 시즌 필터에 맞는 아이템만.
final filteredClosetItemsProvider = Provider<List<ClothingItem>>((ref) {
  final items = ref.watch(closetItemsProvider);
  final season = ref.watch(selectedSeasonFilterProvider);
  return items
      .where((item) => !item.isDeleted)
      .where((item) => season == null || item.season == season)
      .toList();
});

/// 옷장 메인 그리드 밀도 — AppDensity.min/mid/max 중 하나.
final closetDensityProvider = StateProvider<int>((ref) => 3);
```

- [ ] **Step 2: `lib/providers/composition_providers.dart` 작성**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/composition.dart';
import '../mock/mock_data.dart';

class CompositionsNotifier extends StateNotifier<List<Composition>> {
  CompositionsNotifier() : super(mockCompositions);
}

final compositionsProvider =
    StateNotifierProvider<CompositionsNotifier, List<Composition>>(
        (ref) => CompositionsNotifier());

final filteredCompositionsProvider = Provider<List<Composition>>((ref) {
  return ref.watch(compositionsProvider).where((c) => !c.isDeleted).toList();
});
```

- [ ] **Step 3: `lib/providers/style_log_providers.dart` 작성**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/style_log.dart';
import '../mock/mock_data.dart';

class StyleLogsNotifier extends StateNotifier<List<StyleLog>> {
  StyleLogsNotifier() : super(mockStyleLogs);
}

final styleLogsProvider =
    StateNotifierProvider<StyleLogsNotifier, List<StyleLog>>(
        (ref) => StyleLogsNotifier());

final filteredStyleLogsProvider = Provider<List<StyleLog>>((ref) {
  final logs = ref.watch(styleLogsProvider).where((l) => !l.isDeleted).toList();
  logs.sort((a, b) => b.wornDate.compareTo(a.wornDate));
  return logs;
});
```

- [ ] **Step 4 (test): `test/providers/closet_providers_test.dart` 작성**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';

void main() {
  test('selectedSeasonFilterProvider를 설정하면 filteredClosetItemsProvider가 걸러진다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(filteredClosetItemsProvider).length;
    container.read(selectedSeasonFilterProvider.notifier).state = '사계절';
    final after = container.read(filteredClosetItemsProvider);

    expect(after.length, lessThan(before));
    expect(after.every((item) => item.season == '사계절'), isTrue);
  });

  test('softDelete한 아이템은 filteredClosetItemsProvider에서 제외된다', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final beforeCount = container.read(filteredClosetItemsProvider).length;
    container.read(closetItemsProvider.notifier).softDelete('c01');
    final afterCount = container.read(filteredClosetItemsProvider).length;

    expect(afterCount, beforeCount - 1);
  });
}
```

- [ ] **Step 5: 테스트 실행**

```bash
flutter test test/providers/closet_providers_test.dart
```

Expected: `2 tests passed`

- [ ] **Step 6: Commit**

```bash
git add lib/providers/ test/providers/
git commit -m "feat(providers): add Riverpod providers for closet/composition/style-log mock data"
```

---

### Task 5: go_router + main.dart 앱 셸

**Files:**
- Create: `lib/router/app_router.dart`
- Modify: `lib/main.dart` (전체 교체)

**Interfaces:**
- Consumes: `AppTheme.light`, `AppTheme.dark` (Task 2)
- Produces: `appRouterProvider`(`Provider<GoRouter>`), 라우트 이름 상수 `AppRoute.closetMain` 등 10개 — 이후 모든 화면 Task가 자신의 라우트 등록에 사용. **이 Task는 자리표시 화면(placeholder `Scaffold`)으로 라우트를 먼저 만들고, Task 6~16이 각자의 실제 화면으로 교체한다.**

- [ ] **Step 1: `lib/router/app_router.dart` 작성 (10개 라우트, 자리표시 화면)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppRoute {
  AppRoute._();

  static const closetMain = '/closet';
  static const closetItemDetail = '/closet/:id';
  static const closetAdd = '/closet/add';
  static const compositionMain = '/composition';
  static const compositionDetail = '/composition/:id';
  static const compositionEditor = '/composition/editor';
  static const styleLogMain = '/style-log';
  static const styleLogViewer = '/style-log/:id';
  static const styleLogAdd = '/style-log/add';
  static const settingsTrash = '/settings';
}

Widget _placeholder(String label) => Scaffold(body: Center(child: Text(label)));

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.closetMain,
    routes: [
      GoRoute(
        path: AppRoute.closetMain,
        builder: (context, state) => _placeholder('옷장 메인'),
      ),
      GoRoute(
        path: AppRoute.closetItemDetail,
        builder: (context, state) => _placeholder('옷 상세 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoute.closetAdd,
        builder: (context, state) => _placeholder('옷 추가하기'),
      ),
      GoRoute(
        path: AppRoute.compositionMain,
        builder: (context, state) => _placeholder('코디 메인'),
      ),
      GoRoute(
        path: AppRoute.compositionDetail,
        builder: (context, state) => _placeholder('코디 상세 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoute.compositionEditor,
        builder: (context, state) => _placeholder('코디 만들기'),
      ),
      GoRoute(
        path: AppRoute.styleLogMain,
        builder: (context, state) => _placeholder('스타일일지 메인'),
      ),
      GoRoute(
        path: AppRoute.styleLogViewer,
        builder: (context, state) => _placeholder('스타일일지 열람 ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: AppRoute.styleLogAdd,
        builder: (context, state) => _placeholder('스타일일지 추가'),
      ),
      GoRoute(
        path: AppRoute.settingsTrash,
        builder: (context, state) => _placeholder('설정/휴지통'),
      ),
    ],
  );
});
```

- [ ] **Step 2: `lib/main.dart` 전체 교체**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: DigitalWardrobeApp()));
}

class DigitalWardrobeApp extends ConsumerWidget {
  const DigitalWardrobeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Digital Wardrobe',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 3: 앱 실행 확인**

```bash
flutter run -d windows
```

Expected: 앱이 "옷장 메인"이라는 텍스트만 있는 빈 화면으로 실행됨. 에러 없음.

- [ ] **Step 4: Commit**

```bash
git add lib/router/ lib/main.dart
git commit -m "feat(router): add go_router with 10 placeholder routes, wire main.dart"
```

---

### Task 6: 공용 갤러리 컴포넌트 (C1/C2/C4/C12)

**Files:**
- Create: `lib/widgets/status_badge.dart`
- Create: `lib/widgets/selectable_gallery_tile.dart`
- Create: `lib/widgets/grouped_gallery_grid.dart`
- Create: `lib/widgets/overlay_header.dart`

**Interfaces:**
- Consumes: `ClothingItem` (Task 3), `AppSpacing`/`AppDensity` (Task 2)
- Produces: `StatusBadge({required String label})`, `SelectableGalleryTile({required ClothingItem item, required VoidCallback onTap, bool selected = false})`, `GroupedGalleryGrid({required List<ClothingItem> items, required int density, required void Function(ClothingItem) onItemTap})`, `OverlayHeader({required Widget child, List<Widget> actions = const []})` — Task 7(옷장 메인), Task 15(코디 메인), 그 외 상세 화면들이 소비.

- [ ] **Step 1: `lib/widgets/status_badge.dart` 작성 (C12)**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Semantics(
      label: '$label 상태',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: semantic.warning,
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/widgets/selectable_gallery_tile.dart` 작성 (C1)**

```dart
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../theme/app_spacing.dart';
import 'status_badge.dart';

class SelectableGalleryTile extends StatelessWidget {
  const SelectableGalleryTile({
    super.key,
    required this.item,
    required this.onTap,
    this.selected = false,
  });

  final ClothingItem item;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${item.name}, ${item.color}, 착용 ${item.wearCount}회'
          '${item.isIncomplete ? ", 미완성" : ""}',
      child: GestureDetector(
        onTap: item.isIncomplete ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: item.isIncomplete ? 0.4 : 1.0),
            border: selected ? Border.all(color: colorScheme.primary, width: 2) : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: item.imagePath.isNotEmpty
                    ? Image.asset(item.imagePath, fit: BoxFit.cover)
                    : const SizedBox.shrink(),
              ),
              if (item.isIncomplete)
                const Positioned(top: AppSpacing.xxs, left: AppSpacing.xxs, child: StatusBadge(label: '미완성')),
              Positioned(
                left: AppSpacing.xxs,
                bottom: AppSpacing.xxs,
                right: AppSpacing.xxs,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  color: colorScheme.surface.withValues(alpha: 0.85),
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/widgets/grouped_gallery_grid.dart` 작성 (C2, L4/T6 밀도 반영)**

```dart
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../theme/app_spacing.dart';
import 'selectable_gallery_tile.dart';

class GroupedGalleryGrid extends StatelessWidget {
  const GroupedGalleryGrid({
    super.key,
    required this.items,
    required this.density,
    required this.onItemTap,
  });

  final List<ClothingItem> items;
  final int density;
  final void Function(ClothingItem item) onItemTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: density,
        crossAxisSpacing: AppSpacing.galleryGap,
        mainAxisSpacing: AppSpacing.galleryGap,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return SelectableGalleryTile(item: item, onTap: () => onItemTap(item));
      },
    );
  }
}
```

- [ ] **Step 4: `lib/widgets/overlay_header.dart` 작성 (C4, L2 — 콘텐츠 높이를 뺏지 않는 구조적 오버레이)**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class OverlayHeader extends StatelessWidget {
  const OverlayHeader({super.key, required this.child, this.actions = const []});

  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          child: Row(
            children: [
              Expanded(child: child),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: 컴파일 확인**

```bash
flutter analyze lib/widgets/
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/status_badge.dart lib/widgets/selectable_gallery_tile.dart lib/widgets/grouped_gallery_grid.dart lib/widgets/overlay_header.dart
git commit -m "feat(widgets): add StatusBadge, SelectableGalleryTile, GroupedGalleryGrid, OverlayHeader"
```

---

### Task 7: 화면 — 옷장 메인

**Files:**
- Create: `lib/screens/closet_main_screen.dart`
- Modify: `lib/router/app_router.dart:closetMain 라우트` (자리표시 → 실제 화면 교체)

**Interfaces:**
- Consumes: `GroupedGalleryGrid`, `OverlayHeader` (Task 6), `filteredClosetItemsProvider`, `selectedSeasonFilterProvider`, `closetDensityProvider` (Task 4), `AppRoute` (Task 5)

목업(`참고자료/목업/옷장-메인.png`) 기준: 상단에 "옷장" 드롭다운 + "선택" 버튼, 그 아래 계절 필터 칩 2개 + 밀도토글 아이콘 + 정렬토글 아이콘, 하단에 뒤로가기 버튼과 `+` FAB.

- [ ] **Step 1: `lib/screens/closet_main_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/closet_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/grouped_gallery_grid.dart';
import '../widgets/overlay_header.dart';

class ClosetMainScreen extends ConsumerWidget {
  const ClosetMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredClosetItemsProvider);
    final season = ref.watch(selectedSeasonFilterProvider);
    final density = ref.watch(closetDensityProvider);

    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(
            actions: [
              TextButton(onPressed: () {}, child: const Text('선택')),
            ],
            child: Row(
              children: [
                DropdownButton<String>(
                  value: '옷장',
                  underline: const SizedBox.shrink(),
                  items: const [DropdownMenuItem(value: '옷장', child: Text('옷장'))],
                  onChanged: (_) {},
                ),
                const SizedBox(width: AppSpacing.md),
                DropdownButton<String?>(
                  value: season,
                  hint: const Text('계절'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('전체')),
                    DropdownMenuItem(value: '겨울', child: Text('겨울')),
                    DropdownMenuItem(value: '사계절', child: Text('사계절')),
                  ],
                  onChanged: (value) => ref.read(selectedSeasonFilterProvider.notifier).state = value,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.grid_view),
                  tooltip: '그리드 밀도 전환',
                  onPressed: () {
                    final currentIndex = AppDensity.levels.indexOf(density);
                    final next = AppDensity.levels[(currentIndex + 1) % AppDensity.levels.length];
                    ref.read(closetDensityProvider.notifier).state = next;
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  tooltip: '정렬 기준',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: GroupedGalleryGrid(
              items: items,
              density: density,
              onItemTap: (item) => context.go(AppRoute.closetItemDetail.replaceFirst(':id', item.id)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoute.closetAdd),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/router/app_router.dart`의 `closetMain` 라우트 교체**

```dart
      GoRoute(
        path: AppRoute.closetMain,
        builder: (context, state) => const ClosetMainScreen(),
      ),
```

(파일 상단 import에 `import '../screens/closet_main_screen.dart';` 추가)

- [ ] **Step 3: 실행 확인**

```bash
flutter run -d windows
```

Expected: 옷장 메인 화면에 목업 데이터 12개(미완성 1개 포함) 그리드로 표시, 계절 필터 동작, 밀도 아이콘 누르면 1/3/5열 순환.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/closet_main_screen.dart lib/router/app_router.dart
git commit -m "feat(screen): implement 옷장 메인 (Closet Main)"
```

---

### Task 8: 공용 컴포넌트(C10) + 화면 — 스타일일지 (열람)

**Files:**
- Create: `lib/widgets/sequential_slot_card.dart`
- Create: `lib/screens/style_log_viewer_screen.dart`
- Modify: `lib/router/app_router.dart:styleLogViewer 라우트`

**Interfaces:**
- Consumes: `StyleLog`, `Composition` (Task 3), `styleLogsProvider`, `compositionsProvider` (Task 4)
- Produces: `SequentialSlotCard({required List<Widget> slots})` — Task 16(스타일일지 추가)도 재사용.

- [ ] **Step 1: `lib/widgets/sequential_slot_card.dart` 작성 (C10 — 고정 선행 슬롯 + 스와이프)**

```dart
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// 고정 슬롯들을 좌우 스와이프로 넘겨보는 카드. 스타일일지(커버→코디→추가이미지)와
/// 스타일일지 추가 화면 양쪽에서 재사용.
class SequentialSlotCard extends StatelessWidget {
  const SequentialSlotCard({super.key, required this.slots});

  final List<Widget> slots;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: PageView.builder(
        itemCount: slots.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: slots[index],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/screens/style_log_viewer_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/composition.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/overlay_header.dart';
import '../widgets/sequential_slot_card.dart';

class StyleLogViewerScreen extends ConsumerWidget {
  const StyleLogViewerScreen({super.key, required this.styleLogId});

  final String styleLogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(styleLogsProvider).firstWhere((l) => l.id == styleLogId);
    final compositionMatches = log.linkedCompositionId == null
        ? const <Composition>[]
        : ref.watch(compositionsProvider).where((c) => c.id == log.linkedCompositionId).toList();
    final composition = compositionMatches.isEmpty ? null : compositionMatches.first;

    final slots = <Widget>[
      Image.asset(log.coverImagePath, fit: BoxFit.cover),
      composition == null
          ? const Center(child: Text('연결된 코디 없음'))
          : Center(child: Text(composition.name, style: Theme.of(context).textTheme.titleMedium)),
      for (final path in log.additionalImagePaths) Image.asset(path, fit: BoxFit.cover),
    ];

    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(child: Text('스타일일지', style: Theme.of(context).textTheme.titleLarge)),
          Expanded(
            child: Column(
              children: [
                SequentialSlotCard(slots: slots),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}  ${log.location}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/router/app_router.dart`의 `styleLogViewer` 라우트 교체**

```dart
      GoRoute(
        path: AppRoute.styleLogViewer,
        builder: (context, state) => StyleLogViewerScreen(styleLogId: state.pathParameters['id']!),
      ),
```

- [ ] **Step 4: 실행 확인**

```bash
flutter run -d windows
```

브라우저/에뮬레이터 주소창 또는 임시 버튼으로 `/style-log/log01` 접속. Expected: 커버 이미지 → 코디 이름 → 추가 이미지 순으로 스와이프됨.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/sequential_slot_card.dart lib/screens/style_log_viewer_screen.dart lib/router/app_router.dart
git commit -m "feat(screen): implement 스타일일지 열람 (Style Log Viewer), add SequentialSlotCard"
```

---

### Task 9: 화면 — 코디 만들기 (에디터, 정적)

**Files:**
- Create: `lib/widgets/artboard_canvas.dart`
- Create: `lib/screens/composition_editor_screen.dart`
- Modify: `lib/router/app_router.dart:compositionEditor 라우트`

**Interfaces:**
- Consumes: `Composition`, `CompositionItemPlacement`, `ClothingItem` (Task 3), `mockClothingItems` (Task 3), `mockCompositions` (Task 3)
- Produces: `ArtboardCanvas({required List<CompositionItemPlacement> placements, required List<ClothingItem> availableItems})` — **정적 레이아웃만, 드래그/회전/리사이즈/z-index 로직 없음** (Global Constraints).

- [ ] **Step 1: `lib/widgets/artboard_canvas.dart` 작성 (C5, 정적)**

```dart
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../models/composition.dart';
import '../theme/app_spacing.dart';

/// L6(고정 캔버스) 정적 버전 — 이번 스프린트는 배치된 아이템을
/// zIndex 순서대로 그리기만 하고, 드래그/회전/리사이즈는 구현하지 않는다.
class ArtboardCanvas extends StatelessWidget {
  const ArtboardCanvas({super.key, required this.placements, required this.itemsById});

  final List<CompositionItemPlacement> placements;
  final Map<String, ClothingItem> itemsById;

  @override
  Widget build(BuildContext context) {
    final sorted = [...placements]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            for (final placement in sorted)
              Positioned(
                left: placement.x,
                top: placement.y,
                child: Transform.rotate(
                  angle: placement.rotation,
                  child: Transform.scale(
                    scale: placement.scale,
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: itemsById[placement.clothingItemId] == null
                          ? const SizedBox.shrink()
                          : Image.asset(itemsById[placement.clothingItemId]!.imagePath, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/screens/composition_editor_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import '../mock/mock_data.dart';
import '../theme/app_spacing.dart';
import '../widgets/artboard_canvas.dart';
import '../widgets/overlay_header.dart';

class CompositionEditorScreen extends StatelessWidget {
  const CompositionEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final composition = mockCompositions.first;
    final itemsById = {for (final item in mockClothingItems) item.id: item};

    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(
            actions: [TextButton(onPressed: () {}, child: const Text('저장'))],
            child: Text('코디 만들기', style: Theme.of(context).textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ArtboardCanvas(placements: composition.items, itemsById: itemsById),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              children: [
                for (final placement in composition.items)
                  if (itemsById[placement.clothingItemId] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                      child: SizedBox(
                        width: 80,
                        child: Image.asset(itemsById[placement.clothingItemId]!.imagePath, fit: BoxFit.cover),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/router/app_router.dart`의 `compositionEditor` 라우트 교체**

```dart
      GoRoute(
        path: AppRoute.compositionEditor,
        builder: (context, state) => const CompositionEditorScreen(),
      ),
```

- [ ] **Step 4: 실행 확인**

```bash
flutter run -d windows
```

Expected: `/composition/editor` 접속 시 아트보드에 아이템들이 zIndex 순서로 정적 배치되어 보임. 드래그해도 움직이지 않음(의도된 동작).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/artboard_canvas.dart lib/screens/composition_editor_screen.dart lib/router/app_router.dart
git commit -m "feat(screen): implement 코디 만들기 editor as static layout (no gesture logic)"
```

---

### Task 10: 화면 — 옷 상세 / 코디 상세

**Files:**
- Create: `lib/screens/closet_item_detail_screen.dart`
- Create: `lib/screens/composition_detail_screen.dart`
- Modify: `lib/router/app_router.dart` (`closetItemDetail`, `compositionDetail` 라우트)

**Interfaces:**
- Consumes: `closetItemsProvider`, `compositionsProvider`, `styleLogsProvider` (Task 4), `OverlayHeader` (Task 6)

- [ ] **Step 1: `lib/screens/closet_item_detail_screen.dart` 작성 (P4 크로스레퍼런스: 이 옷이 쓰인 코디/스타일일지 이력)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/overlay_header.dart';

class ClosetItemDetailScreen extends ConsumerWidget {
  const ClosetItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(closetItemsProvider).firstWhere((i) => i.id == itemId);
    final compositions = ref.watch(compositionsProvider)
        .where((c) => c.items.any((p) => p.clothingItemId == itemId))
        .toList();
    final styleLogs = ref.watch(styleLogsProvider)
        .where((l) => compositions.any((c) => c.id == l.linkedCompositionId))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(child: Text(item.name, style: Theme.of(context).textTheme.titleLarge)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AspectRatio(aspectRatio: 1, child: Image.asset(item.imagePath, fit: BoxFit.cover)),
                const SizedBox(height: AppSpacing.md),
                Text('${item.category} · ${item.color} · ${item.season}'),
                Text('위치: ${item.location.isEmpty ? "미지정" : item.location}'),
                Text('착용 ${item.wearCount}회'),
                const SizedBox(height: AppSpacing.lg),
                Text('이 옷을 사용한 코디', style: Theme.of(context).textTheme.titleMedium),
                for (final composition in compositions)
                  ListTile(
                    title: Text(composition.name),
                    onTap: () => context.go(AppRoute.compositionDetail.replaceFirst(':id', composition.id)),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text('이 옷이 담긴 스타일일지', style: Theme.of(context).textTheme.titleMedium),
                for (final log in styleLogs)
                  ListTile(
                    title: Text('${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}'),
                    onTap: () => context.go(AppRoute.styleLogViewer.replaceFirst(':id', log.id)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/screens/composition_detail_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/artboard_canvas.dart';
import '../widgets/overlay_header.dart';

class CompositionDetailScreen extends ConsumerWidget {
  const CompositionDetailScreen({super.key, required this.compositionId});

  final String compositionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composition = ref.watch(compositionsProvider).firstWhere((c) => c.id == compositionId);
    final itemsById = {for (final item in ref.watch(closetItemsProvider)) item.id: item};
    final linkedLogs = ref.watch(styleLogsProvider).where((l) => l.linkedCompositionId == compositionId).toList();

    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(child: Text(composition.name, style: Theme.of(context).textTheme.titleLarge)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ArtboardCanvas(placements: composition.items, itemsById: itemsById),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('사용된 아이템', style: Theme.of(context).textTheme.titleMedium),
                ),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final placement in composition.items)
                        if (itemsById[placement.clothingItemId] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                            child: GestureDetector(
                              onTap: () => context.go(AppRoute.closetItemDetail.replaceFirst(':id', placement.clothingItemId)),
                              child: SizedBox(width: 70, child: Image.asset(itemsById[placement.clothingItemId]!.imagePath)),
                            ),
                          ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('연결된 스타일일지', style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final log in linkedLogs)
                  ListTile(
                    title: Text('${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}'),
                    onTap: () => context.go(AppRoute.styleLogViewer.replaceFirst(':id', log.id)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/router/app_router.dart`의 두 라우트 교체**

```dart
      GoRoute(
        path: AppRoute.closetItemDetail,
        builder: (context, state) => ClosetItemDetailScreen(itemId: state.pathParameters['id']!),
      ),
```
```dart
      GoRoute(
        path: AppRoute.compositionDetail,
        builder: (context, state) => CompositionDetailScreen(compositionId: state.pathParameters['id']!),
      ),
```

- [ ] **Step 4: 실행 확인**

```bash
flutter run -d windows
```

Expected: 옷장 메인에서 아이템 탭 → 옷 상세로 이동, 사용된 코디 탭 → 코디 상세로 이동, 코디 상세의 아이템 탭 → 다시 옷 상세로 이동 (P4 크로스레퍼런스 확인).

- [ ] **Step 5: Commit**

```bash
git add lib/screens/closet_item_detail_screen.dart lib/screens/composition_detail_screen.dart lib/router/app_router.dart
git commit -m "feat(screen): implement 옷 상세, 코디 상세 with cross-reference navigation"
```

---

### Task 11: 공용 컴포넌트(C9) + 화면 — 옷 추가하기

**Files:**
- Create: `lib/widgets/ai_processing_status.dart`
- Create: `lib/screens/closet_add_screen.dart`
- Modify: `lib/router/app_router.dart:closetAdd 라우트`

**Interfaces:**
- Consumes: `closetItemsProvider` (Task 4)
- Produces: `AiProcessingStatus({required AiProcessingState state})`(`enum AiProcessingState { processing, success, failed }`) — 이번 스프린트는 항상 `success` 고정 표시(Global Constraints).

- [ ] **Step 1: `lib/widgets/ai_processing_status.dart` 작성 (C9, I7 계약의 상태 표시만 — 실제 재시도 로직 없음)**

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AiProcessingState { processing, success, failed }

/// I7(AI 처리 인터랙션 계약)의 상태 표시부만 구현. 실제 API 호출/재시도 로직은
/// 이번 스프린트 스코프 밖 — 이 화면에서는 항상 success로 고정 사용.
class AiProcessingStatus extends StatelessWidget {
  const AiProcessingStatus({super.key, required this.state});

  final AiProcessingState state;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Semantics(
      liveRegion: true,
      label: switch (state) {
        AiProcessingState.processing => 'AI 처리 중',
        AiProcessingState.success => 'AI 처리 완료',
        AiProcessingState.failed => 'AI 처리 실패, 재시도 가능',
      },
      child: Row(
        children: [
          Icon(
            switch (state) {
              AiProcessingState.processing => Icons.hourglass_top,
              AiProcessingState.success => Icons.check_circle,
              AiProcessingState.failed => Icons.error,
            },
            color: state == AiProcessingState.failed ? semantic.warning : null,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(switch (state) {
            AiProcessingState.processing => '배경 제거 및 태그 생성 중...',
            AiProcessingState.success => '자동 태깅 완료',
            AiProcessingState.failed => '처리 실패 — 다시 시도',
          }),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/screens/closet_add_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/closet_providers.dart';
import '../models/clothing_item.dart';
import '../theme/app_spacing.dart';
import '../widgets/ai_processing_status.dart';
import '../widgets/overlay_header.dart';

class ClosetAddScreen extends ConsumerStatefulWidget {
  const ClosetAddScreen({super.key});

  @override
  ConsumerState<ClosetAddScreen> createState() => _ClosetAddScreenState();
}

class _ClosetAddScreenState extends ConsumerState<ClosetAddScreen> {
  final _nameController = TextEditingController(text: '새 아이템');
  String _category = 'top';
  String _season = '사계절';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(child: Text('옷 추가하기', style: Theme.of(context).textTheme.titleLarge)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Container(
                  height: 200,
                  color: Theme.of(context).colorScheme.secondary,
                  child: const Center(child: Icon(Icons.add_a_photo, size: 48)),
                ),
                const SizedBox(height: AppSpacing.md),
                const AiProcessingStatus(state: AiProcessingState.success),
                const SizedBox(height: AppSpacing.md),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: '이름')),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: '종류'),
                  items: const [
                    DropdownMenuItem(value: 'top', child: Text('상의')),
                    DropdownMenuItem(value: 'bottom', child: Text('하의')),
                    DropdownMenuItem(value: 'outer', child: Text('아우터')),
                    DropdownMenuItem(value: 'shoes', child: Text('신발')),
                    DropdownMenuItem(value: 'accessory', child: Text('액세서리')),
                  ],
                  onChanged: (value) => setState(() => _category = value!),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _season,
                  decoration: const InputDecoration(labelText: '계절'),
                  items: const [
                    DropdownMenuItem(value: '봄', child: Text('봄')),
                    DropdownMenuItem(value: '여름', child: Text('여름')),
                    DropdownMenuItem(value: '가을', child: Text('가을')),
                    DropdownMenuItem(value: '겨울', child: Text('겨울')),
                    DropdownMenuItem(value: '사계절', child: Text('사계절')),
                  ],
                  onChanged: (value) => setState(() => _season = value!),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    final notifier = ref.read(closetItemsProvider.notifier);
                    notifier.state = [
                      ...notifier.state,
                      ClothingItem(
                        id: 'c${notifier.state.length + 1}',
                        name: _nameController.text,
                        category: _category,
                        color: 'unknown',
                        season: _season,
                        imagePath: '',
                      ),
                    ];
                    context.pop();
                  },
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/router/app_router.dart`의 `closetAdd` 라우트 교체**

```dart
      GoRoute(
        path: AppRoute.closetAdd,
        builder: (context, state) => const ClosetAddScreen(),
      ),
```

- [ ] **Step 4: 실행 확인**

```bash
flutter run -d windows
```

Expected: 옷장 메인의 `+` 버튼 → 옷 추가하기 화면 → "AI 처리 완료" 정적 표시 확인 → 저장 시 옷장 메인 그리드에 새 아이템 반영.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/ai_processing_status.dart lib/screens/closet_add_screen.dart lib/router/app_router.dart
git commit -m "feat(screen): implement 옷 추가하기 with static AiProcessingStatus"
```

---

### Task 12: 공용 컴포넌트(C3/C11) + 화면 — 설정/휴지통

**Files:**
- Create: `lib/widgets/flat_filter_gallery.dart`
- Create: `lib/widgets/destructive_confirm_modal.dart`
- Create: `lib/screens/settings_trash_screen.dart`
- Modify: `lib/router/app_router.dart:settingsTrash 라우트`

**Interfaces:**
- Consumes: `closetItemsProvider`, `compositionsProvider`, `styleLogsProvider` (Task 4)
- Produces: `FlatFilterGallery({required List<Widget> tiles, required List<String> filterChips})` — Task 14(스타일일지 메인)도 재사용. `DestructiveConfirmModal.show(BuildContext, {required String message, required VoidCallback onConfirm})`.

- [ ] **Step 1: `lib/widgets/flat_filter_gallery.dart` 작성 (C3, L3 Flat+Filter 변형 — 드릴다운 없는 플랫 갤러리)**

```dart
import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class FlatFilterGallery extends StatelessWidget {
  const FlatFilterGallery({super.key, required this.tiles, required this.filterChips});

  final List<Widget> tiles;
  final List<String> filterChips;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            children: [
              for (final chip in filterChips)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  child: FilterChip(label: Text(chip), selected: false, onSelected: (_) {}),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(AppSpacing.sm), children: tiles),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: `lib/widgets/destructive_confirm_modal.dart` 작성 (C11, I6 — 영구 삭제 등 비가역 액션 전용)**

```dart
import 'package:flutter/material.dart';

class DestructiveConfirmModal {
  DestructiveConfirmModal._();

  static Future<void> show(
    BuildContext context, {
    required String message,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('영구 삭제'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            child: const Text('영구 삭제'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/screens/settings_trash_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/closet_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/destructive_confirm_modal.dart';
import '../widgets/flat_filter_gallery.dart';
import '../widgets/overlay_header.dart';

class SettingsTrashScreen extends ConsumerWidget {
  const SettingsTrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedItems = ref.watch(closetItemsProvider).where((i) => i.isDeleted).toList();

    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(child: Text('설정 / 휴지통', style: Theme.of(context).textTheme.titleLarge)),
          Expanded(
            child: FlatFilterGallery(
              filterChips: const ['옷', '코디', '스타일일지'],
              tiles: [
                for (final item in deletedItems)
                  ListTile(
                    title: Text(item.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever),
                      onPressed: () => DestructiveConfirmModal.show(
                        context,
                        message: '${item.name}을(를) 영구 삭제하시겠습니까? 되돌릴 수 없습니다.',
                        onConfirm: () {},
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: `lib/router/app_router.dart`의 `settingsTrash` 라우트 교체**

```dart
      GoRoute(
        path: AppRoute.settingsTrash,
        builder: (context, state) => const SettingsTrashScreen(),
      ),
```

- [ ] **Step 5: 실행 확인**

```bash
flutter run -d windows
```

Expected: 휴지통에서 영구 삭제 아이콘 탭 → 확인 모달 표시 → "영구 삭제" 눌러야만 닫힘(취소 가능).

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/flat_filter_gallery.dart lib/widgets/destructive_confirm_modal.dart lib/screens/settings_trash_screen.dart lib/router/app_router.dart
git commit -m "feat(screen): implement 설정/휴지통 with FlatFilterGallery, DestructiveConfirmModal"
```

---

### Task 13: 화면 — 코디 메인

**Files:**
- Create: `lib/screens/composition_main_screen.dart`
- Modify: `lib/router/app_router.dart:compositionMain 라우트`

**Interfaces:**
- Consumes: `filteredCompositionsProvider` (Task 4), `GroupedGalleryGrid`(사양 재사용 — 단, `Composition` 리스트용으로 타일만 다르게 렌더링), `OverlayHeader` (Task 6)

- [ ] **Step 1: `lib/screens/composition_main_screen.dart` 작성 (옷장 메인과 동일한 Grouped 구조, Composition용 타일)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/composition_providers.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import '../widgets/overlay_header.dart';

class CompositionMainScreen extends ConsumerWidget {
  const CompositionMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compositions = ref.watch(filteredCompositionsProvider);

    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(child: Text('코디', style: Theme.of(context).textTheme.titleLarge)),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.sm),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.galleryGap,
                mainAxisSpacing: AppSpacing.galleryGap,
                childAspectRatio: 1,
              ),
              itemCount: compositions.length,
              itemBuilder: (context, index) {
                final composition = compositions[index];
                return GestureDetector(
                  onTap: () => context.go(AppRoute.compositionDetail.replaceFirst(':id', composition.id)),
                  child: Container(
                    color: Theme.of(context).colorScheme.secondary,
                    child: Center(child: Text(composition.name, textAlign: TextAlign.center)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoute.compositionEditor),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/router/app_router.dart`의 `compositionMain` 라우트 교체**

```dart
      GoRoute(
        path: AppRoute.compositionMain,
        builder: (context, state) => const CompositionMainScreen(),
      ),
```

- [ ] **Step 3: 실행 확인**

```bash
flutter run -d windows
```

Expected: `/composition` 접속 시 코디 2개(comp01, comp02) 그리드 표시, 탭하면 코디 상세로 이동.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/composition_main_screen.dart lib/router/app_router.dart
git commit -m "feat(screen): implement 코디 메인"
```

---

### Task 14: 화면 — 스타일일지 메인

**Files:**
- Create: `lib/screens/style_log_main_screen.dart`
- Modify: `lib/router/app_router.dart:styleLogMain 라우트`

**Interfaces:**
- Consumes: `filteredStyleLogsProvider` (Task 4), `FlatFilterGallery` (Task 12), `OverlayHeader` (Task 6)

- [ ] **Step 1: `lib/screens/style_log_main_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/style_log_providers.dart';
import '../router/app_router.dart';
import '../widgets/flat_filter_gallery.dart';
import '../widgets/overlay_header.dart';

class StyleLogMainScreen extends ConsumerWidget {
  const StyleLogMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(filteredStyleLogsProvider);

    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(child: Text('스타일일지', style: Theme.of(context).textTheme.titleLarge)),
          Expanded(
            child: FlatFilterGallery(
              filterChips: const ['최근', '겨울', '여름'],
              tiles: [
                for (final log in logs)
                  ListTile(
                    leading: Image.asset(log.coverImagePath, width: 48, height: 48, fit: BoxFit.cover),
                    title: Text('${log.wornDate.year}.${log.wornDate.month}.${log.wornDate.day}'),
                    subtitle: Text(log.location),
                    onTap: () => context.go(AppRoute.styleLogViewer.replaceFirst(':id', log.id)),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoute.styleLogAdd),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/router/app_router.dart`의 `styleLogMain` 라우트 교체**

```dart
      GoRoute(
        path: AppRoute.styleLogMain,
        builder: (context, state) => const StyleLogMainScreen(),
      ),
```

- [ ] **Step 3: 실행 확인**

```bash
flutter run -d windows
```

Expected: `/style-log` 접속 시 최신순(log02, log01) 정렬된 리스트 표시, 탭하면 열람 화면으로 이동.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/style_log_main_screen.dart lib/router/app_router.dart
git commit -m "feat(screen): implement 스타일일지 메인"
```

---

### Task 15: 공용 컴포넌트(C6) + 화면 — 스타일일지 추가

**Files:**
- Create: `lib/widgets/binding_selection_modal.dart`
- Create: `lib/screens/style_log_add_screen.dart`
- Modify: `lib/router/app_router.dart:styleLogAdd 라우트`

**Interfaces:**
- Consumes: `closetItemsProvider` (Task 4), `GroupedGalleryGrid` (Task 6), `styleLogsProvider` (Task 4)
- Produces: `BindingSelectionModal.show(BuildContext, {required List<ClothingItem> items, required void Function(ClothingItem) onSelected})` — I2(재사용 원칙): 옷장 메인과 동일한 그리드를 모달로 재사용.

- [ ] **Step 1: `lib/widgets/binding_selection_modal.dart` 작성 (C6)**

```dart
import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../widgets/grouped_gallery_grid.dart';
import '../theme/app_spacing.dart' show AppDensity;

class BindingSelectionModal {
  BindingSelectionModal._();

  static Future<void> show(
    BuildContext context, {
    required List<ClothingItem> items,
    required void Function(ClothingItem item) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: GroupedGalleryGrid(
          items: items.where((i) => !i.isDeleted).toList(),
          density: AppDensity.mid,
          onItemTap: (item) {
            onSelected(item);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `lib/screens/style_log_add_screen.dart` 작성**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/clothing_item.dart';
import '../models/style_log.dart';
import '../providers/closet_providers.dart';
import '../providers/style_log_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/binding_selection_modal.dart';
import '../widgets/overlay_header.dart';
import '../widgets/sequential_slot_card.dart';

class StyleLogAddScreen extends ConsumerStatefulWidget {
  const StyleLogAddScreen({super.key});

  @override
  ConsumerState<StyleLogAddScreen> createState() => _StyleLogAddScreenState();
}

class _StyleLogAddScreenState extends ConsumerState<StyleLogAddScreen> {
  final List<ClothingItem> _linkedItems = [];

  @override
  Widget build(BuildContext context) {
    final closetItems = ref.watch(closetItemsProvider);

    return Scaffold(
      body: Column(
        children: [
          OverlayHeader(
            actions: [
              TextButton(
                onPressed: () {
                  final notifier = ref.read(styleLogsProvider.notifier);
                  notifier.state = [
                    ...notifier.state,
                    StyleLog(
                      id: 'log${notifier.state.length + 1}',
                      coverImagePath: _linkedItems.isEmpty ? '' : _linkedItems.first.imagePath,
                      wornDate: DateTime.now(),
                    ),
                  ];
                  context.pop();
                },
                child: const Text('저장'),
              ),
            ],
            child: Text('스타일일지 추가', style: Theme.of(context).textTheme.titleLarge),
          ),
          SequentialSlotCard(
            slots: [
              Container(
                color: Theme.of(context).colorScheme.secondary,
                child: const Center(child: Icon(Icons.add_a_photo, size: 48)),
              ),
              Container(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                child: const Center(child: Text('코디 연결 (선택)')),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: FilledButton(
              onPressed: () => BindingSelectionModal.show(
                context,
                items: closetItems,
                onSelected: (item) => setState(() => _linkedItems.add(item)),
              ),
              child: const Text('입은 옷 연결하기'),
            ),
          ),
          Expanded(
            child: ListView(
              children: [for (final item in _linkedItems) ListTile(title: Text(item.name))],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: `lib/router/app_router.dart`의 `styleLogAdd` 라우트 교체**

```dart
      GoRoute(
        path: AppRoute.styleLogAdd,
        builder: (context, state) => const StyleLogAddScreen(),
      ),
```

- [ ] **Step 4: 실행 확인**

```bash
flutter run -d windows
```

Expected: "입은 옷 연결하기" 버튼 → 옷장 메인과 동일한 그리드가 모달로 뜸 → 아이템 탭하면 목록에 추가됨.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/binding_selection_modal.dart lib/screens/style_log_add_screen.dart lib/router/app_router.dart
git commit -m "feat(screen): implement 스타일일지 추가 with BindingSelectionModal (reuses closet grid, I2)"
```

---

## Self-Review Notes

- **Spec coverage**: 스펙의 화면 10개 전부 Task 7~15에 매핑됨(설정/휴지통에 Trash+Settings 통합, 00_MVP.md §7 스크린 리스트와 동일한 통합 방식). 토큰(Task 2), 데이터/상태(Task 3~4), 라우팅(Task 5) 전부 커버.
- **Placeholder scan**: 없음 — 모든 코드 블록은 실행 가능한 완전한 코드. `AiProcessingStatus`는 `success` 고정이 스펙에서 의도한 제약(placeholder 아님).
- **Type/signature 일관성**: `ClothingItem`, `Composition`, `CompositionItemPlacement`, `StyleLog`(Task 3)의 필드명이 Task 4 provider, Task 6~15 화면/위젯 전체에서 동일하게 사용됨(`imagePath`, `wearCount`, `isIncomplete`, `linkedCompositionId` 등 재확인 완료). `AppRoute.*` 상수와 실제 `context.go()` 호출 전부 Task 5에서 정의한 경로 패턴과 일치.
- **컴포넌트 재사용 확인**: `GroupedGalleryGrid`(Task 6)는 Task 7(옷장 메인)과 Task 15(스타일일지 추가의 BindingSelectionModal)에서 재사용. `FlatFilterGallery`(Task 12)는 Task 14(스타일일지 메인)에서 재사용. `OverlayHeader`(Task 6)는 전 화면 공통 사용.
- **회귀 위험**: Task 5의 자리표시 라우트가 Task 7~15에서 순차적으로 실제 화면으로 교체되므로, 각 Task 완료 시점마다 `flutter run`으로 전체 네비게이션이 여전히 동작하는지 확인 필요(각 Task의 Step "실행 확인"에 이미 포함됨).
