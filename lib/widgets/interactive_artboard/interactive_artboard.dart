// lib/widgets/interactive_artboard/interactive_artboard.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'artboard_background_color.dart';
import 'artboard_item.dart';
import 'artboard_item_view.dart';
import 'artboard_overlap_popup.dart';

/// 렌더 박스 대비 Hit Area 축소 비율 — 배경제거 옷 이미지의 투명 여백을 터치판정에서
/// 제외하기 위함(스펙 §2.2). 85%로 좁혀 실제 불투명 영역을 넉넉히 감싸되 여백은 배제.
/// 잠정값 — 스펙 §2.2가 요구하는 대로, Worker는 실제 배경제거 이미지로 시각 확인 후
/// 필요하면 이 값을 조정한다.
const double _hitAreaInsetFactor = 0.85;

/// scale 하한/상한 — 너무 작아지면 조작 불가, 너무 커지면 캔버스를 벗어나 보기
/// 어려워짐(스펙 §4.3).
const double _minScale = 0.3;
const double _maxScale = 3.0;

/// 핸들이 아이템 중심에서 최소 이만큼은 떨어지도록 하는 오프셋(논리픽셀) — 44px
/// 접근성 최소 터치영역 권장 기준의 절반(스펙 §4.4).
const double _minHandleOffset = 24.0;

/// 핸들 원형 시각/히트 크기(논리픽셀) — 44x44 접근성 최소 터치영역 기준을 그대로
/// 적용(`flutter-implementation-conventions` Review 체크리스트 "터치 타겟 44×44
/// 이상"). 32px로는 이 기준에 못 미쳤던 걸 리뷰에서 지적받아 수정.
const double _handleVisualDiameter = 44.0;

/// 회전 핸들이 상단 모서리에서 위로 뻗는 연결선 길이(논리픽셀).
const double _rotateStemLength = 20.0;

/// 아이템 렌더 박스를 감싸는 상호작용 레이어의 여유 마진(논리픽셀) — 핸들(특히
/// 회전 핸들의 줏대)이 렌더 박스 경계 밖으로 튀어나오는데, `Positioned`에 크기를
/// 명시하면 `RenderBox.hitTest`가 딱 그 크기 안에서만 자식으로 히트테스트를
/// 위임한다(`Clip.none`은 페인트 오버플로만 허용하고 히트테스트엔 영향 없음) —
/// 그래서 레이어 자체를 핸들 최대 도달 거리보다 넉넉히 키워서, 핸들이 항상 이
/// 레이어의 히트테스트 가능 영역 안에 들어오게 한다(리뷰 P0 반영).
const double _handleLayerMargin = _minHandleOffset + _rotateStemLength + _handleVisualDiameter;

/// 겹침 팝업 카드의 고정 너비(논리픽셀) — 화면 경계 클램핑 계산을 단순하게 하려고
/// 카드 폭을 고정한다(내용은 세로로만 늘어남).
const double _overlapPopupCardWidth = 240.0;

/// 팝업 카드가 화면 가장자리에서 최소한 이만큼은 떨어지도록 하는 여백(논리픽셀).
const double _overlapPopupScreenMargin = 8.0;

/// 팝업 행 1개의 예상 높이(논리픽셀) — Tester가 실측한 실제 값(항목 2개일 때 카드
/// 높이 112px → 행당 56px, Flutter 기본 ListTile 높이와 일치)을 그대로 사용한다.
/// 화면 하단 경계 클램프 계산 전용 근사치다 — 실제 레이아웃 전에는 정확한 카드 높이를
/// 알 수 없다(Tester 발견 버그 반영: 기존엔 세로 클램프가 카드 높이를 전혀 고려하지
/// 않아 화면 하단 근처에서 열면 카드가 화면 밖으로 넘어갔다).
const double _overlapPopupEstimatedRowHeight = 56.0;

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
    required this.backgroundColor,
    required this.onBackgroundColorChanged,
    this.baseItemSizeFraction = 0.28,
  });

  final List<ArtboardItem> items;
  final ValueChanged<List<ArtboardItem>> onItemsChanged;
  final ValueChanged<String> onItemDeleted;
  final String? selectedItemId;
  final ValueChanged<String?> onSelectionChanged;
  final ArtboardBackgroundColor backgroundColor;
  final ValueChanged<ArtboardBackgroundColor> onBackgroundColorChanged;

  /// 캔버스 짧은 변 대비 baseItemSize 비율(스펙 §2.1, 권장 범위 25~30%의 중간값).
  final double baseItemSizeFraction;

  @override
  State<InteractiveArtboard> createState() => _InteractiveArtboardState();
}

class _InteractiveArtboardState extends State<InteractiveArtboard> {
  final GlobalKey _canvasKey = GlobalKey();
  String? _draggingItemId;
  Offset _dragDelta = Offset.zero;

  String? _resizingItemId;
  double _resizeStartDistance = 0;
  double _resizeStartScale = 1;
  double? _liveScale;

  String? _rotatingItemId;
  double _rotateStartAngleOffset = 0;
  double? _liveRotation;

  OverlayEntry? _deleteZoneOverlayEntry;
  bool _isOutOfBounds = false;

  OverlayEntry? _overlapPopupEntry;

  bool _isSwatchExpanded = false;

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
          child: ColoredBox(
            color: widget.backgroundColor.value,
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
                Positioned(
                  right: _backgroundColorButtonMargin,
                  bottom: _backgroundColorButtonMargin,
                  child: _backgroundColorButton(),
                ),
                if (_isSwatchExpanded)
                  Positioned(
                    // top:0 + bottom: 함께 지정 — 두 값을 다 주면 Stack이 이 자식에게
                    // "캔버스 상단부터 버튼 바로 위까지"로 꽉 채운 높이 제약을 준다(shrink-wrap
                    // 아님). 그래서 스와치 리스트의 히트테스트 가능 영역이 캔버스 자기 크기가
                    // 아무리 작아도 항상 [0, canvasHeight] 안에 있음이 보장된다 — bottom만
                    // 쓰던 예전 버전은 리스트가 자기 콘텐츠 크기(200px)만큼 위로 자연스럽게
                    // 커져서, 캔버스가 그보다 작으면 맨 위 스와치가 캔버스 박스 밖으로 나가
                    // 눌리지 않는 버그가 있었다(Tester 확인, 핸들 때와 같은 종류의 버그).
                    //
                    // 이 박스(top:0~bottom) 안에서 실제 스와치 목록이 차지하는 위치는
                    // LayoutBuilder+ConstrainedBox(minHeight)+Align(bottomCenter) 조합으로
                    // 한 번 더 조정한다 — 박스가 콘텐츠(200px)보다 넉넉하면(일반 크기 캔버스)
                    // Align이 콘텐츠를 박스 하단(=버튼 바로 위)에 붙여서, 위 top:0을 추가하기
                    // 전 "버튼에 딱 붙어 위로 자라는" 예전 앵커와 동일한 자리에 렌더된다.
                    // 박스가 콘텐츠보다 작으면(작은 캔버스) ConstrainedBox의 minHeight가
                    // 남는 공간이 없게 만들어 Align이 사실상 무력화되고, 콘텐츠가 박스 맨
                    // 위부터 채워지며 SingleChildScrollView로 스크롤해 모든 스와치에 닿을 수
                    // 있다.
                    top: 0,
                    right: _backgroundColorButtonMargin,
                    bottom: _backgroundColorButtonMargin +
                        _backgroundColorButtonDiameter +
                        _backgroundSwatchSpacing,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _backgroundSwatchList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Offset _toCanvasLocal(Offset globalPosition) {
    final renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }

  Widget _itemLayer(
    ArtboardItem item,
    Size canvasSize,
    double baseItemSize, {
    required bool isSelected,
    required bool includeInteraction,
    bool includeVisual = true,
  }) {
    final effectiveScale =
        (item.id == _resizingItemId && _liveScale != null) ? _liveScale! : item.scale;
    final effectiveRotation = (item.id == _rotatingItemId && _liveRotation != null)
        ? _liveRotation!
        : item.rotation;
    final renderBoxSize = baseItemSize * effectiveScale;
    final hitAreaSize = renderBoxSize * _hitAreaInsetFactor;
    final layerSize = renderBoxSize + 2 * _handleLayerMargin;
    final layerCenter = layerSize / 2;
    var centerX = canvasSize.width * item.x;
    var centerY = canvasSize.height * item.y;
    if (item.id == _draggingItemId) {
      centerX += _dragDelta.dx;
      centerY += _dragDelta.dy;
    }
    final handleOffset = math.max(renderBoxSize / 2, _minHandleOffset);

    return Positioned(
      // 같은 아이템이 자연 위치(시각)와 최상단 고정(상호작용) 두 곳에 각각 렌더링될
      // 수 있어(선택된 아이템, 아래 build()의 마지막 추가 호출 참고) 단순
      // ValueKey(item.id)만 쓰면 Stack 안에서 키가 중복돼 런타임 에러가 난다 —
      // includeVisual로 역할을 구분해 키를 유일하게 만든다.
      key: ValueKey('${item.id}:${includeVisual ? 'visual' : 'interactive'}'),
      left: centerX - layerSize / 2,
      top: centerY - layerSize / 2,
      width: layerSize,
      height: layerSize,
      child: Transform.rotate(
        angle: effectiveRotation,
        alignment: Alignment.center,
        child: Stack(
          children: [
            if (includeVisual)
              Positioned(
                left: layerCenter - renderBoxSize / 2,
                top: layerCenter - renderBoxSize / 2,
                width: renderBoxSize,
                height: renderBoxSize,
                child: RepaintBoundary(
                  child: ArtboardItemView(item: item, renderBoxSize: renderBoxSize),
                ),
              ),
            if (includeVisual && isSelected)
              Positioned(
                left: layerCenter - renderBoxSize / 2,
                top: layerCenter - renderBoxSize / 2,
                width: renderBoxSize,
                height: renderBoxSize,
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
              Positioned(
                left: layerCenter - hitAreaSize / 2,
                top: layerCenter - hitAreaSize / 2,
                width: hitAreaSize,
                height: hitAreaSize,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => _bodyDragStart(item),
                  onPanUpdate: (details) => _bodyDragUpdate(item, details, canvasSize),
                  onPanEnd: (_) => _bodyDragEnd(item, canvasSize),
                ),
              ),
            if (includeInteraction && isSelected)
              ..._buildHandles(item, layerCenter, handleOffset, canvasSize),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHandles(
    ArtboardItem item,
    double center,
    double handleOffset,
    Size canvasSize,
  ) {
    return [
      // 이동 핸들 — 좌하단
      _handle(
        left: center - handleOffset - _handleVisualDiameter / 2,
        top: center + handleOffset - _handleVisualDiameter / 2,
        label: '이동 핸들',
        onPanStart: (_) => _bodyDragStart(item),
        onPanUpdate: (details) => _bodyDragUpdate(item, details, canvasSize),
        onPanEnd: (_) => _bodyDragEnd(item, canvasSize),
      ),
      // 크기조절 핸들 — 우하단
      _handle(
        left: center + handleOffset - _handleVisualDiameter / 2,
        top: center + handleOffset - _handleVisualDiameter / 2,
        label: '크기조절 핸들',
        onPanStart: (details) => _resizeDragStart(item, details, canvasSize),
        onPanUpdate: (details) => _resizeDragUpdate(item, details, canvasSize),
        onPanEnd: (_) => _resizeDragEnd(item),
      ),
      // 회전 핸들 — 상단 중앙에서 위로 뻗은 연결선 끝
      _handle(
        left: center - _handleVisualDiameter / 2,
        top: center - handleOffset - _rotateStemLength - _handleVisualDiameter / 2,
        label: '회전 핸들',
        onPanStart: (details) => _rotateDragStart(item, details, canvasSize),
        onPanUpdate: (details) => _rotateDragUpdate(item, details, canvasSize),
        onPanEnd: (_) => _rotateDragEnd(item),
      ),
    ];
  }

  Widget _handle({
    required double left,
    required double top,
    required String label,
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Semantics(
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          child: Container(
            width: _handleVisualDiameter,
            height: _handleVisualDiameter,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _resizeDragStart(ArtboardItem item, DragStartDetails details, Size canvasSize) {
    final canvasCenter = Offset(canvasSize.width * item.x, canvasSize.height * item.y);
    final pointerLocal = _toCanvasLocal(details.globalPosition);
    _resizeStartDistance = (pointerLocal - canvasCenter).distance;
    _resizeStartScale = item.scale;
    setState(() {
      _resizingItemId = item.id;
      _liveScale = item.scale;
    });
  }

  void _resizeDragUpdate(ArtboardItem item, DragUpdateDetails details, Size canvasSize) {
    if (_resizeStartDistance == 0) return;
    final canvasCenter = Offset(canvasSize.width * item.x, canvasSize.height * item.y);
    final pointerLocal = _toCanvasLocal(details.globalPosition);
    final currentDistance = (pointerLocal - canvasCenter).distance;
    final rawScale = _resizeStartScale * (currentDistance / _resizeStartDistance);
    setState(() {
      _liveScale = rawScale.clamp(_minScale, _maxScale);
    });
  }

  void _resizeDragEnd(ArtboardItem item) {
    final finalScale = _liveScale ?? item.scale;
    final updated = widget.items.map((current) {
      if (current.id != item.id) return current;
      return current.copyWith(scale: finalScale);
    }).toList();
    widget.onItemsChanged(updated);
    setState(() {
      _resizingItemId = null;
      _liveScale = null;
    });
  }

  void _rotateDragStart(ArtboardItem item, DragStartDetails details, Size canvasSize) {
    final canvasCenter = Offset(canvasSize.width * item.x, canvasSize.height * item.y);
    final pointerLocal = _toCanvasLocal(details.globalPosition);
    final pointerAngle = math.atan2(
      pointerLocal.dy - canvasCenter.dy,
      pointerLocal.dx - canvasCenter.dx,
    );
    _rotateStartAngleOffset = pointerAngle - item.rotation;
    setState(() {
      _rotatingItemId = item.id;
      _liveRotation = item.rotation;
    });
  }

  void _rotateDragUpdate(ArtboardItem item, DragUpdateDetails details, Size canvasSize) {
    final canvasCenter = Offset(canvasSize.width * item.x, canvasSize.height * item.y);
    final pointerLocal = _toCanvasLocal(details.globalPosition);
    final pointerAngle = math.atan2(
      pointerLocal.dy - canvasCenter.dy,
      pointerLocal.dx - canvasCenter.dx,
    );
    setState(() {
      _liveRotation = pointerAngle - _rotateStartAngleOffset;
    });
  }

  void _rotateDragEnd(ArtboardItem item) {
    final finalRotation = _liveRotation ?? item.rotation;
    final updated = widget.items.map((current) {
      if (current.id != item.id) return current;
      return current.copyWith(rotation: finalRotation);
    }).toList();
    widget.onItemsChanged(updated);
    setState(() {
      _rotatingItemId = null;
      _liveRotation = null;
    });
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
    final centerX = canvasSize.width * item.x + _dragDelta.dx;
    final centerY = canvasSize.height * item.y + _dragDelta.dy;
    final outOfBounds = _isCenterOutOfBounds(centerX, centerY, canvasSize);
    if (outOfBounds && !_isOutOfBounds) {
      HapticFeedback.mediumImpact();
      _showDeleteZoneOverlay();
    } else if (!outOfBounds && _isOutOfBounds) {
      _hideDeleteZoneOverlay();
    }
    _isOutOfBounds = outOfBounds;
  }

  void _bodyDragEnd(ArtboardItem item, Size canvasSize) {
    _hideDeleteZoneOverlay();
    if (_isOutOfBounds) {
      widget.onItemDeleted(item.id);
      setState(() {
        _draggingItemId = null;
        _dragDelta = Offset.zero;
        _isOutOfBounds = false;
      });
      return;
    }
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
      _isOutOfBounds = false;
    });
  }

  bool _isCenterOutOfBounds(double centerX, double centerY, Size canvasSize) {
    return centerX < 0 || centerX > canvasSize.width || centerY < 0 || centerY > canvasSize.height;
  }

  void _showDeleteZoneOverlay() {
    _deleteZoneOverlayEntry = OverlayEntry(
      builder: (context) => const Positioned.fill(
        child: IgnorePointer(
          child: _DeleteZoneVisual(),
        ),
      ),
    );
    Overlay.of(context).insert(_deleteZoneOverlayEntry!);
  }

  void _hideDeleteZoneOverlay() {
    // remove()만으로는 부족하다 — OverlayEntry는 remove()(Overlay에서 분리)와
    // dispose()(리소스 해제, 누수추적 훅 발동)가 분리된 2단계 생명주기다
    // (Flutter `OverlayEntry` 문서: "remove must be called before dispose").
    // 매번 새 OverlayEntry를 만들므로 이 호출을 빠뜨리면 누적 누수가 생긴다(리뷰 P1 반영).
    _deleteZoneOverlayEntry?..remove()..dispose();
    _deleteZoneOverlayEntry = null;
  }

  @override
  void dispose() {
    _deleteZoneOverlayEntry?..remove()..dispose();
    _overlapPopupEntry?..remove()..dispose();
    super.dispose();
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
    if (_isSwatchExpanded) {
      setState(() => _isSwatchExpanded = false);
      return;
    }
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
      _openOverlapPopup(matches, details.globalPosition);
    }
  }

  void _openOverlapPopup(List<ArtboardItem> matches, Offset anchorGlobalPosition) {
    _overlapPopupEntry = OverlayEntry(
      builder: (overlayContext) {
        final screenSize = MediaQuery.of(overlayContext).size;
        final left = anchorGlobalPosition.dx.clamp(
          _overlapPopupScreenMargin,
          screenSize.width - _overlapPopupCardWidth - _overlapPopupScreenMargin,
        );
        // Tester가 발견한 버그 수정: 카드의 실제 렌더 높이는 항목 개수에 따라
        // 달라져서 레이아웃 전에는 알 수 없다 — _overlapPopupEstimatedRowHeight로
        // 추정한 높이를 빼서 하단 경계도 함께 클램프한다. math.max로 화면이 카드보다
        // 작은 극단적인 경우(항목이 아주 많을 때)에도 clamp()의 lower<=upper 불변식이
        // 깨지지 않게 방어한다.
        final estimatedCardHeight = matches.length * _overlapPopupEstimatedRowHeight;
        final maxTop = math.max(
          _overlapPopupScreenMargin,
          screenSize.height - estimatedCardHeight - _overlapPopupScreenMargin,
        );
        final top = anchorGlobalPosition.dy.clamp(_overlapPopupScreenMargin, maxTop);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeOverlapPopup,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: _overlapPopupCardWidth,
              child: ArtboardOverlapPopup(
                items: matches,
                selectedItemId: widget.selectedItemId,
                onSelect: (id) {
                  _closeOverlapPopup();
                  widget.onSelectionChanged(id);
                },
                onReorder: (orderedIds) {
                  // 겹친 아이템들이 원래 갖고 있던 zIndex 값 집합을 그대로 재사용하고
                  // (0..N-1 같은 새 범위로 압축하지 않음), 순서만 새로 배정한다 —
                  // 캔버스에 이 팝업에 없는 다른 아이템들이 이미 그 zIndex 값
                  // 사이사이를 차지하고 있을 수 있어서, 새 범위로 압축하면 그
                  // 아이템들과 충돌해 전체 페인트 순서가 조용히 어긋난다(리뷰 P1 반영).
                  final originalZIndexesDescending =
                      matches.map((item) => item.zIndex).toList()
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
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlapPopupEntry!);
  }

  void _closeOverlapPopup() {
    _overlapPopupEntry?..remove()..dispose();
    _overlapPopupEntry = null;
  }

  Widget _backgroundColorButton() {
    return Semantics(
      label: '배경색 버튼',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _isSwatchExpanded = !_isSwatchExpanded),
        child: _swatchCircle(
          fillColor: widget.backgroundColor.value,
          diameter: _backgroundColorButtonDiameter,
        ),
      ),
    );
  }

  /// 배경색 버튼/스와치 원 — 테두리 선 대신 그림자/하이라이트/이너글로우로 구분해
  /// 달라는 요청(2026-07-27)에 따른 것. 처음엔 이 셋을 전부 `BoxDecoration.boxShadow`
  /// 한 리스트에 넣었는데, `BoxDecoration`은 `boxShadow`를 먼저 그리고 그 위에 `color`를
  /// 덮어그린다(`box_decoration.dart`의 `paint()`: `_paintShadows` 다음 `_paintBackgroundColor`)
  /// — 그래서 원 안쪽으로 파고드는 그림자는 전부 불투명한 원 색에 가려져 안 보였다.
  /// `glass_pill.dart`/`glass_circle_button.dart`가 이미 쓰던 해법을 그대로 따른다:
  /// 그림자는 **색이 없는 바깥 Container**에서, 실제 색은 **별도의 안쪽 레이어**에서
  /// 칠해 서로 덮어쓰지 않게 분리한다. 이너글로우는 애초에 `BoxShadow`로 못 만든다
  /// (안쪽에 그려도 결국 같은 문제) — 대신 색 위에 겹쳐 그리는 `RadialGradient`
  /// 오버레이로 가장자리 안쪽을 밝힌다.
  Widget _swatchCircle({required Color fillColor, required double diameter}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // 은은하게 퍼지는 외곽 그림자 — 원이 캔버스 위에 살짝 떠 있는 듯한 존재감
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          // 부드러운 하이라이트 글로우 — "누를 수 있는 요소"라는 신호. primary 톤을
          // 얕게 둘러 스와치 자체 색(흰색 포함)에 기대지 않고 항상 시인성을 확보
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 캔버스 배경색과 달리 여기선 `ColoredBox`를 안 쓴다 — 기존 테스트가
            // `find.byType(ColoredBox)`로 "캔버스 배경색 하나"를 단수 조회하는데,
            // 스와치 안쪽 색칠에도 `ColoredBox`를 쓰면(`Container(color: ...)`도 내부적으로
            // `ColoredBox`로 빌드된다) 개수가 여러 개가 되어 그 조회가 깨진다(Tester 발견).
            // `DecoratedBox`는 다른 위젯 타입이라 이 충돌이 없다.
            DecoratedBox(decoration: BoxDecoration(color: fillColor)),
            // 이너글로우 — 색 위에 겹쳐 그려야 실제로 보인다(위 doc 참고). 중심은
            // 완전히 투명하게 둬서 스와치 색 자체가 그대로 보이고, 가장자리 쪽에만
            // 밝은 링이 겹쳐 유리알 같은 입체감을 준다.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.transparent, Colors.white38],
                  stops: [0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backgroundSwatchList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in ArtboardBackgroundColor.values) ...[
          _backgroundSwatch(option),
          if (option != ArtboardBackgroundColor.values.last)
            const SizedBox(height: _backgroundSwatchSpacing),
        ],
      ],
    );
  }

  Widget _backgroundSwatch(ArtboardBackgroundColor option) {
    return Semantics(
      label: '배경색: ${option.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onBackgroundColorChanged(option);
          setState(() => _isSwatchExpanded = false);
        },
        child: _swatchCircle(fillColor: option.value, diameter: _backgroundSwatchDiameter),
      ),
    );
  }

}

/// 딤드 오버레이의 반투명도 — 아이템이 삭제 가능 상태임을 알아볼 수 있을 만큼
/// 어둡히되 밑에 있던 캔버스 형태가 여전히 비치는 정도(스펙 §4.6, 정확한 수치는
/// Worker 재량).
const double _deleteZoneDimAlpha = 0.4;

/// 휴지통 아이콘을 화면 하단에서 띄우는 여백(논리픽셀) — 하단 안전영역에 아이콘이
/// 바짝 붙지 않도록 하는 시각적 여유.
const double _deleteZoneIconBottomPadding = 32.0;

/// 휴지통 아이콘 크기(논리픽셀) — 화면 전체를 덮는 딤드 오버레이 위에서 눈에 띄게
/// 하려고 핸들(44px)보다 큰 크기로 잡음.
const double _deleteZoneIconSize = 48.0;

/// 배경색 버튼 지름(논리픽셀) — 핸들(44px)과 동일한 접근성 최소 터치영역.
const double _backgroundColorButtonDiameter = 44.0;

/// 배경색 버튼이 캔버스 모서리에서 떨어지는 여백(논리픽셀).
const double _backgroundColorButtonMargin = 16.0;

/// 배경색 스와치 원 지름(논리픽셀) — 버튼과 동일 크기로 시각 통일.
const double _backgroundSwatchDiameter = 44.0;

/// 스와치끼리, 버튼-첫 스와치 사이의 세로 간격(논리픽셀).
const double _backgroundSwatchSpacing = 8.0;

/// 아이템을 캔버스 밖으로 드래그할 때 [Overlay]에 그리는 딤드+휴지통 아이콘 시각
/// 피드백(스펙 §4.6) — `interactive_artboard.dart`의 `RenderBox` 경계에 갇히지 않도록
/// `Overlay`를 통해 화면 전체 위에 그린다.
class _DeleteZoneVisual extends StatelessWidget {
  const _DeleteZoneVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black.withValues(alpha: _deleteZoneDimAlpha)),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: _deleteZoneIconBottomPadding),
            child: Icon(Icons.delete, color: Colors.white, size: _deleteZoneIconSize),
          ),
        ),
      ],
    );
  }
}
