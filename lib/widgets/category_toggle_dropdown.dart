import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'glass_pill.dart';

/// 메뉴 항목 4개(옷장/코디/스타일일지/설정)를 전부 이 너비로 맞춰, 짧은 라벨도
/// 메뉴 폭 전체를 기준으로 가운데 정렬되게 한다 — `PopupMenuItem`은 기본적으로
/// child를 내용 크기만큼만 감싸(centerStart) 짧은 항목이 왼쪽으로 쏠리므로, 고정
/// 너비 박스로 감싸는 게 유일한 신뢰 가능한 중앙정렬 방법이다.
const double _menuItemWidth = 150;

/// 체크 아이콘(선택된 항목 표시) + 아이콘-텍스트 간격이 차지하는 폭 — 텍스트 앞에
/// 이 폭만큼을 항상 예약하고, 텍스트 뒤에도 똑같은 폭을 빈 공간으로 예약한다.
/// 좌우가 대칭이라 아이콘이 있든 없든 텍스트 자체는 [_menuItemWidth] 정중앙에
/// 고정된다(아이콘이 텍스트를 오른쪽으로 밀어내지 않음).
const double _checkIconSlotWidth = 20; // Icon(16) + SizedBox(4)

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
        // 기본 offset(Offset.zero)이면 메뉴가 버튼과 겹쳐서 뜬다 — GlassPill 높이
        // (kMinInteractiveDimension, 48)만큼 아래로 밀어 버튼 바로 아래에 펼쳐지게 한다.
        offset: const Offset(0, kMinInteractiveDimension + AppSpacing.xxs),
        initialValue: _CategoryMenuEntry.category(current),
        onSelected: (entry) => _onSelected(context, entry),
        itemBuilder: (context) => [
          for (final category in AppCategory.values)
            PopupMenuItem(
              value: _CategoryMenuEntry.category(category),
              child: SizedBox(
                width: _menuItemWidth,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: _checkIconSlotWidth,
                        child: category == current ? const Icon(Icons.check, size: 16) : null,
                      ),
                      Text(category.label, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: _checkIconSlotWidth),
                    ],
                  ),
                ),
              ),
            ),
          PopupMenuDivider(
            color: Theme.of(context).extension<AppSemanticColors>()!.gray200,
          ),
          PopupMenuItem(
            value: const _CategoryMenuEntry.settings(),
            child: SizedBox(
              width: _menuItemWidth,
              child: Center(
                child: Text('설정', style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
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
