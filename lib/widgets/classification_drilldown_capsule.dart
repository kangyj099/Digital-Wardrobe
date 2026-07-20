import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'glass_pill.dart';

/// "전체 그룹 보기"(소분류 드릴인 해제) 항목의 sentinel 값 — 실제 `null`을 못 쓰는 이유는
/// [ClassificationDrilldownCapsule]의 소분류 `onSelected` 콜백 주석 참고.
/// `subOptionLabels` 인덱스(항상 0 이상)와 절대 겹치지 않는 음수를 쓴다.
const int _clearSentinel = -1;

/// 옷장/코디 메인 헤더의 "[중분류▾][소분류▾]" 2세그먼트 캡슐(스펙 §3.1).
///
/// 중분류/소분류 값의 실제 타입(옷장은 `ClosetSortCriterion`, 코디는
/// `CompositionSortCriterion`처럼 서로 다른 enum)을 이 위젯이 모르게 하고, 화면이
/// 인덱스↔enum 매핑과 라벨 문자열만 넘긴다 — 제네릭 타입 파라미터 2개를 위젯에 노출하는
/// 대신 화면이 매핑을 소유하는 방식(Worker 재량으로 명시된 지점 중 이 플랜이 확정한 선택).
///
/// **Header/HUD Pinned Rule과의 관계**: `glass_pill.dart` docstring이 "여러 컨트롤을 하나의
/// GlassPill 안에 함께 담지 않는다"고 명시하고, 이 규칙 변경은 `docs/history/Decision.md`상
/// 사용자 승인이 필요하다. Review(2026-07-19, Task 5)가 최초 구현(하나의 GlassPill에 두
/// DropdownButton)을 이 규칙 위반으로 지적해 한때 독립 GlassPill 2개로 분리했었으나,
/// **사용자가 2026-07-20에 "캡슐 이미지 하나로, 중분류/소분류 사이는 구분선으로"라고
/// 직접 지시 — 이 지시 자체가 필요한 사용자 승인이라 하나의 GlassPill로 되돌리고, 대신
/// 두 세그먼트 사이에 얇은 세로 구분선(팔레트 연한 회색)을 넣어 시각적으로 구획을
/// 나눈다**(`docs/history/Decision.md` 해당 항목 참고, 명시적 Pinned Rule 예외로 기록됨).
///
/// **2026-07-20**: 두 세그먼트 모두 `DropdownButton`에서 `PopupMenuButton`(`_CapsuleSegment`)
/// 으로 교체 — `CategoryToggleDropdown`(헤더 카테고리 드롭다운)과 동일한 스타일(버튼 톤에
/// 맞춘 색/모서리, 버튼 바로 아래 배치, 선택 항목 하이라이트)을 쓰기 위함(사용자 지시).
class ClassificationDrilldownCapsule extends StatelessWidget {
  const ClassificationDrilldownCapsule({
    super.key,
    required this.criterionLabels,
    required this.selectedCriterionIndex,
    required this.onCriterionChanged,
    required this.hasSubClassification,
    this.subHint,
    this.subOptionLabels = const [],
    this.selectedSubOptionIndex,
    this.onSubOptionSelected,
    this.onClearSubSelection,
  });

  /// 중분류 세그먼트 드롭다운 항목 라벨(순서=enum.values 순서, 화면이 보장).
  final List<String> criterionLabels;
  final int selectedCriterionIndex;
  final ValueChanged<int> onCriterionChanged;

  /// 현재 선택된 중분류가 소분류를 갖는지 — false면 소분류 세그먼트 자체를 숨기고
  /// 캡슐이 첫 세그먼트 크기로 줄어든다(스펙 §3.3).
  final bool hasSubClassification;

  /// 소분류 값 미선택(그룹 개요) 상태에서 보여줄 플레이스홀더(예: '계절').
  final String? subHint;

  /// 소분류 세그먼트 드롭다운 항목 라벨(그룹 값들 + 필요 시 '미분류', 화면이 순서 결정).
  final List<String> subOptionLabels;

  /// 소분류 값이 선택된 상태(드릴인)일 때 그 인덱스. null이면 미선택(그룹 개요).
  final int? selectedSubOptionIndex;

  final ValueChanged<int>? onSubOptionSelected;

  /// "전체 그룹 보기로" 되돌리기 — 드릴인 상태에서 소분류 세그먼트 최상단 항목으로 제공.
  final VoidCallback? onClearSubSelection;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).extension<AppSemanticColors>()!.gray200;
    return GlassPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 중분류는 항상 값이 있다(null 없음) — `PopupMenuButton<int>`로 통합테스트가
          // 소분류(`PopupMenuButton<int?>`)와 타입으로 구분해 찾을 수 있게 유지한다
          // (`find.byType(DropdownButton<int>)`로 구분하던 기존 테스트 관례를 그대로 계승).
          _CapsuleSegment<int>(
            currentLabel: criterionLabels[selectedCriterionIndex],
            onSelected: onCriterionChanged,
            items: [
              for (var i = 0; i < criterionLabels.length; i++)
                _menuItem<int>(context, value: i, label: criterionLabels[i], selected: i == selectedCriterionIndex),
            ],
          ),
          if (hasSubClassification) ...[
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              color: dividerColor,
            ),
            _CapsuleSegment<int?>(
              currentLabel: selectedSubOptionIndex != null
                  ? subOptionLabels[selectedSubOptionIndex!]
                  : (subHint ?? ''),
              onSelected: (value) {
                // `PopupMenuButton<T>`는 메뉴에서 실제로 null 값을 골라도, "아무것도 안
                // 고르고 바깥을 탭해 닫음"(취소)과 구분을 못 해 onSelected 자체를 호출하지
                // 않는다(Flutter 프레임워크 자체의 알려진 동작 — showButtonMenu()가
                // `newValue == null`이면 무조건 onCanceled로 처리). 그래서 "전체 그룹
                // 보기"는 실제 null이 아니라 sentinel 값 _clearSentinel(-1)로 표현한다
                // — subOptionLabels 인덱스는 항상 0 이상이라 절대 충돌하지 않는다.
                if (value == _clearSentinel) {
                  onClearSubSelection?.call();
                } else if (value != null) {
                  onSubOptionSelected?.call(value);
                }
              },
              items: [
                if (selectedSubOptionIndex != null)
                  _menuItem<int?>(context, value: _clearSentinel, label: '전체 그룹 보기', selected: false),
                for (var i = 0; i < subOptionLabels.length; i++)
                  _menuItem<int?>(context, value: i, label: subOptionLabels[i], selected: i == selectedSubOptionIndex),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// [_CapsuleSegment]의 메뉴 항목 — 현재 선택된 항목만 불투명 배경으로 하이라이트한다.
  static PopupMenuItem<T> _menuItem<T>(
    BuildContext context, {
    required T value,
    required String label,
    required bool selected,
  }) {
    final highlightColor = Theme.of(context).extension<AppSemanticColors>()!.primaryLight;
    return PopupMenuItem<T>(
      value: value,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: kMinInteractiveDimension,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        color: selected ? highlightColor : null,
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// [ClassificationDrilldownCapsule]의 세그먼트 하나(중분류 또는 소분류) — 헤더의
/// `CategoryToggleDropdown`과 동일한 스타일 계약(버튼 톤에 맞춘 색/모서리, 버튼 바로
/// 아래 배치, 선택 항목만 불투명 배경 하이라이트, 좌측정렬·콘텐츠 폭)을 공유하는
/// `PopupMenuButton<T>`. 두 세그먼트가 이 보일러플레이트를 반복하지 않도록 이 파일
/// 내부 전용 private 위젯으로 뽑았다 — `T`를 제네릭으로 남겨 중분류(`int`, null 없음)와
/// 소분류(`int?`, "전체 그룹 보기"=null 포함)가 서로 다른 정적 타입을 유지하게 한다
/// (통합테스트가 `PopupMenuButton<int>` vs `PopupMenuButton<int?>`로 두 세그먼트를
/// 구분해 찾으므로, 하나의 타입으로 통합하면 그 구분이 깨진다).
class _CapsuleSegment<T> extends StatelessWidget {
  const _CapsuleSegment({
    required this.currentLabel,
    required this.items,
    required this.onSelected,
  });

  /// 닫힌 상태에서 보여줄 텍스트(선택된 항목 라벨, 또는 미선택 시 hint).
  final String currentLabel;
  final List<PopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuButton<T>(
      tooltip: '',
      // `CategoryToggleDropdown`과 동일한 이유로 0 — GlassPill이 이미 자체 padding을 갖고
      // 있고, 이 세그먼트는 그 안에서 다른 세그먼트와 나란히 배치되는 것이라 더더욱 여분의
      // 패딩이 필요 없다.
      padding: EdgeInsets.zero,
      // 실측(스크래치 위젯 테스트)으로 확정한 값 — `CategoryToggleDropdown`과 값이 다르다.
      // 이 세그먼트의 트리거(Row: Text+Icon) 자체 높이가 24px뿐이라(그 위젯은 48) 같은
      // 공식을 그대로 못 쓴다. 목표는 여기서도 시각적 간격 16(AppSpacing.md, 화면 좌측
      // 여백과 동일)이고, 그 값을 만드는 offset을 직접 측정해 역산했다.
      offset: const Offset(0, kMinInteractiveDimension - AppSpacing.xs),
      color: colorScheme.surface.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      clipBehavior: Clip.antiAlias,
      onSelected: onSelected,
      itemBuilder: (context) => items,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currentLabel),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
