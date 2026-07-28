// lib/widgets/interactive_artboard/artboard_overlap_popup.dart
import 'package:flutter/material.dart';
import 'artboard_item.dart';

/// 팝업 행의 썸네일 한 변 길이(논리픽셀) — `ListTile.leading` 표준 아이콘/썸네일
/// 크기에 맞춘 값, 목록 행 높이 안에서 라벨과 균형 있게 보이도록 고정한다.
const double _thumbnailSize = 40;

/// 겹친 아이템 목록을 z-순서(위→아래)로 보여주는, 터치 지점 근처에 뜨는 팝업 카드
/// (스펙 §4.5, 2026-07-19 리디자인). 호스팅(화면 위 위치 계산/배리어)은
/// `interactive_artboard.dart`의 `_openOverlapPopup`이 담당하고, 이 위젯은 카드
/// 내용(행 목록)만 책임진다.
/// - 행의 선택 아이콘/썸네일/라벨 탭 → [onSelect]
/// - 행 끝 드래그핸들로 재배열 → [onReorder](재배열된 새 순서의 id 리스트, 위→아래)
///
/// 탭(선택)과 드래그(재배열)의 히트영역을 분리한다 — `ReorderableListView`의
/// `buildDefaultDragHandles: false` + `ReorderableDragStartListener`로 드래그 트리거를
/// trailing 아이콘에만 한정하고, `ListTile.onTap`은 그대로 탭 선택에 쓴다.
class ArtboardOverlapPopup extends StatefulWidget {
  const ArtboardOverlapPopup({
    super.key,
    required this.items,
    required this.selectedItemId,
    required this.onSelect,
    required this.onReorder,
  });

  /// z-순서 내림차순(위→아래)으로 이미 정렬되어 들어온다.
  final List<ArtboardItem> items;

  /// 현재 아트보드에서 선택된 아이템 id — 이 목록에 포함돼 있으면 그 행만 강조 표시.
  final String? selectedItemId;
  final ValueChanged<String> onSelect;
  final ValueChanged<List<String>> onReorder;

  @override
  State<ArtboardOverlapPopup> createState() => _ArtboardOverlapPopupState();
}

class _ArtboardOverlapPopupState extends State<ArtboardOverlapPopup> {
  late final List<ArtboardItem> _order = List.of(widget.items);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ReorderableListView(
        shrinkWrap: true,
        buildDefaultDragHandles: false,
        // `onReorder`는 최신 Flutter SDK에서 deprecated 됐다(`onReorderItem`으로 대체,
        // newIndex를 oldIndex 제거분까지 이미 보정해 전달함) — 플랜 작성 시점 이후
        // SDK가 올라가며 생긴 차이라 여기서만 최신 API로 교체, 동작은 동일하다.
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            final moved = _order.removeAt(oldIndex);
            _order.insert(newIndex, moved);
          });
          widget.onReorder(_order.map((item) => item.id).toList());
        },
        children: [
          for (var i = 0; i < _order.length; i++) _row(context, _order[i], i, colorScheme),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ArtboardItem item, int index, ColorScheme colorScheme) {
    final isSelected = item.id == widget.selectedItemId;
    // Tester가 발견한 버그 수정: Container(color: ...)로 ListTile을 감싸면 Flutter가
    // "ListTile background color or ink splashes may be invisible" FlutterError를
    // 던진다(ListTile 내부가 Material 위젯을 전제하는데 색 있는 Container/ColoredBox가
    // 그 사이를 가로막기 때문) — ListTile 자신의 tileColor 파라미터가 정확히 이 용도로
    // 존재하므로 그걸 대신 쓴다.
    return ListTile(
      key: ValueKey(item.id),
      tileColor: isSelected ? colorScheme.primaryContainer : null,
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.check_circle_outline,
        color: isSelected ? colorScheme.primary : null,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            item.imagePath,
            width: _thumbnailSize,
            height: _thumbnailSize,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(item.id, overflow: TextOverflow.ellipsis)),
        ],
      ),
      onTap: () => widget.onSelect(item.id),
      trailing: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle),
      ),
    );
  }
}
