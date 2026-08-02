import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/composition.dart';
import '../providers/composition_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'gallery_meta_label.dart';

/// 코디 1개를 이미지+이름 카드로 보여주는 Detail 전용 프리뷰 — `CompositionPreviewCarousel`의
/// 페이지 콘텐츠(여러 개)로도, 스타일일지 열람의 "연결된 코디"(항상 0~1개) 단독 카드로도
/// 쓰인다. `CompositionGalleryTile`(코디 메인 그리드, 아직 텍스트 전용)과 달리 이 위젯은
/// `compositionCoverImageProvider`(Task 5, null이면 첫 옷 이미지로 폴백)로 실제 썸네일을 그린다.
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
                    if (imagePath != null) Image.asset(imagePath, fit: BoxFit.cover),
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
