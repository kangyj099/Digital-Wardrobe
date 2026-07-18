import 'package:flutter/material.dart';
import '../models/composition.dart';
import '../theme/app_spacing.dart';
import 'composition_preview_card.dart';

/// 옷 상세 화면의 "연결된 코디" 섹션 — `style_log_viewer_screen.dart`의 "착용 옷" 섹션과
/// 동일한 메커니즘(페이지 넘김 없이 여러 카드가 동시에 보이는 연속 가로 스크롤)으로
/// 보여준다. 하나도 없으면 아무것도 그리지 않는다(읽기 전용, 이 화면엔 바인딩 액션이 없다).
/// `docs/history/Decision.md` "옷 상세 코디 프리뷰를 `PageView` 캐러셀에서 '착용 옷'과
/// 동일한 연속 스크롤 리스트로 교체" 참고 — 이전의 `PageView`+점 인디케이터("페이지" 단위로
/// 하나씩 스와이프해 넘기는 방식) 구현은 폐기됐다.
class CompositionPreviewCarousel extends StatelessWidget {
  const CompositionPreviewCarousel({super.key, required this.compositions, required this.onTap});

  final List<Composition> compositions;
  final void Function(Composition composition) onTap;

  /// `AppSpacing` 미등재 로컬 값(TechnicalDebt 기록됨) — `style_log_viewer_screen.dart`의
  /// "착용 옷" 타일과 동일한 스케일로 맞춘 고정 타일 크기(정사각형).
  static const double _tileSize = 96;

  @override
  Widget build(BuildContext context) {
    if (compositions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: _tileSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: compositions.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final composition = compositions[index];
          return SizedBox(
            width: _tileSize,
            height: _tileSize,
            child: CompositionPreviewCard(
              composition: composition,
              onTap: () => onTap(composition),
            ),
          );
        },
      ),
    );
  }
}
