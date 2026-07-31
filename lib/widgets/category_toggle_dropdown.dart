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
///
/// **같은 카테고리 재선택(사용자 지시, 2026-07-20)**: 이 위젯 자신은 "지금 메인 화면에
/// 있는지"를 모른다(그건 화면 계층의 문제) — 그래서 호출부([onReselectCurrent])가 그
/// 판단을 대신 내린다. [onReselectCurrent]가 있으면(메인 화면) 네비게이션 없이 그 콜백만
/// 호출하고, 없으면(Detail 등 메인이 아닌 화면) 그 카테고리의 메인으로 실제 이동한다
/// (다른 카테고리를 선택했을 때와 동일하게 스택 리셋).
class CategoryToggleDropdown extends StatelessWidget {
  const CategoryToggleDropdown({super.key, required this.current, this.onReselectCurrent});

  final AppCategory current;

  /// [current]와 같은 카테고리를 다시 골랐을 때 호출된다 — 이 값이 non-null이라는 것
  /// 자체가 "지금 이 카테고리의 메인 화면에 있다"는 신호다(호출부가 그렇게 넘길 때만
  /// 채워야 함). 메인 화면은 여기서 자신의 로컬 상태(분류 캡슐 중분류/소분류 등)를
  /// 초기화하고, 네비게이션은 전혀 일어나지 않는다(뒤로가기 스택 그대로 유지).
  final VoidCallback? onReselectCurrent;

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
        // 선택 항목 배경(아래 Container)이 꽉 찬 사각형이라, 첫/마지막 항목이 선택된 경우
        // 메뉴의 둥근 모서리 밖으로 각지게 삐져나올 수 있다 — 메뉴 도형에 맞춰 클립.
        clipBehavior: Clip.antiAlias,
        onSelected: (entry) => _onSelected(context, entry),
        itemBuilder: (context) => [
          for (final category in AppCategory.values)
            PopupMenuItem(
              value: _CategoryMenuEntry.category(category),
              // 기본 아이템 padding(가로만 16, PopupMenuItemState.build 참고)을 0으로 비우고
              // 아래 Container가 전부 대체한다 — 그래야 선택 항목의 배경색이 좌우/상하 여백
              // 없이 행 전체(48높이, 메뉴 폭 전체)를 꽉 채운다.
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                height: kMinInteractiveDimension,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                // 현재 선택된 항목만 불투명(alpha 1.0) 배경색으로 구분 — 아직 아무 위젯도
                // 안 쓰던 AppSemanticColors.primaryLight(연한 프라이머리 톤)를 사용.
                color: category == current
                    ? Theme.of(context).extension<AppSemanticColors>()!.primaryLight
                    : null,
                child: Text(category.label, style: Theme.of(context).textTheme.titleMedium),
              ),
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
            // 목업(`옷장 메인 화면.txt` 34행, 헤더 16px/700) 대조 결과 이 트리거 텍스트가
            // 스타일 미지정으로 Material 기본값(bodyMedium, 14/w500)을 상속하고 있었다 —
            // titleMedium(16)에 `FontWeight.bold`(700)를 얹어 목업과 맞춘다. 공용
            // `textTheme.titleMedium` 자체(600)는 다른 화면까지 바뀌므로 건드리지 않고,
            // 이 헤더 트리거 텍스트에만 국한해 `.copyWith`로 좁게 적용.
            Text(
              current.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
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
    if (category == current && onReselectCurrent != null) {
      // 메인 화면에서 같은 카테고리 재선택(사용자 지시, 2026-07-20) — 네비게이션은 전혀
      // 안 하고(뒤로가기 스택 그대로) 호출부가 자기 로컬 상태만 초기화하게 맡긴다.
      onReselectCurrent!();
      return;
    }
    // 다른 카테고리를 선택했거나, 메인이 아닌 화면(Detail 등)에서 현재 카테고리를
    // 재선택한 경우 — 둘 다 그 카테고리의 메인으로 실제 이동해 스택을 리셋한다. 후자는
    // `category == current`라도 `onReselectCurrent`가 없다는 것 자체가 "아직 메인에 없다"는
    // 뜻이라 go()가 진짜 네비게이션(스택 리셋)을 수행한다.
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
