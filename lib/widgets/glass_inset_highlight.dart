import 'package:flutter/material.dart';
import '../theme/app_effects.dart';

/// 유리 표면 상단의 얇은 빛 반사선 — CSS `inset 0 1px 0 rgba(255,255,255,0.16)`(목업
/// 원본, `AppGlassEffect` docstring 참고) 근사. Flutter `BoxDecoration.boxShadow`는
/// inset을 지원하지 않아, 유리 표면 최상단에 이 위젯을 얹어 흉내낸다.
///
/// `Stack`의 자식으로 써야 한다(`Positioned` 사용) — [GlassPill]/[GlassCircleButton]/
/// `AppDetailScaffold._MoreMenuButton`처럼 `BackdropFilter` 다음에 이 위젯을 형제로
/// 두면, 부모 `ClipRRect`/`ClipOval`이 모서리를 잘라주므로 이 위젯 자신은 폭 전체를
/// 채우기만 해도 자연스럽게 둥근 모서리 안쪽에 맞아떨어진다(블러 대상이 아니라 블러
/// 위에 그대로 그려짐 — CSS inset shadow가 배경 블러와 별개로 표면 위에 그려지는 것과
/// 동일한 레이어 순서).
class GlassInsetHighlight extends StatelessWidget {
  const GlassInsetHighlight({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: AppGlassEffect.insetHighlightHeight,
        color: AppGlassEffect.insetHighlightColor,
      ),
    );
  }
}
