import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_spacing.dart';
import 'app_main_scaffold.dart';
import 'app_scroll_container.dart';
import 'classification_drilldown_capsule.dart';
import 'frosted_close_button.dart';
import 'glass_circle_button.dart';
import 'glass_pill.dart';
import 'selection_entry_button.dart';

/// 그리드 렌더링을 도메인 wrapper에 위임하는 콜백 — `GalleryMainScreen`은 `T`의 런타임
/// 타입을 분기하지 않는다(각 도메인이 자기 기존 그리드 어댑터를 그대로 인스턴스화).
typedef GalleryGridBuilder<T> = Widget Function({
  required int density,
  required ScrollController? controller,
  required double topSpacing,
  required bool multiSelectMode,
  required Set<String> selectedIds,
  required void Function(T item) onItemTap,
  required void Function(T item) onItemLongPress,
});

/// 그룹형(옷장/코디) 전용 — 분류 캡슐+밀도+정렬 배선에 필요한 값 전부. null이면
/// [GalleryMainScreen]이 캡슐/밀도 UI 자체를 렌더링하지 않는다(플랫+필터형). 그리드
/// 콘텐츠 스위칭(그룹카드 vs 아이템 그리드)은 이 config가 아니라 `gridBuilder`(도메인
/// wrapper)의 책임이다 — 그래서 이 config엔 그룹개요 여부 필드가 없다.
class ClassificationConfig<T> {
  const ClassificationConfig({
    required this.criterionLabels,
    required this.selectedCriterionIndex,
    required this.onCriterionChanged,
    required this.hasSubClassification,
    this.subHint,
    required this.subOptionLabels,
    required this.selectedSubOptionIndex,
    required this.onSubOptionSelected,
    required this.onClearSubSelection,
    required this.density,
    required this.onDensityChanged,
    required this.ascending,
    required this.onAscendingChanged,
  });

  final List<String> criterionLabels;
  final int selectedCriterionIndex;
  final ValueChanged<int> onCriterionChanged;
  final bool hasSubClassification;
  final String? subHint;
  final List<String> subOptionLabels;
  final int? selectedSubOptionIndex;
  final ValueChanged<int> onSubOptionSelected;
  final VoidCallback onClearSubSelection;
  final int density;

  /// 밀도 버튼 탭 시 호출 — 현재 [density]를 그대로 받아 다음 단계 계산은 호출부(도메인
  /// wrapper)가 한다("`AppDensity.levels`를 이미 알고 있는 쪽이 순환 로직을 갖는다"는
  /// 관심사 분리 — 이 config가 순환 로직까지 떠안지 않음).
  final ValueChanged<int> onDensityChanged;
  final bool ascending;
  final ValueChanged<bool> onAscendingChanged;
}

class GalleryMainScreen<T> extends StatefulWidget {
  const GalleryMainScreen({
    super.key,
    required this.current,
    required this.items,
    required this.itemId,
    required this.gridBuilder,
    required this.onItemTap,
    this.classification,
    this.showCategoryToggle = true,
    this.showBackButton = true,
    this.headerActions = const [],
    this.selectionMode = false,
    this.fab,
    this.onReselectCurrentCategory,
    this.multiSelectDeleteLabel = '삭제',
    this.onDeleteSelected,
  });

  final AppCategory current;
  final List<T> items;
  final String Function(T item) itemId;
  final GalleryGridBuilder<T> gridBuilder;
  final void Function(T item) onItemTap;
  final ClassificationConfig<T>? classification;
  final bool showCategoryToggle;
  final bool showBackButton;
  final List<Widget> headerActions;

  /// 기존 "재호출 피커 모달" 개념 — true면 다중선택 진입 경로(선택버튼/롱프레스) 자체를
  /// 렌더링하지 않는다(§2.2).
  final bool selectionMode;
  final Widget? fab;
  final VoidCallback? onReselectCurrentCategory;
  final String multiSelectDeleteLabel;

  /// non-null이면 다중선택 하단에 [multiSelectDeleteLabel] 버튼 1개가 뜬다. null이면
  /// (예: 휴지통처럼 버튼 구성이 다른 화면은) 이 위젯 대신 직접 `AppMainScaffold`를
  /// 써야 하므로, 그 경우 호출부가 `GalleryMainScreen` 대신 더 낮은 레벨을 쓴다(Task 10
  /// 참고) — 이 Task 스코프(옷장/코디/스타일일지)에선 항상 non-null.
  final void Function(Set<String> selectedIds)? onDeleteSelected;

  @override
  State<GalleryMainScreen<T>> createState() => _GalleryMainScreenState<T>();
}

class _GalleryMainScreenState<T> extends State<GalleryMainScreen<T>> {
  bool _multiSelectMode = false;
  final Set<String> _selectedIds = {};

  void _enterOrToggle(T item) {
    final id = widget.itemId(item);
    setState(() {
      if (!_multiSelectMode) {
        _multiSelectMode = true;
        _selectedIds.add(id);
      } else if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggle(T item) {
    final id = widget.itemId(item);
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _multiSelectMode = false;
      _selectedIds.clear();
    });
  }

  void _handleDelete() {
    widget.onDeleteSelected?.call(Set.of(_selectedIds));
    _exitMultiSelect();
  }

  @override
  Widget build(BuildContext context) {
    final contentTopSpacing =
        AppMainScaffold.contentSpacerHeight(hasSecondaryRow: widget.classification != null);

    final effectiveOnItemTap = _multiSelectMode ? _toggle : widget.onItemTap;
    final effectiveOnLongPress = widget.selectionMode ? (T item) {} : _enterOrToggle;

    final headerActions = widget.selectionMode
        ? widget.headerActions
        : _multiSelectMode
            ? [
                GlassPill(child: Text('${_selectedIds.length}개 선택')),
                FrostedCloseButton(onTap: _exitMultiSelect),
              ]
            : [
                ...widget.headerActions,
                SelectionEntryButton(onTap: () => setState(() => _multiSelectMode = true)),
              ];

    return AppMainScaffold(
      current: widget.current,
      showCategoryToggle: widget.showCategoryToggle && !_multiSelectMode,
      showBackButton: widget.showBackButton && !_multiSelectMode,
      headerActions: headerActions,
      onReselectCurrentCategory: widget.onReselectCurrentCategory,
      floatingActionButton: _multiSelectMode ? null : widget.fab,
      secondaryControlsLeft: widget.classification == null
          ? const []
          : [
              ClassificationDrilldownCapsule(
                criterionLabels: widget.classification!.criterionLabels,
                selectedCriterionIndex: widget.classification!.selectedCriterionIndex,
                onCriterionChanged: widget.classification!.onCriterionChanged,
                hasSubClassification: widget.classification!.hasSubClassification,
                subHint: widget.classification!.subHint,
                subOptionLabels: widget.classification!.subOptionLabels,
                selectedSubOptionIndex: widget.classification!.selectedSubOptionIndex,
                onSubOptionSelected: widget.classification!.onSubOptionSelected,
                onClearSubSelection: widget.classification!.onClearSubSelection,
              ),
            ],
      secondaryControlsRight: widget.classification == null
          ? const []
          : [
              GlassCircleButton(
                icon: AppDensity.iconFor(widget.classification!.density),
                tooltip: '그리드 밀도 전환',
                onTap: () => widget.classification!.onDensityChanged(widget.classification!.density),
              ),
              GlassCircleButton(
                icon: widget.classification!.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                tooltip: widget.classification!.ascending ? '오름차순' : '내림차순',
                onTap: () => widget.classification!.onAscendingChanged(!widget.classification!.ascending),
              ),
            ],
      bottomFloatingActions: _multiSelectMode && widget.onDeleteSelected != null
          ? [
              Opacity(
                opacity: _selectedIds.isEmpty ? 0.4 : 1.0,
                child: GlassPill(
                  child: TextButton(
                    onPressed: _selectedIds.isEmpty ? null : _handleDelete,
                    child: Text(widget.multiSelectDeleteLabel),
                  ),
                ),
              ),
            ]
          : const [],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => widget.gridBuilder(
          density: widget.classification?.density ?? AppDensity.mid,
          controller: controller,
          topSpacing: contentTopSpacing,
          multiSelectMode: _multiSelectMode,
          selectedIds: _selectedIds,
          onItemTap: (item) => effectiveOnItemTap(item),
          onItemLongPress: (item) => effectiveOnLongPress(item),
        ),
      ),
    );
  }
}
