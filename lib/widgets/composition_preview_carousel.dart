import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/clothing_item.dart';
import '../models/composition.dart';
import '../providers/closet_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'composition_items_tile.dart';

/// 옷 상세 화면의 "연결된 코디" 섹션 — 여러 개면 좌우 스와이프로 넘기는 캐러셀, 하나도
/// 없으면 아무것도 그리지 않는다(읽기 전용, 이 화면엔 바인딩 액션이 없다). 카드 영역은
/// 항상 `AspectRatio(1)` 풀블리드 정사각형 — 페이지 인디케이터는 2개 이상일 때만 보인다.
///
/// 각 페이지 콘텐츠는 `CompositionItemsTile`(Task 10) — `closetItemsProvider`를 watch해
/// 각 코디의 `composition.items`(순서 유지)를 실제 `ClothingItem` 리스트로 resolve한 뒤
/// 넘긴다(`docs/history/Decision.md` "옷 상세의 '연결된 코디' 캐러셀 타일을 단일 대표이미지에서
/// '사용된 옷' 가로 스크롤로 교체" 참고). [onItemTap]은 타일 안 개별 옷 이미지 탭을,
/// [onTap]은 타일의 나머지 영역(코디 자체) 탭을 처리한다.
class CompositionPreviewCarousel extends ConsumerStatefulWidget {
  const CompositionPreviewCarousel({
    super.key,
    required this.compositions,
    required this.onTap,
    required this.onItemTap,
  });

  final List<Composition> compositions;
  final void Function(Composition composition) onTap;
  final void Function(ClothingItem item) onItemTap;

  @override
  ConsumerState<CompositionPreviewCarousel> createState() => _CompositionPreviewCarouselState();
}

class _CompositionPreviewCarouselState extends ConsumerState<CompositionPreviewCarousel> {
  /// `AppSpacing` 등재 전까지 유지하는 로컬 값(TechnicalDebt 기록됨) — 페이지 인디케이터 점 크기.
  static const double _dotSize = 6;

  /// `AppSpacing` 등재 전까지 유지하는 로컬 값(TechnicalDebt 기록됨) — 인디케이터 점 사이 여백.
  static const double _dotMargin = 2;

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compositions.isEmpty) return const SizedBox.shrink();
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final closetItems = ref.watch(closetItemsProvider);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.compositions.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) {
              final composition = widget.compositions[index];
              final items = [
                for (final placement in composition.items)
                  closetItems.firstWhere((item) => item.id == placement.clothingItemId),
              ];
              return CompositionItemsTile(
                composition: composition,
                items: items,
                onTap: () => widget.onTap(composition),
                onItemTap: widget.onItemTap,
              );
            },
          ),
        ),
        if (widget.compositions.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.compositions.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: _dotMargin),
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? semantic.gray900 : semantic.gray200,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
