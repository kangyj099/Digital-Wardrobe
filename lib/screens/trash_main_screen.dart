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
import '../widgets/glass_pill.dart';
import '../widgets/glass_toast.dart';
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
  AppCategory? _filter;

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
              Text(
                '${entry.category.label} · 영구 삭제까지 ${entry.daysUntilPurge}일',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              // 스펙(`05_삭제 & 휴지통.md` 31-34행)이 요구하는 "헤더 아래: 이미지 배치" +
              // "제작된 날짜/시간(삭제일이 아닌 생성일)" — Audit이 기존 스텁에 이 두 요소가
              // 빠져 있음을 지적해 추가함.
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: entry.imagePath.isEmpty
                      ? Container(color: Theme.of(sheetContext).extension<AppSemanticColors>()!.gray200)
                      : Image.asset(entry.imagePath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${entry.createdAt.year}.${entry.createdAt.month}.${entry.createdAt.day} 제작',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
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
    final entries = _filter == null ? allEntries : allEntries.where((e) => e.category == _filter).toList();
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
              GlassPill(
                child: TextButton(
                  onPressed: () => setState(() => _multiSelectMode = true),
                  child: const Text('선택', style: AppTypography.actionMinimal),
                ),
              ),
              GlassPill(
                child: TextButton(
                  onPressed: () => _confirmEmptyTrash(context, allEntries),
                  child: const Text('비우기', style: AppTypography.actionMinimal),
                ),
              ),
            ],
      secondaryControlsLeft: [
        for (final option in [null, AppCategory.closet, AppCategory.composition, AppCategory.styleLog])
          GlassPill(
            child: TextButton(
              // 선택된 필터만 배경을 구분(`category_toggle_dropdown.dart`가 이미 쓰는
              // `primaryLight` 하이라이트 패턴 재사용) — 홀리스틱 Audit이 선택 상태 표시가
              // 없었다고 지적(P3).
              style: TextButton.styleFrom(
                backgroundColor: _filter == option
                    ? Theme.of(context).extension<AppSemanticColors>()!.primaryLight
                    : null,
              ),
              onPressed: () => setState(() => _filter = option),
              child: Text(option?.label ?? '전체'),
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
