import 'package:flutter/material.dart';
import '../models/composition.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'composition_preview_card.dart';

/// 옷 상세 화면의 "연결된 코디" 섹션 — 여러 개면 좌우 스와이프로 넘기는 캐러셀, 하나도
/// 없으면 아무것도 그리지 않는다(읽기 전용, 이 화면엔 바인딩 액션이 없다). 카드 높이는
/// 1:1 정사각(`CompositionPreviewCard`)에 좌우 여백을 더한 고정값 — 페이지 인디케이터는
/// 2개 이상일 때만 보인다.
class CompositionPreviewCarousel extends StatefulWidget {
  const CompositionPreviewCarousel({super.key, required this.compositions, required this.onTap});

  final List<Composition> compositions;
  final void Function(Composition composition) onTap;

  @override
  State<CompositionPreviewCarousel> createState() => _CompositionPreviewCarouselState();
}

class _CompositionPreviewCarouselState extends State<CompositionPreviewCarousel> {
  final _controller = PageController(viewportFraction: 0.82);
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

    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.compositions.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final composition = widget.compositions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: CompositionPreviewCard(
                    composition: composition,
                    onTap: () => widget.onTap(composition),
                  ),
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
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page ? semantic.gray900 : semantic.gray200,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
