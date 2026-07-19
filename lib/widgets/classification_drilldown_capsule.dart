import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
/// 사용자 승인이 필요하다. Review(2026-07-19, Task 5)가 최초 구현(하나의 GlassPill에 두
/// DropdownButton)을 이 규칙 위반으로 지적해 한때 독립 GlassPill 2개로 분리했었으나,
/// **사용자가 2026-07-20에 "캡슐 이미지 하나로, 중분류/소분류 사이는 구분선으로"라고
/// 직접 지시 — 이 지시 자체가 필요한 사용자 승인이라 하나의 GlassPill로 되돌리고, 대신
/// 두 세그먼트 사이에 얇은 세로 구분선(팔레트 연한 회색)을 넣어 시각적으로 구획을
/// 나눈다**(`docs/history/Decision.md` 해당 항목 참고, 명시적 Pinned Rule 예외로 기록됨).
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
          DropdownButton<int>(
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
          if (hasSubClassification) ...[
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              color: dividerColor,
            ),
            DropdownButton<int?>(
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
          ],
        ],
      ),
    );
  }
}
