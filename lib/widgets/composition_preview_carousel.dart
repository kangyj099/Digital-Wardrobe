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
  /// `AppSpacing` 등재 전까지 유지하는 로컬 값(TechnicalDebt 기록됨) — 카드 영역 고정 높이.
  static const double _cardAreaHeight = 200;

  /// `AppSpacing` 등재 전까지 유지하는 로컬 값(TechnicalDebt 기록됨) — 옆 카드가 살짝 보이는 비율.
  static const double _pageViewportFraction = 0.82;

  /// `AppSpacing` 등재 전까지 유지하는 로컬 값(TechnicalDebt 기록됨) — 페이지 인디케이터 점 크기.
  static const double _dotSize = 6;

  /// `AppSpacing` 등재 전까지 유지하는 로컬 값(TechnicalDebt 기록됨) — 인디케이터 점 사이 여백.
  static const double _dotMargin = 2;

  final _controller = PageController(viewportFraction: _pageViewportFraction);
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
      height: _cardAreaHeight,
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
      ),
    );
  }
}
