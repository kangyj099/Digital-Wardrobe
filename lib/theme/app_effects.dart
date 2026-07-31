import 'dart:ui';

/// 프로스티드 글래스(Frosted Glass) 효과 상수/헬퍼 — [GlassPill]/[GlassCircleButton]/
/// `AppDetailScaffold._MoreMenuButton`이 각자 매직넘버를 들고 있지 않도록 한 곳에 모은다
/// (DRY, `docs/history/Decision.md` "Header/HUD Pinned Rule"이 요구하는 시각 스타일 공유).
///
/// 근거: 목업 원본 CSS(`참고자료/목업/옷장 메인/옷장 메인.html`, `옷장 메인 화면.txt` 34행)
/// `backdrop-filter: blur(3px) saturate(180%)`,
/// `box-shadow: 0 2px 10px var(--shadow), inset 0 1px 0 rgba(255,255,255,0.16)`.
class AppGlassEffect {
  AppGlassEffect._();

  /// CSS `blur(3px)`의 Flutter `ImageFilter.blur` sigma 근사값.
  /// CSS blur radius ≈ 2 × Gaussian sigma(브라우저 구현 기준 통용 근사식) → 3px ÷ 2 = 1.5.
  /// (교정 전 코드는 sigma 12를 썼는데, 이 근사식 기준 CSS blur(24px)에 해당해 목업 대비
  /// 약 8배 과했다.)
  static const double blurSigma = 1.5;

  /// CSS `saturate(180%)` 근사 — 표준 SVG `feColorMatrix type="saturate"` 공식(CSS
  /// `saturate()`가 내부적으로 쓰는 것과 동일한 행렬)에 s=1.8을 대입해 구성한 채도 보정
  /// `ColorFilter`. `ColorFilter`는 `ImageFilter`를 구현하므로 [backdropFilter]의
  /// `ImageFilter.compose`에 그대로 합성할 수 있다.
  static const ColorFilter saturationBoost = ColorFilter.matrix(<double>[
    0.213 + 0.787 * 1.8, 0.715 - 0.715 * 1.8, 0.072 - 0.072 * 1.8, 0, 0,
    0.213 - 0.213 * 1.8, 0.715 + 0.285 * 1.8, 0.072 - 0.072 * 1.8, 0, 0,
    0.213 - 0.213 * 1.8, 0.715 - 0.715 * 1.8, 0.072 + 0.928 * 1.8, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  /// [GlassPill]류가 `BackdropFilter.filter`에 그대로 넘길 합성 필터.
  ///
  /// CSS `filter` 목록은 왼쪽부터 순서대로 적용된다(`blur(3px) saturate(180%)` → 블러
  /// 먼저, 채도 나중). Flutter `ImageFilter.compose`는 반대로 `inner`가 먼저, `outer`가
  /// 나중에 적용되므로 `inner`에 블러, `outer`에 채도 보정을 둬야 CSS와 동일한 순서가 된다.
  static ImageFilter backdropFilter() => ImageFilter.compose(
        outer: saturationBoost,
        inner: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      );

  /// CSS `inset 0 1px 0 rgba(255,255,255,0.16)`(유리 상단 얇은 빛 반사선) 근사 — Flutter
  /// `BoxDecoration.boxShadow`는 inset을 지원하지 않아, 호출부가 유리 표면 최상단에 이
  /// 높이/색으로 얇은 `Container`를 얹어 흉내낸다.
  static const double insetHighlightHeight = 1;
  static const Color insetHighlightColor = Color(0x29FFFFFF); // white, alpha 0.16 ≈ 0x29/0xFF
}
