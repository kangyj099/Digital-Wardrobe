// lib/widgets/composition_cover_image.dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/composition_snapshot_service.dart';

/// [path]가 번들 에셋 경로(`assets/...`, mock 데이터)면 `Image.asset`, 런타임에 로컬
/// 파일시스템에 저장된 실제 캡처 스냅샷(`composition_snapshot_service.dart`가 쓴 PNG)이면
/// `Image.file`로 분기해 렌더링한다(`docs/reference/data/00_DataSchema.md` §13.3) — 호출부가
/// 매번 `isBundledAssetPath` 판정을 직접 반복하지 않게 하는 공용 위젯. 향후 seed mock
/// 데이터의 `coverImagePath`는 계속 `assets/...` 형태를 쓴다는 전제라 이 위젯 도입에 별도
/// 마이그레이션이 필요 없다.
///
/// **`Composition.coverImagePath`를 읽는 모든 화면이 이걸 써야 한다** — 커밋된 적 있는
/// 코디의 경로는 `assets/...`가 아니라 로컬 파일 절대경로이므로, `Image.asset`으로 읽으면
/// "Unable to load asset"으로 그 화면이 깨진다(Tester가 실기기에서 그룹 카드/휴지통에서
/// 실제로 재현). 현재 호출부: [CompositionGalleryTile], `classification_group_card.dart`의
/// 그룹 요약 썸네일, `trash_gallery_tile.dart`/`trash_main_screen.dart`의 휴지통 표시,
/// `composition_preview_card.dart`(옷 상세의 "연결된 코디" 캐러셀 + 스타일일지 열람의
/// "연결된 코디" 단독 카드).
///
/// 이름은 코디 스냅샷 용도로 붙었지만(§13.3이 지정한 이름) 실제로는 "에셋/로컬파일 경로를
/// 분기해 그리는" 범용 위젯이라, 휴지통처럼 세 도메인 경로가 섞여 들어오는 호출부에서도
/// 그대로 쓴다 — 에셋 경로면 내부적으로 `Image.asset`이므로 옷/스타일일지 렌더링 동작은
/// 이전과 완전히 동일하다.
///
/// 의도적으로 `errorBuilder`를 두지 않는다: 경로 분기가 잘못되면(에셋 로더로 로컬 파일을
/// 읽는 등) 조용히 폴백되는 대신 예외로 드러나야, 그걸 잡아내는 회귀 테스트
/// (`integration_test/composition_snapshot_runtime_test.dart` 그룹 5의 `takeException()`
/// 단언)가 의미를 유지한다.
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
