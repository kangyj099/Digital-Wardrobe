import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import '../models/trash_entry.dart';
import '../providers/closet_providers.dart';
import '../providers/composition_providers.dart';
import '../providers/style_log_providers.dart';
import '../providers/trash_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_gallery_grid.dart';
import '../widgets/app_main_scaffold.dart';
import '../widgets/app_scroll_container.dart';
import '../widgets/gallery_meta_label.dart';
import '../widgets/glass_pill.dart';
import '../widgets/glass_toast.dart';
import '../widgets/selection_entry_button.dart';
import '../widgets/trash_gallery_tile.dart';

/// 휴지통 메인 — Task 10(실행): 복원/영구삭제/비우기를 실제로 실행하고, 다중선택+카테고리
/// 필터칩을 이 화면 로컬 state로 구현한다.
///
/// `GalleryMainScreen<T>`("버튼 1개+탭=상세이동" 전제)를 쓰지 않고 `AppMainScaffold`를
/// 직접 배선한다 — 휴지통은 [복원]+[영구삭제] 2버튼, 탭 시 상세이동 대신 정보팝업, 필터칩 등
/// 그 전제와 다른 점이 많아 억지로 공용 셸에 넣지 않는다(스펙 §2.1 "화면 전용 확장" 원칙,
/// `docs/superpowers/plans/2026-07-21-multi-select-and-trash.md` Task 10).
class TrashMainScreen extends ConsumerStatefulWidget {
  const TrashMainScreen({super.key});

  @override
  ConsumerState<TrashMainScreen> createState() => _TrashMainScreenState();
}

class _TrashMainScreenState extends ConsumerState<TrashMainScreen> {
  bool _multiSelectMode = false;
  final Set<String> _selectedIds = {};
  // 빈 집합 = "전체"(필터 없음). 항목 자체를 여러 개 골라 삭제/복원하는 `_multiSelectMode`와는
  // 별개 개념 — 이건 카테고리 필터칩을 여러 개 동시 선택하는 기능이다.
  final Set<AppCategory> _filters = {};

  void _exitMultiSelect() => setState(() {
        _multiSelectMode = false;
        _selectedIds.clear();
      });

  Map<AppCategory, Set<String>> _groupByCategory(List<TrashEntry> entries, Set<String> ids) {
    final grouped = <AppCategory, Set<String>>{};
    for (final entry in entries) {
      if (ids.contains(entry.id)) {
        grouped.putIfAbsent(entry.category, () => {}).add(entry.id);
      }
    }
    return grouped;
  }

  // `?.let(...)`(Kotlin 관용구)은 Dart 표준 라이브러리에 없어 이 파일에서 직접 안 쓰고
  // 아래처럼 null 체크로 바로 처리한다(Plan Task 10 lines 3361-3382 참고).
  void _restore(WidgetRef ref, List<TrashEntry> entries, Set<String> ids) {
    final grouped = _groupByCategory(entries, ids);
    final closetIds = grouped[AppCategory.closet];
    if (closetIds != null) ref.read(closetItemsProvider.notifier).restoreMany(closetIds);
    final compositionIds = grouped[AppCategory.composition];
    if (compositionIds != null) ref.read(compositionsProvider.notifier).restoreMany(compositionIds);
    final styleLogIds = grouped[AppCategory.styleLog];
    if (styleLogIds != null) ref.read(styleLogsProvider.notifier).restoreMany(styleLogIds);
  }

  void _purge(WidgetRef ref, List<TrashEntry> entries, Set<String> ids) {
    final grouped = _groupByCategory(entries, ids);
    final closetIds = grouped[AppCategory.closet];
    if (closetIds != null) ref.read(closetItemsProvider.notifier).purgeMany(closetIds);
    final compositionIds = grouped[AppCategory.composition];
    if (compositionIds != null) ref.read(compositionsProvider.notifier).purgeMany(compositionIds);
    final styleLogIds = grouped[AppCategory.styleLog];
    if (styleLogIds != null) ref.read(styleLogsProvider.notifier).purgeMany(styleLogIds);
  }

  Future<bool> _confirmPurge(BuildContext context, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('영구 삭제'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('영구 삭제')),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _confirmEmptyTrash(BuildContext context, List<TrashEntry> entries) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('휴지통 비우기'),
        content: Text('전체 ${entries.length}개 항목을 영구 삭제하시겠어요? 되돌릴 수 없어요'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('비우기')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _purge(ref, entries, entries.map((e) => e.id).toSet());
    }
  }

  void _showTrashItemInfo(BuildContext context, WidgetRef ref, List<TrashEntry> entries, TrashEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      // 기본값(isScrollControlled: false)은 시트 높이를 화면 높이의 9/16로 제한한다
      // (`showModalBottomSheet` 문서). 정보 팝업에 이미지(정사각형, `AspectRatio(aspectRatio: 1)`)가
      // 추가되며 그 제한을 넘겨 일반 화면 높이에서도 `RenderFlex overflowed` 오류가 실제로
      // 재현됐다(`settings_trash_shell_test.dart` 재검증 중 발견) — true로 바꿔 시트가 콘텐츠
      // 높이(화면 전체 높이 이내)만큼 자유롭게 커지도록 한다.
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 스펙(31-35행) "팝업 내용이 길어 스크롤이 생기더라도 [복원]/[영구 삭제] 버튼은
              // 스크롤 위치와 무관하게 항상 화면 하단에 고정 노출" — 헤더+이미지+날짜를
              // 스크롤 가능 영역(Flexible + SingleChildScrollView)으로 묶는다. `Flexible`이
              // 자식에게 느슨한(loose) 제약(min:0, max:남은 공간)을 주므로 `SingleChildScrollView`
              // 는 `ListView`와 달리 별도 `shrinkWrap` 없이도 자연스럽게 콘텐츠 실제 크기(남은
              // 공간을 넘지 않는 한)만큼만 차지하고, 콘텐츠가 그 공간을 넘을 때만(예: 향후 메모
              // 필드 추가) 내부 스크롤이 생긴다. 버튼 Row는 그 형제로 바깥에 둬 항상 보이게 함.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.category.label,
                              style: Theme.of(sheetContext).textTheme.titleMedium,
                            ),
                          ),
                          // 공통 규칙(`_공통 규칙.md` "팝업은 반드시 가시적인 닫기 버튼 제공")
                          // + 스펙 "우측 모서리 닫기 버튼" — 스와이프/바깥 탭 같은 암묵적
                          // 닫기만으로는 불충분해 명시적 X 버튼을 추가한다.
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: '닫기',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                      // 스펙 "헤더 아래: 이미지 배치" + "이미지 안쪽 중앙 하단: 'N일' 오버레이".
                      // `TrashGalleryTile`이 이미 쓰는 `GalleryMetaLabel`("N일" 텍스트) 위젯을
                      // 그대로 재사용해 시각적 일관성을 유지한다(신규 오버레이 위젯을 새로
                      // 만들지 않음) — [GalleryMetaLabel]은 좌하단 고정 위치라 스펙 원문의
                      // "중앙 하단"과 정확히 일치하진 않지만, 이 앱 전역에서 이미 통일된
                      // "N일" 배지 패턴이라 재사용을 우선한다.
                      LayoutBuilder(
                        builder: (context, imageConstraints) => ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                entry.imagePath.isEmpty
                                    ? Container(
                                        color: Theme.of(sheetContext).extension<AppSemanticColors>()!.gray200)
                                    : Image.asset(entry.imagePath, fit: BoxFit.cover),
                                GalleryMetaLabel(
                                  label: '${entry.daysUntilPurge}일',
                                  maxWidth: imageConstraints.maxWidth,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${entry.createdAt.year}.${entry.createdAt.month}.${entry.createdAt.day} 제작',
                        style: Theme.of(sheetContext).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _restore(ref, entries, {entry.id});
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('복원'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final confirmed = await _confirmPurge(sheetContext, '영구 삭제하면 되돌릴 수 없어요, 계속할까요?');
                        if (confirmed && sheetContext.mounted) {
                          _purge(ref, entries, {entry.id});
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: const Text('영구 삭제'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(trashEntriesProvider);
    final entries = _filters.isEmpty
        ? allEntries
        : allEntries.where((e) => _filters.contains(e.category)).toList();
    final contentTopSpacing = AppMainScaffold.contentSpacerHeight(hasSecondaryRow: true);

    return AppMainScaffold(
      current: AppCategory.closet,
      showCategoryToggle: false,
      showBackButton: !_multiSelectMode,
      headerActions: _multiSelectMode
          ? [
              GlassPill(child: Text('${_selectedIds.length}개 선택')),
              GlassPill(
                child: TextButton(
                  onPressed: _exitMultiSelect,
                  child: const Text('닫기'),
                ),
              ),
            ]
          : [
              SelectionEntryButton(onTap: () => setState(() => _multiSelectMode = true)),
              GlassPill(
                child: TextButton(
                  onPressed: () => _confirmEmptyTrash(context, allEntries),
                  child: const Text('비우기', style: AppTypography.actionMinimal),
                ),
              ),
            ],
      secondaryControlsLeft: [
        // `AppMainScaffold`가 이 슬롯의 Positioned에 top/left만 지정하고 right는 지정하지
        // 않아(Row 2 우측 슬롯은 secondaryControlsRight 몫), child에 가로 폭 제약이 오지
        // 않는다 — 칩 4개(다중선택으로 늘어난 폭)가 화면 밖까지 넘치는 원인이었다.
        // ConstrainedBox로 "화면 폭 - 좌우 여백"만큼 상한을 주고, 그 안에서
        // SingleChildScrollView(가로)로 넘치는 만큼만 스크롤하게 한다 — 기존 GlassPill
        // 칩 UI/선택 하이라이트 패턴은 그대로 유지.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - AppSpacing.md * 2),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassPill(
                  child: TextButton(
                    // "전체" 칩은 다른 칩과 달리 다중선택이 아니라 필터 초기화(빈 Set) 전용
                    // 특수 케이스 — 선택 시 개별 카테고리 선택을 모두 해제한다.
                    style: TextButton.styleFrom(
                      backgroundColor: _filters.isEmpty
                          ? Theme.of(context).extension<AppSemanticColors>()!.primaryLight
                          : null,
                    ),
                    onPressed: () => setState(() => _filters.clear()),
                    child: const Text('전체'),
                  ),
                ),
                for (final category in [AppCategory.closet, AppCategory.composition, AppCategory.styleLog]) ...[
                  const SizedBox(width: AppSpacing.xs),
                  GlassPill(
                    child: TextButton(
                      // 각 카테고리 칩은 서로 독립적으로 토글(다중선택) — 선택된 칩만 배경을
                      // 구분(`category_toggle_dropdown.dart`가 이미 쓰는 `primaryLight`
                      // 하이라이트 패턴 재사용).
                      style: TextButton.styleFrom(
                        backgroundColor: _filters.contains(category)
                            ? Theme.of(context).extension<AppSemanticColors>()!.primaryLight
                            : null,
                      ),
                      onPressed: () => setState(() {
                        if (_filters.contains(category)) {
                          _filters.remove(category);
                        } else {
                          _filters.add(category);
                        }
                      }),
                      child: Text(category.label),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      bottomFloatingActions: _multiSelectMode
          ? [
              Opacity(
                opacity: _selectedIds.isEmpty ? 0.4 : 1.0,
                child: GlassPill(
                  child: TextButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () {
                            _restore(ref, allEntries, _selectedIds);
                            GlassToast.show(context, message: '${_selectedIds.length}개 항목이 복원됨');
                            _exitMultiSelect();
                          },
                    child: const Text('복원'),
                  ),
                ),
              ),
              Opacity(
                opacity: _selectedIds.isEmpty ? 0.4 : 1.0,
                child: GlassPill(
                  child: TextButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () async {
                            final confirmed = await _confirmPurge(context, '영구 삭제하면 되돌릴 수 없어요, 계속할까요?');
                            if (confirmed && mounted) {
                              _purge(ref, allEntries, _selectedIds);
                              _exitMultiSelect();
                            }
                          },
                    child: const Text('영구 삭제'),
                  ),
                ),
              ),
            ]
          : const [],
      body: AppScrollContainer(
        topHintThreshold: contentTopSpacing,
        builder: (context, controller) => AppGalleryGrid(
          itemCount: entries.length,
          density: AppDensity.mid,
          controller: controller,
          topSpacing: contentTopSpacing,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final selected = _multiSelectMode && _selectedIds.contains(entry.id);
            return TrashGalleryTile(
              key: ValueKey(entry.id),
              imagePath: entry.imagePath,
              category: entry.category,
              daysUntilPurge: entry.daysUntilPurge,
              multiSelectMode: _multiSelectMode,
              selected: selected,
              onLongPress: () => setState(() {
                if (!_multiSelectMode) {
                  _multiSelectMode = true;
                  _selectedIds.add(entry.id);
                } else if (_selectedIds.contains(entry.id)) {
                  _selectedIds.remove(entry.id);
                } else {
                  _selectedIds.add(entry.id);
                }
              }),
              onTap: () {
                if (_multiSelectMode) {
                  setState(() {
                    if (_selectedIds.contains(entry.id)) {
                      _selectedIds.remove(entry.id);
                    } else {
                      _selectedIds.add(entry.id);
                    }
                  });
                } else {
                  _showTrashItemInfo(context, ref, allEntries, entry);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
