import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import '../models/trash_entry.dart';
import 'closet_providers.dart';
import 'composition_providers.dart';
import 'style_log_providers.dart';

const int _trashRetentionDays = 15;

int _daysUntilPurge(DateTime deletedAt) {
  final elapsed = DateTime.now().difference(deletedAt).inDays;
  return (_trashRetentionDays - elapsed).clamp(0, _trashRetentionDays);
}

/// 휴지통 목록 — 3도메인(옷장/코디/스타일일지) provider를 watch해 `isDeleted`인 것만
/// 걸러 `TrashEntry`로 매핑하는 파생 뷰. `autoDispose`인 이유: 휴지통 화면을 벗어나면
/// 폐기되고 재진입 시 완전히 새로 계산돼, `daysUntilPurge`가 "휴지통 재진입 시" 자연스럽게
/// 갱신된다(시간 경과 자체로는 재계산 안 되므로 이렇게 안 하면 오래 켜둔 세션에서 값이
/// 고정돼 보일 수 있음).
final trashEntriesProvider = Provider.autoDispose<List<TrashEntry>>((ref) {
  final closetItems = ref.watch(closetItemsProvider).where((i) => i.isDeleted);
  final compositions = ref.watch(compositionsProvider).where((c) => c.isDeleted);
  final styleLogs = ref.watch(styleLogsProvider).where((l) => l.isDeleted);

  return [
    for (final item in closetItems)
      TrashEntry(
        id: item.id,
        category: AppCategory.closet,
        imagePath: item.imagePath,
        createdAt: item.createdAt,
        daysUntilPurge: _daysUntilPurge(item.deletedAt!),
      ),
    for (final c in compositions)
      TrashEntry(
        id: c.id,
        category: AppCategory.composition,
        imagePath: c.coverImagePath ?? '',
        createdAt: c.createdAt,
        daysUntilPurge: _daysUntilPurge(c.deletedAt!),
      ),
    for (final log in styleLogs)
      TrashEntry(
        id: log.id,
        category: AppCategory.styleLog,
        imagePath: log.coverImagePath,
        createdAt: log.createdAt,
        daysUntilPurge: _daysUntilPurge(log.deletedAt!),
      ),
  ];
});

/// 앱 실행 시 1회 — 15일 초과된 휴지통 항목을 3도메인에서 조용히 영구삭제한다.
/// `main.dart`의 `runApp()` 호출 전에 실행(Riverpod provider 빌더 안에서 부수효과로 하지
/// 않고 명시적 imperative 단계로 분리).
void purgeExpiredTrash(ProviderContainer container) {
  final closetExpired = container
      .read(closetItemsProvider)
      .where((i) => i.isDeleted && _daysUntilPurge(i.deletedAt!) <= 0)
      .map((i) => i.id)
      .toSet();
  if (closetExpired.isNotEmpty) {
    container.read(closetItemsProvider.notifier).purgeMany(closetExpired);
  }

  final compositionExpired = container
      .read(compositionsProvider)
      .where((c) => c.isDeleted && _daysUntilPurge(c.deletedAt!) <= 0)
      .map((c) => c.id)
      .toSet();
  if (compositionExpired.isNotEmpty) {
    container.read(compositionsProvider.notifier).purgeMany(compositionExpired);
  }

  final styleLogExpired = container
      .read(styleLogsProvider)
      .where((l) => l.isDeleted && _daysUntilPurge(l.deletedAt!) <= 0)
      .map((l) => l.id)
      .toSet();
  if (styleLogExpired.isNotEmpty) {
    container.read(styleLogsProvider.notifier).purgeMany(styleLogExpired);
  }
}
