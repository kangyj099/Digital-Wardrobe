// lib/widgets/interactive_artboard/static_artboard.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'artboard_background_color.dart';
import 'artboard_item.dart';
import 'artboard_item_view.dart';
import 'artboard_overlap_popup.dart';

/// 렌더 박스 대비 Hit Area 축소 비율 — `InteractiveArtboard`(`interactive_artboard.dart`)와
/// 동일한 값/근거(스펙 §2.2, 배경제거 이미지의 투명 여백을 터치판정에서 제외). 그 파일을
/// import해서 재사용하면 이 위젯이 편집용 상태/제스처 전체에 결합돼버리므로, 판정 로직만
/// 여기 독립적으로 복제한다(`interactive_artboard.dart`는 Task 지시에 따라 수정하지 않음).
const double _hitAreaInsetFactor = 0.85;

/// 겹침 팝업 카드의 고정 너비/여백/행 높이 추정치 — `InteractiveArtboard`와 동일한 값을
/// 그대로 재사용(같은 `ArtboardOverlapPopup`을 같은 방식으로 화면에 앵커링하므로 값이
/// 갈라지면 안 됨).
const double _overlapPopupCardWidth = 240.0;
const double _overlapPopupScreenMargin = 8.0;
const double _overlapPopupEstimatedRowHeight = 56.0;

/// 롱프레스 인정 시간 — 스펙 "아트보드의 옷 길게 누르기(1~2초)"(`02_코디 (가상 조합).md`
/// §코디 상세)의 범위 중간값. `GestureDetector.onLongPress`는 지속시간을 커스터마이즈할
/// 수 없어(고정 `kLongPressTimeout`=500ms) `onTapDown`/`onTapUp`/`onTapCancel` 조합 +
/// `Timer`로 직접 구현한다.
const Duration _longPressDuration = Duration(milliseconds: 1500);

/// 코디 상세(읽기 전용) 아트보드 — `InteractiveArtboard`와 같은 배치 규약(zIndex 순 페인트,
/// 정규화 x/y, scale/rotation)으로 [ArtboardItem]들을 그리기만 하는 정적 렌더 위젯.
/// 이동/회전/크기조절/핸들/배경색 변경 버튼/삭제존은 전혀 없다 — 오직 렌더링과 아래 두 개
/// 탭 인터랙션만 제공한다(스펙 §코디 상세):
/// - 단일 아이템 탭 → [onItemTap]
/// - 겹친 영역 탭 → [ArtboardOverlapPopup] 재사용해 대상 선택 팝업, 선택 시 마찬가지로
///   [onItemTap] 호출(재배열 UI는 `reorderable:false`로 숨김 — 이 화면은 읽기 전용이라
///   순서를 바꾸면 안 됨)
/// - 아이템 길게 누르기(1~2초) → [onEditRequested](파라미터 없음 — 편집 화면은 특정
///   아이템 선택 상태를 받지 않고 코디 전체를 여는 진입점이라 어떤 아이템을 눌렀는지는
///   구분하지 않는다)
///
/// 캔버스는 정사각형을 전제한다 — 호출부가 `AspectRatio(aspectRatio: 1)`로 감싼다.
class StaticArtboard extends StatefulWidget {
  const StaticArtboard({
    super.key,
    required this.items,
    required this.backgroundColor,
    required this.onItemTap,
    required this.onEditRequested,
    this.baseItemSizeFraction = 0.28,
    this.boundaryKey,
  });

  final List<ArtboardItem> items;
  final ArtboardBackgroundColor backgroundColor;
  final ValueChanged<String> onItemTap;
  final VoidCallback onEditRequested;

  /// 루트 `RepaintBoundary`에 부여하는 key — `composition_snapshot_capture.dart`가
  /// 오프스크린으로 이 위젯을 마운트해 `RenderRepaintBoundary.toImage()`로 캡처할 때
  /// 이 key로 해당 렌더 객체를 찾는다(`docs/reference/data/00_DataSchema.md` §13.1).
  /// 일반 사용(코디 상세의 인터랙티브 렌더링)에서는 넘기지 않는다(기본값 null).
  final Key? boundaryKey;

  /// 캔버스 짧은 변 대비 baseItemSize 비율 — `InteractiveArtboard.baseItemSizeFraction`과
  /// 동일 기본값(스펙 §2.1). 같은 코디 데이터를 편집기와 동일한 크기감으로 보여주기 위해
  /// 기본값을 맞춘다.
  final double baseItemSizeFraction;

  @override
  State<StaticArtboard> createState() => _StaticArtboardState();
}

class _StaticArtboardState extends State<StaticArtboard> {
  Timer? _longPressTimer;
  bool _longPressTriggered = false;
  OverlayEntry? _overlapPopupEntry;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    // remove()만으로는 부족하다 — OverlayEntry는 remove()(Overlay에서 분리)와
    // dispose()(리소스 해제)가 분리된 2단계 생명주기다(`interactive_artboard.dart`의
    // 동일 처리 참고).
    _overlapPopupEntry?..remove()..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = constraints.biggest;
        final baseItemSize = canvasSize.shortestSide * widget.baseItemSizeFraction;
        final sortedItems = [...widget.items]..sort((a, b) => a.zIndex.compareTo(b.zIndex));

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) => _handleTapDown(details, canvasSize, baseItemSize),
          onTapUp: (details) => _handleTapUp(details, canvasSize, baseItemSize),
          onTapCancel: _cancelLongPressTimer,
          child: RepaintBoundary(
            key: widget.boundaryKey,
            child: ColoredBox(
              color: widget.backgroundColor.value,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final item in sortedItems) _itemLayer(item, canvasSize, baseItemSize),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _itemLayer(ArtboardItem item, Size canvasSize, double baseItemSize) {
    final renderBoxSize = baseItemSize * item.scale;
    final centerX = canvasSize.width * item.x;
    final centerY = canvasSize.height * item.y;

    return Positioned(
      // 단순 `ValueKey(item.id)`를 쓰면 같은 화면(코디 상세) 안의 "사용된 옷" 목록이
      // 동일한 `clothingItemId`를 자기 타일 `GestureDetector`의 key로도 쓰고 있어
      // `find.byKey`류 조회가 중복 매치된다(Tester 관점 회귀 — 기존
      // `composition_detail_screen_test.dart`가 실제로 이렇게 깨짐) — 접두사로 scope를
      // 분리해 유일성을 보장한다.
      key: ValueKey('static-artboard-item-${item.id}'),
      left: centerX - renderBoxSize / 2,
      top: centerY - renderBoxSize / 2,
      width: renderBoxSize,
      height: renderBoxSize,
      child: Transform.rotate(
        angle: item.rotation,
        alignment: Alignment.center,
        child: RepaintBoundary(
          child: ArtboardItemView(item: item, renderBoxSize: renderBoxSize),
        ),
      ),
    );
  }

  /// [InteractiveArtboard._hitAreaContains]와 동일한 판정식(Hit Area = 렌더 박스를
  /// [_hitAreaInsetFactor]만큼 축소한, 회전 반영 사각형).
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

  List<ArtboardItem> _matchesAt(Offset point, Size canvasSize, double baseItemSize) {
    return widget.items
        .where((item) => _hitAreaContains(item, point, canvasSize, baseItemSize))
        .toList();
  }

  void _handleTapDown(TapDownDetails details, Size canvasSize, double baseItemSize) {
    _longPressTriggered = false;
    _longPressTimer?.cancel();
    final matches = _matchesAt(details.localPosition, canvasSize, baseItemSize);
    if (matches.isEmpty) return;
    _longPressTimer = Timer(_longPressDuration, () {
      _longPressTriggered = true;
      HapticFeedback.mediumImpact();
      widget.onEditRequested();
    });
  }

  void _cancelLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _handleTapUp(TapUpDetails details, Size canvasSize, double baseItemSize) {
    _cancelLongPressTimer();
    if (_longPressTriggered) {
      // 롱프레스가 이미 발동했으면(onEditRequested 호출됨) 손을 뗄 때 발생하는 탭까지
      // 겹쳐서 처리하지 않는다.
      _longPressTriggered = false;
      return;
    }
    final matches = _matchesAt(details.localPosition, canvasSize, baseItemSize)
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    if (matches.isEmpty) {
      return;
    } else if (matches.length == 1) {
      widget.onItemTap(matches.first.id);
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
                // 이 화면엔 지속되는 "선택 상태" 개념이 없다(강조는 아래 "사용된 옷"
                // 목록에서 잠깐 표시될 뿐, 팝업 자신은 무엇이 선택돼 있었는지 기억하지
                // 않음) — 항상 null.
                selectedItemId: null,
                // 읽기 전용 화면: 겹친 아이템의 렌더 순서를 바꾸면 안 되므로 드래그
                // 재배열 UI 자체를 감춘다(스펙 §코디 상세, Task B 지시).
                reorderable: false,
                onSelect: (id) {
                  _closeOverlapPopup();
                  widget.onItemTap(id);
                },
                onReorder: (_) {},
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
}
