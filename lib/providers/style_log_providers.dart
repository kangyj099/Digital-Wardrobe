import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/style_log.dart';
import '../mock/mock_data.dart';

class StyleLogsNotifier extends StateNotifier<List<StyleLog>> {
  StyleLogsNotifier() : super(mockStyleLogs);
}

final styleLogsProvider =
    StateNotifierProvider<StyleLogsNotifier, List<StyleLog>>(
        (ref) => StyleLogsNotifier());

final filteredStyleLogsProvider = Provider<List<StyleLog>>((ref) {
  final logs = ref.watch(styleLogsProvider).where((l) => !l.isDeleted).toList();
  logs.sort((a, b) => b.wornDate.compareTo(a.wornDate));
  return logs;
});
