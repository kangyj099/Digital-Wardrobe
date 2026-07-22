// lib/widgets/interactive_artboard/artboard_overlap_popup.dart
import 'package:flutter/material.dart';
import 'artboard_item.dart';

/// 팝업 행의 썸네일 한 변 길이(논리픽셀) — `ListTile.leading` 표준 아이콘/썸네일
/// 크기에 맞춘 값, 목록 행 높이 안에서 라벨과 균형 있게 보이도록 고정한다.
const double _thumbnailSize = 40;

/// 겹친 아이템 목록을 z-순서(위→아래)로 보여주는 팝업(스펙 §4.5).
/// - 행의 썸네일/라벨 탭 → [onSelect]
/// - 행 끝 드래그핸들로 재배열 → [onReorder](재배열된 새 순서의 id 리스트, 위→아래)
///
/// 탭(선택)과 드래그(재배열)의 히트영역을 분리한다 — `ReorderableListView`의
/// `buildDefaultDragHandles: false` + `ReorderableDragStartListener`로 드래그 트리거를
/// trailing 아이콘에만 한정하고, `ListTile.onTap`은 그대로 탭 선택에 쓴다.
class ArtboardOverlapPopup extends StatefulWidget {
  const ArtboardOverlapPopup({
    super.key,
    required this.items,
    required this.onSelect,
    required this.onReorder,
  });

  /// z-순서 내림차순(위→아래)으로 이미 정렬되어 들어온다.
  final List<ArtboardItem> items;
  final ValueChanged<String> onSelect;
  final ValueChanged<List<String>> onReorder;

  @override
  State<ArtboardOverlapPopup> createState() => _ArtboardOverlapPopupState();
}

class _ArtboardOverlapPopupState extends State<ArtboardOverlapPopup> {
  late final List<ArtboardItem> _order = List.of(widget.items);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
          for (var i = 0; i < _order.length; i++)
            ListTile(
              key: ValueKey(_order[i].id),
              leading: Image.asset(
                _order[i].imagePath,
                width: _thumbnailSize,
                height: _thumbnailSize,
                fit: BoxFit.contain,
              ),
              title: Text(_order[i].id),
              onTap: () => widget.onSelect(_order[i].id),
              trailing: ReorderableDragStartListener(
                index: i,
                child: const Icon(Icons.drag_handle),
              ),
            ),
        ],
      ),
    );
  }
}
