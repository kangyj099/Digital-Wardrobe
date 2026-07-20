import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'glass_pill.dart';

/// 헤더 좌측 카테고리 드롭다운 — 옷장/코디/스타일일지 전환 + 설정 진입.
///
/// `DropdownButton<AppCategory>`는 `AppCategory` 값만 담을 수 있어 "설정"(카테고리가
/// 아닌 액션)을 넣을 수 없다 — `PopupMenuButton`으로 교체해 구분선 아래 "설정" 항목을
/// 별도 추가한다(`docs/superpowers/specs/2026-07-19-main-header-classification-and-settings-entry-design.md`
/// §2). "설정"을 골라도 [current] 표시는 바뀌지 않는다 — 메뉴가 닫힌 뒤 보이는 텍스트는
/// 항상 `current.label`이고, 선택된 메뉴 항목 값과 무관하다.
class CategoryToggleDropdown extends StatelessWidget {
  const CategoryToggleDropdown({super.key, required this.current});

  final AppCategory current;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassPill(
      child: PopupMenuButton<_CategoryMenuEntry>(
        tooltip: '',
        // GlassPill이 이미 자체 padding을 갖고 있어, PopupMenuButton 기본 padding(8)까지
        // 겹치면 버튼이 불필요하게 커진다 — 여기선 0으로 비운다.
        padding: EdgeInsets.zero,
        // `initialValue`를 넘기면 Flutter가 "메뉴 top이 아니라 선택된 항목의 세로 중심"을
        // 버튼에 맞추려 해서(PopupMenuButton 공식 문서), 선택 위치에 따라 메뉴가 버튼에서
        // 예측 불가능하게 멀어진다 — 선택 표시는 없앴으니(체크 아이콘 제거) 넘길 필요가 아예
        // 없다. offset은 GlassPill 높이(kMinInteractiveDimension, 48)만큼 아래로 민다.
        // 목표 시각적 간격은 화면 좌측 여백과 동일(AppSpacing.md, 16)이지만, Material 메뉴
        // 자체가 위쪽에 내부 패딩을 갖고 있어(실측 확인, 테마 문서화된 값 아님) 그만큼을
        // 미리 빼줘야 실제 렌더 간격이 16이 된다 — 스타일 변경(색/모서리) 후 다시 실측함.
        offset: const Offset(0, kMinInteractiveDimension + AppSpacing.xxs),
        // 박스 색/모서리를 버튼(GlassPill)과 비슷한 톤으로 — GlassPill이 쓰는 surface
        // 색상·pill 모서리 반경과 같은 계열(단, 메뉴는 읽기 쉬워야 하니 GlassPill의
        // 반투명(0.38)보다는 훨씬 불투명하게).
        color: colorScheme.surface.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        onSelected: (entry) => _onSelected(context, entry),
        itemBuilder: (context) => [
          for (final category in AppCategory.values)
            PopupMenuItem(
              value: _CategoryMenuEntry.category(category),
              child: Text(category.label, style: Theme.of(context).textTheme.titleMedium),
            ),
          PopupMenuDivider(
            color: Theme.of(context).extension<AppSemanticColors>()!.gray200,
          ),
          PopupMenuItem(
            value: const _CategoryMenuEntry.settings(),
            child: Text('설정', style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.label),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _onSelected(BuildContext context, _CategoryMenuEntry entry) {
    if (entry.isSettings) {
      context.push(AppRoute.settingsMain);
      return;
    }
    final category = entry.category!;
    if (category == current) return;
    switch (category) {
      case AppCategory.closet:
        context.go(AppRoute.closetMain);
      case AppCategory.composition:
        context.go(AppRoute.compositionMain);
      case AppCategory.styleLog:
        context.go(AppRoute.styleLogMain);
    }
  }
}

class _CategoryMenuEntry {
  const _CategoryMenuEntry.category(AppCategory value)
      : category = value,
        isSettings = false;
  const _CategoryMenuEntry.settings()
      : category = null,
        isSettings = true;

  final AppCategory? category;
  final bool isSettings;

  @override
  bool operator ==(Object other) =>
      other is _CategoryMenuEntry && other.category == category && other.isSettings == isSettings;

  @override
  int get hashCode => Object.hash(category, isSettings);
}
