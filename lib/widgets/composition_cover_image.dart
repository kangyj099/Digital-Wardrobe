// lib/widgets/composition_cover_image.dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/composition_snapshot_service.dart';

/// [path]가 번들 에셋 경로(`assets/...`, mock 데이터)면 `Image.asset`, 런타임에 로컬
/// 파일시스템에 저장된 실제 캡처 스냅샷(`composition_snapshot_service.dart`가 쓴 PNG)이면
/// `Image.file`로 분기해 렌더링한다(`docs/reference/data/00_DataSchema.md` §13.3) — 호출부
/// (`CompositionGalleryTile` 등)가 매번 `isBundledAssetPath` 판정을 직접 반복하지 않게
/// 하는 공용 위젯. 향후 seed mock 데이터의 `coverImagePath`는 계속 `assets/...` 형태를
/// 쓴다는 전제라 이 위젯 도입에 별도 마이그레이션이 필요 없다.
class CompositionCoverImage extends StatelessWidget {
  const CompositionCoverImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
  });

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (isBundledAssetPath(path)) {
      return Image.asset(path, fit: fit);
    }
    return Image.file(File(path), fit: fit);
  }
}
