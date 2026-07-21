// lib/widgets/interactive_artboard/artboard_item_view.dart
import 'package:flutter/material.dart';
import 'artboard_item.dart';

/// 아이템 1개의 이미지 렌더링만 담당한다 — 위치/회전은 부모([InteractiveArtboard])가
/// 감싸는 Transform이 처리한다(스펙 §4.3, Selection Box·핸들과 동일 Transform 공유).
class ArtboardItemView extends StatelessWidget {
  const ArtboardItemView({
    super.key,
    required this.item,
    required this.renderBoxSize,
  });

  final ArtboardItem item;

  /// §2.1의 렌더 박스 한 변 길이(`baseItemSize * item.scale`), 이미 계산된 값을 받는다.
  final double renderBoxSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: renderBoxSize,
      height: renderBoxSize,
      child: Image.asset(item.imagePath, fit: BoxFit.contain),
    );
  }
}
