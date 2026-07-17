import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/composition.dart';
import '../providers/composition_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'gallery_meta_label.dart';

/// 코디 1개를 이미지+이름 카드로 보여주는 Detail 전용 프리뷰 — 이제 스타일일지 열람의
/// "연결된 코디" 슬롯(항상 0~1개, `style_log_viewer_screen.dart`) 전용으로 좁혀졌다(Task 10,
/// `docs/history/Decision.md` "옷 상세의 '연결된 코디' 캐러셀 타일을 단일 대표이미지에서
/// '사용된 옷' 가로 스크롤로 교체" 참고 — `CompositionPreviewCarousel`의 페이지 콘텐츠는
/// `CompositionItemsTile`로 대체되어 더 이상 이 위젯을 쓰지 않는다). `CompositionGalleryTile`
/// (코디 메인 그리드, 아직 텍스트 전용)과 달리 이 위젯은 `compositionCoverImageProvider`
/// (Task 5, null이면 첫 옷 이미지로 폴백)로 실제 썸네일을 그린다.
class CompositionPreviewCard extends ConsumerWidget {
  const CompositionPreviewCard({super.key, required this.composition, required this.onTap});

  final Composition composition;
  final VoidCallback onTap;

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
