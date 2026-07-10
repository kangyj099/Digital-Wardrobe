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

/// T-Shape(코너 반경) — 옷장 메인 재설계 시 신설, Design Tokens에 역할명조차 없던 값이라
/// 여기서 처음 정의. 추후 Brand Guide/Design Tokens 문서에 정식 등재 검토 필요(TechnicalDebt 후보).
class AppRadius {
  AppRadius._();

  static const double sm = 16; // 드롭다운 패널
  static const double pill = 100; // 필 버튼(둥근 알약형)
}

/// Motion(애니메이션 지속시간) — Design Tokens에 `Motion.standard`라는 역할명만 있고 값이 없던 것을
/// 이 화면(옷장 메인, 속도 우선 유틸리티 화면) 기준으로 처음 채택. 다른 화면에도 재사용 전제.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 200); // 밀도 토글, FAB 회전 등 일반 전환
  static const Duration searchExpand = Duration(milliseconds: 300); // 검색창 확장/축소 전용(추후 Task 4에서 소비)
}
