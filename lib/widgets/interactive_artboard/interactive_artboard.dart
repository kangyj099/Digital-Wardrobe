// lib/widgets/interactive_artboard/interactive_artboard.dart
import 'package:flutter/material.dart';
import 'artboard_item.dart';
import 'artboard_item_view.dart';

/// 코디 편집기 아트보드 — 배치/이동/회전/크기조절/겹침처리/삭제의 코어 상호작용을
/// 제공하는 완전 독립 위젯. `Composition`/`ClothingItem` 모델에 의존하지 않는다.
///
/// 선택 상태는 완전 외부 제어(controlled)다 — 위젯이 내부에 선택을 소유하지 않고
/// [selectedItemId]를 그대로 반영만 한다(스펙 §5).
class InteractiveArtboard extends StatefulWidget {
  const InteractiveArtboard({
    super.key,
    required this.items,
    required this.onItemsChanged,
    required this.onItemDeleted,
    required this.selectedItemId,
    required this.onSelectionChanged,
    this.baseItemSizeFraction = 0.28,
  });

  final List<ArtboardItem> items;
  final ValueChanged<List<ArtboardItem>> onItemsChanged;
  final ValueChanged<String> onItemDeleted;
  final String? selectedItemId;
  final ValueChanged<String?> onSelectionChanged;

  /// 캔버스 짧은 변 대비 baseItemSize 비율(스펙 §2.1, 권장 범위 25~30%의 중간값).
  final double baseItemSizeFraction;

  @override
  State<InteractiveArtboard> createState() => _InteractiveArtboardState();
}

class _InteractiveArtboardState extends State<InteractiveArtboard> {
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = constraints.biggest;
        final baseItemSize = canvasSize.shortestSide * widget.baseItemSizeFraction;
        final sortedItems = [...widget.items]
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

        return Stack(
          key: _canvasKey,
          clipBehavior: Clip.none,
          children: [
            for (final item in sortedItems)
              _positioned(item, canvasSize, baseItemSize),
          ],
        );
      },
    );
  }

  Widget _positioned(ArtboardItem item, Size canvasSize, double baseItemSize) {
    final renderBoxSize = baseItemSize * item.scale;
    final centerX = canvasSize.width * item.x;
    final centerY = canvasSize.height * item.y;
    return Positioned(
      left: centerX - renderBoxSize / 2,
      top: centerY - renderBoxSize / 2,
      width: renderBoxSize,
      height: renderBoxSize,
      child: Transform.rotate(
        angle: item.rotation,
        alignment: Alignment.center,
        child: ArtboardItemView(item: item, renderBoxSize: renderBoxSize),
      ),
    );
  }
}
