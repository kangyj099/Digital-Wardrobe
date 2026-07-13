import 'package:flutter/material.dart';
import 'bottom_gradient_overlay.dart';
import 'top_gradient_overlay.dart';

/// 모든 Gallery(추후 Detail/Editor도 계약만 맞춰 재사용 예정) 화면이 공유하는 스크롤
/// 컨테이너 — `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`
/// §1/§6 "Flutter Implementation Contract"의 `AppScrollContainer` 구현체.
///
/// 실제 스크롤 가능 위젯(GridView 등)은 [builder]가 만들고, 이 위젯이 새로 만든
/// [ScrollController]를 그 위젯의 `controller`에 반드시 연결해야 한다 — 그래야 이
/// 컨테이너가 스크롤 위치(`scrollTop`/`scrollHeight`/`clientHeight`)를 관찰해
/// [TopGradientOverlay]/[BottomGradientOverlay]의 표시 조건(스펙 §2)을 계산할 수 있다.
///
/// Scrollbar Overlay(스펙 §3/§6)는 이번 스코프에 포함하지 않는다(`docs/work/BACKLOG.md`
/// 파킹로트) — 향후 추가 시 이 Stack의 children에 layer 하나만 더하면 된다.
class AppScrollContainer extends StatefulWidget {
  const AppScrollContainer({super.key, required this.builder});

  final Widget Function(BuildContext context, ScrollController controller) builder;

  @override
  State<AppScrollContainer> createState() => _AppScrollContainerState();
}

class _AppScrollContainerState extends State<AppScrollContainer> {
  final ScrollController _controller = ScrollController();
  bool _showTop = false;
  bool _showBottom = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    // 최초 프레임에서 maxScrollExtent가 확정된 뒤 한 번 더 계산 — 내용이 짧아 애초에
    // 스크롤이 불가능한 경우 bottom hint가 잘못 표시되는 것을 막는다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    // 스펙 §2 표시 조건 그대로: top은 "조금이라도 내렸으면", bottom은 "아래로 더 스크롤
    // 가능한 경우에만".
    final showTop = position.pixels > 2;
    final showBottom = position.pixels < position.maxScrollExtent - 2;
    if (showTop != _showTop || showBottom != _showBottom) {
      setState(() {
        _showTop = showTop;
        _showBottom = showBottom;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.builder(context, _controller),
        TopGradientOverlay(visible: _showTop),
        BottomGradientOverlay(visible: _showBottom),
      ],
    );
  }
}
