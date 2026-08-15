import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/composition.dart';
import '../providers/composition_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'composition_cover_image.dart';
import 'gallery_meta_label.dart';

/// 코디 1개를 이미지+이름 카드로 보여주는 Detail 전용 프리뷰 — `CompositionPreviewCarousel`의
/// 페이지 콘텐츠(여러 개, 옷 상세의 "연결된 코디")로도, 스타일일지 열람의 "연결된 코디"
/// (항상 0~1개) 단독 카드로도 쓰인다. 썸네일 경로는 `compositionCoverImageProvider`
/// (`coverImagePath`가 있으면 그대로, 없으면 첫 옷 이미지로 폴백)에서 온다.
///
/// 그 경로는 **번들 에셋일 수도, 런타임에 저장된 코디 스냅샷의 로컬 파일 절대경로일 수도**
/// 있으므로(커밋된 적 있는 코디는 후자) 반드시 [CompositionCoverImage]로 그린다 —
/// `Image.asset`으로 직접 읽으면 커밋 이후 이 카드가 "Unable to load asset"으로 깨진다
/// (`docs/reference/data/00_DataSchema.md` §13.3).
class CompositionPreviewCard extends ConsumerWidget {
  const CompositionPreviewCard({super.key, required this.composition, required this.onTap});

  /// `style_log_viewer_screen.dart`가 삭제된(휴지통 이동) 코디를 `StatusBadge`로 표시하며
  /// 탭을 막을 때 `onTap: null`로 `GestureDetector` 자체를 비활성화한다(`composition_detail_screen.dart`
  /// "사용된 옷" 타일과 동일 패턴). `CompositionPreviewCarousel` 호출부는 항상
  /// `!isDeleted` 필터를 거친 목록만 받으므로 실질적으로 항상 non-null 콜백을 넘긴다.
  final Composition composition;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final imagePath = ref.watch(compositionCoverImageProvider(composition.id));

    return Semantics(
      button: true,
      label: composition.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            decoration: BoxDecoration(color: semantic.gray200),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imagePath != null) CompositionCoverImage(path: imagePath),
                    GalleryMetaLabel(label: composition.name, maxWidth: constraints.maxWidth),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
