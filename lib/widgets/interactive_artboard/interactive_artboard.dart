// lib/widgets/interactive_artboard/interactive_artboard.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'artboard_item.dart';
import 'artboard_item_view.dart';
import 'artboard_overlap_popup.dart';

/// 렌더 박스 대비 Hit Area 축소 비율 — 배경제거 옷 이미지의 투명 여백을 터치판정에서
/// 제외하기 위함(스펙 §2.2). 85%로 좁혀 실제 불투명 영역을 넉넉히 감싸되 여백은 배제.
/// 잠정값 — 스펙 §2.2가 요구하는 대로, Worker는 실제 배경제거 이미지로 시각 확인 후
/// 필요하면 이 값을 조정한다.
const double _hitAreaInsetFactor = 0.85;

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
  String? _draggingItemId;
  Offset _dragDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = constraints.biggest;
        final baseItemSize = canvasSize.shortestSide * widget.baseItemSizeFraction;
        final sortedItems = [...widget.items]
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
        final selectedIndex =
            widget.items.indexWhere((item) => item.id == widget.selectedItemId);
        final selectedItem = selectedIndex == -1 ? null : widget.items[selectedIndex];

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) => _handleTapUp(details, canvasSize, baseItemSize),
          child: Stack(
            key: _canvasKey,
            clipBehavior: Clip.none,
            children: [
              for (final item in sortedItems)
                _itemLayer(
                  item,
                  canvasSize,
                  baseItemSize,
                  isSelected: item.id == widget.selectedItemId,
                  includeInteraction: item.id != widget.selectedItemId,
                ),
              // 선택된 아이템의 몸체 히트테스트 영역은 paint 순서(zIndex)와 분리해
              // 항상 Stack 최상단에 별도로 그린다 — 팝업으로 선택한 아래쪽 아이템이
              // 위쪽 아이템에 가려져 있어도 계속 드래그로 조작할 수 있게 하기 위함
              // (스펙 §4.1). 이미지/아웃라인은 위 루프에서 이미 그렸으므로 여기선
              // 상호작용 레이어만 중복 없이 추가한다(includeVisual: false).
              if (selectedItem != null)
                _itemLayer(
                  selectedItem,
                  canvasSize,
                  baseItemSize,
                  isSelected: true,
                  includeInteraction: true,
                  includeVisual: false,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _itemLayer(
    ArtboardItem item,
    Size canvasSize,
    double baseItemSize, {
    required bool isSelected,
    required bool includeInteraction,
    bool includeVisual = true,
  }) {
    final renderBoxSize = baseItemSize * item.scale;
    final hitAreaSize = renderBoxSize * _hitAreaInsetFactor;
    var centerX = canvasSize.width * item.x;
    var centerY = canvasSize.height * item.y;
    if (item.id == _draggingItemId) {
      centerX += _dragDelta.dx;
      centerY += _dragDelta.dy;
    }
    return Positioned(
      // 같은 아이템이 자연 위치(시각)와 최상단 고정(상호작용) 두 곳에 각각 렌더링될
      // 수 있어(선택된 아이템, 아래 build()의 마지막 추가 호출 참고) 단순
      // ValueKey(item.id)만 쓰면 Stack 안에서 키가 중복돼 런타임 에러가 난다 —
      // includeVisual로 역할을 구분해 키를 유일하게 만든다.
      key: ValueKey('${item.id}:${includeVisual ? 'visual' : 'interactive'}'),
      left: centerX - renderBoxSize / 2,
      top: centerY - renderBoxSize / 2,
      width: renderBoxSize,
      height: renderBoxSize,
      child: Transform.rotate(
        angle: item.rotation,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (includeVisual) ArtboardItemView(item: item, renderBoxSize: renderBoxSize),
            if (includeVisual && isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            if (includeInteraction)
              SizedBox(
                width: hitAreaSize,
                height: hitAreaSize,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => _bodyDragStart(item),
                  onPanUpdate: (details) => _bodyDragUpdate(item, details, canvasSize),
                  onPanEnd: (_) => _bodyDragEnd(item, canvasSize),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _bodyDragStart(ArtboardItem item) {
    setState(() {
      _draggingItemId = item.id;
      _dragDelta = Offset.zero;
    });
  }

  void _bodyDragUpdate(ArtboardItem item, DragUpdateDetails details, Size canvasSize) {
    setState(() {
      _dragDelta += details.delta;
    });
  }

  void _bodyDragEnd(ArtboardItem item, Size canvasSize) {
    final dxNormalized = _dragDelta.dx / canvasSize.width;
    final dyNormalized = _dragDelta.dy / canvasSize.height;
    final updated = widget.items.map((current) {
      if (current.id != item.id) return current;
      return current.copyWith(x: current.x + dxNormalized, y: current.y + dyNormalized);
    }).toList();
    widget.onItemsChanged(updated);
    setState(() {
      _draggingItemId = null;
      _dragDelta = Offset.zero;
    });
  }

  /// 아이템의 Hit Area(렌더 박스를 [_hitAreaInsetFactor]만큼 축소한, 회전 반영 사각형)
  /// 안에 [point]가 들어가는지 판정한다(스펙 §2.2/§4.1).
  bool _hitAreaContains(
    ArtboardItem item,
    Offset point,
    Size canvasSize,
    double baseItemSize,
  ) {
    final renderBoxSize = baseItemSize * item.scale;
    final hitHalf = renderBoxSize * _hitAreaInsetFactor / 2;
    final centerX = canvasSize.width * item.x;
    final centerY = canvasSize.height * item.y;
    final dx = point.dx - centerX;
    final dy = point.dy - centerY;
    final cosT = math.cos(item.rotation);
    final sinT = math.sin(item.rotation);
    final localX = dx * cosT + dy * sinT;
    final localY = -dx * sinT + dy * cosT;
    return localX.abs() <= hitHalf && localY.abs() <= hitHalf;
  }

  void _handleTapUp(TapUpDetails details, Size canvasSize, double baseItemSize) {
    final matches = widget.items
        .where((item) =>
            _hitAreaContains(item, details.localPosition, canvasSize, baseItemSize))
        .toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    if (matches.isEmpty) {
      widget.onSelectionChanged(null);
    } else if (matches.length == 1) {
      widget.onSelectionChanged(matches.first.id);
    } else {
      _openOverlapPopup(matches);
    }
  }

  Future<void> _openOverlapPopup(List<ArtboardItem> matches) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => ArtboardOverlapPopup(
        items: matches,
        onSelect: (id) {
          Navigator.of(sheetContext).pop();
          widget.onSelectionChanged(id);
        },
        onReorder: (orderedIds) {
          // 겹친 아이템들이 원래 갖고 있던 zIndex 값 집합을 그대로 재사용하고
          // (0..N-1 같은 새 범위로 압축하지 않음), 순서만 새로 배정한다 — 캔버스에
          // 이 팝업에 없는 다른 아이템들이 이미 그 zIndex 값 사이사이를 차지하고
          // 있을 수 있어서, 새 범위로 압축하면 그 아이템들과 충돌해 전체 페인트
          // 순서가 조용히 어긋난다(리뷰 P1 반영).
          final originalZIndexesDescending = matches.map((item) => item.zIndex).toList()
            ..sort((a, b) => b.compareTo(a));
          final newZIndexById = <String, int>{
            for (var i = 0; i < orderedIds.length; i++)
              orderedIds[i]: originalZIndexesDescending[i],
          };
          final updated = widget.items.map((item) {
            final newZ = newZIndexById[item.id];
            return newZ == null ? item : item.copyWith(zIndex: newZ);
          }).toList();
          widget.onItemsChanged(updated);
        },
      ),
    );
  }
}
