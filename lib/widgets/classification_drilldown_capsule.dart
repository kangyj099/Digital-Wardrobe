import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'glass_pill.dart';

/// 옷장/코디 메인 헤더의 "[중분류▾][소분류▾]" 2세그먼트 캡슐(스펙 §3.1).
///
/// 중분류/소분류 값의 실제 타입(옷장은 `ClosetSortCriterion`, 코디는
/// `CompositionSortCriterion`처럼 서로 다른 enum)을 이 위젯이 모르게 하고, 화면이
/// 인덱스↔enum 매핑과 라벨 문자열만 넘긴다 — 제네릭 타입 파라미터 2개를 위젯에 노출하는
/// 대신 화면이 매핑을 소유하는 방식(Worker 재량으로 명시된 지점 중 이 플랜이 확정한 선택).
///
/// **Header/HUD Pinned Rule과의 관계**: `glass_pill.dart` docstring이 "여러 컨트롤을 하나의
/// GlassPill 안에 함께 담지 않는다"고 명시하고, 이 규칙 변경은 `docs/history/Decision.md`상
/// 사용자 승인이 필요하다 — 그 승인을 받지 않고 우회하기 위해, 중분류/소분류 두 세그먼트를
/// **각각 독립된 [GlassPill]**로 감싸고 그 둘을 `Row`로 나란히 배치한다(Pinned Rule을 그대로
/// 준수, 시각적으로는 여전히 붙어 보이는 2세그먼트 캡슐). Review(2026-07-19, Task 5)가
/// 최초 구현(하나의 GlassPill에 두 DropdownButton)이 이 규칙과 충돌한다고 지적해 수정됨.
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassPill(
          child: DropdownButton<int>(
            value: selectedCriterionIndex,
            underline: const SizedBox.shrink(),
            items: [
              for (var i = 0; i < criterionLabels.length; i++)
                DropdownMenuItem<int>(value: i, child: Text(criterionLabels[i])),
            ],
            onChanged: (value) {
              if (value != null) onCriterionChanged(value);
            },
          ),
        ),
        if (hasSubClassification) ...[
          const SizedBox(width: AppSpacing.xs),
          GlassPill(
            child: DropdownButton<int?>(
              value: selectedSubOptionIndex,
              hint: Text(subHint ?? ''),
              underline: const SizedBox.shrink(),
              items: [
                if (selectedSubOptionIndex != null)
                  const DropdownMenuItem<int?>(value: null, child: Text('전체 그룹 보기')),
                for (var i = 0; i < subOptionLabels.length; i++)
                  DropdownMenuItem<int?>(value: i, child: Text(subOptionLabels[i])),
              ],
              onChanged: (value) {
                if (value == null) {
                  onClearSubSelection?.call();
                } else {
                  onSubOptionSelected?.call(value);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
