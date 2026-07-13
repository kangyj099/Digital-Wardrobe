import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../router/app_router.dart';
import '../theme/app_spacing.dart';
import 'glass_pill.dart';

/// 상단 좌측의 `[현재 컨텐츠 이름 ▾]` 카테고리 토글 — 옷장/코디/스타일일지 중 어디로든
/// 즉시 이동한다(`_공통 규칙.md` "네비게이션 > 상단 헤더"). 화면 간 수평 전환이라
/// `context.go()`를 쓴다(드릴다운이 아님).
///
/// [current]로 호출 화면이 어느 카테고리인지 받는다 — 예전엔 `AppCategory.closet`이
/// 하드코딩돼 있어 옷장 메인 밖에서는 재사용 자체가 불가능한 버그가 있었다(원래
/// `closet_main_screen.dart`의 private `_buildCategoryDropdown`을 추출하며 함께 해소).
///
/// [GlassPill]로 감싸 독립된 floating pill로 렌더링한다 — 이제 `AppMainScaffold`가 다른
/// 조작 요소(선택 버튼 등)와 하나의 Row/Container로 묶지 않고 이 위젯 자체를 물리적으로
/// 독립된 Positioned로 배치한다(`docs/history/Decision.md` Header/HUD Pinned Rule).
class CategoryToggleDropdown extends StatelessWidget {
  const CategoryToggleDropdown({super.key, required this.current});

  final AppCategory current;

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      child: DropdownButton<AppCategory>(
        value: current,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        items: AppCategory.values
            .map(
              (c) => DropdownMenuItem<AppCategory>(
                value: c,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c == current) ...[
                      const Icon(Icons.circle, size: 6),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    Text(c.label),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (value) => _onChanged(context, value),
      ),
    );
  }

  void _onChanged(BuildContext context, AppCategory? value) {
    if (value == null || value == current) {
      // 이미 보고 있는 카테고리를 다시 선택하면 아무 동작도 하지 않는다.
      return;
    }
    switch (value) {
      case AppCategory.closet:
        context.go(AppRoute.closetMain);
      case AppCategory.composition:
        context.go(AppRoute.compositionMain);
      case AppCategory.styleLog:
        context.go(AppRoute.styleLogMain);
    }
  }
}
