import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../router/app_router.dart';
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
    return GlassPill(
      child: PopupMenuButton<_CategoryMenuEntry>(
        tooltip: '',
        initialValue: _CategoryMenuEntry.category(current),
        onSelected: (entry) => _onSelected(context, entry),
        itemBuilder: (context) => [
          for (final category in AppCategory.values)
            PopupMenuItem(
              value: _CategoryMenuEntry.category(category),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category == current) ...[
                    const Icon(Icons.check, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Text(category.label),
                ],
              ),
            ),
          const PopupMenuDivider(),
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
