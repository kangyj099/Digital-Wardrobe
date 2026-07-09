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
