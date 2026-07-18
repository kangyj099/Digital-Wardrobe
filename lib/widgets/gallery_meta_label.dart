import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// 갤러리 타일 좌하단에 붙는 반투명 라벨 pill — `selectable_gallery_tile.dart`/
/// `composition_gallery_tile.dart`/`style_log_gallery_tile.dart`/`trash_gallery_tile.dart`
/// 4곳에 라벨 텍스트만 다르고 동일하게 반복됐던 "Positioned(좌하단) + 부모 폭 기준
/// `ConstrainedBox` + 반투명 pill + 말줄임 `Text`(`labelSmall`)" 블록을 추출한 공용
/// StatelessWidget(`docs/history/TechnicalDebt.md` "화면 간 반복 복제된 UI 블록" 항목).
///
/// [Positioned]를 내부에 포함하므로 이 위젯은 반드시 [Stack]의 직접 자식으로만 사용해야
/// 한다. [maxWidth]는 호출부가 넘겨야 한다 — `Positioned(left: ..., bottom: ...)`처럼
/// `right`/`top`을 지정하지 않는 Positioned는 Flutter Stack 레이아웃상 자식에게 **무제한
/// 폭**(unbounded constraints)을 준다(양쪽 edge를 다 지정해야만 폭이 타이트하게 결정됨).
/// 그래서 이 위젯 내부에 `LayoutBuilder`를 두면 `Positioned` 밑에서 항상 `infinity`를
/// 관측하게 되어 폭 제한이 무효화된다 — 그래서 폭은 호출부의 `Stack`을 감싸는
/// `LayoutBuilder`가 잡아낸 타일 전체 폭을 그대로 전달받는다(이 위젯이 좌우 여백만큼을
/// 내부에서 뺀다).
class GalleryMetaLabel extends StatelessWidget {
  const GalleryMetaLabel({super.key, required this.label, required this.maxWidth});

  final String label;

  /// 타일(Stack) 전체 폭 — 호출부의 `LayoutBuilder`가 잡아낸 `constraints.maxWidth`를
  /// 그대로 넘기면 된다. 좌우 여백(`AppSpacing.xxs * 2`)은 이 위젯이 내부에서 뺀다.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Positioned(
      left: AppSpacing.xxs,
      bottom: AppSpacing.xxs,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth - AppSpacing.xxs * 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: semantic.gray50.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
