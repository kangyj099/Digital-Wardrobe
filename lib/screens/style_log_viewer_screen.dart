import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'app_detail_scaffold.dart';

/// Task 5에서 실제 데이터 바인딩으로 교체될 임시 skeleton body.
class StyleLogViewerScreen extends StatelessWidget {
  const StyleLogViewerScreen({super.key, required this.styleLogId});

  final String styleLogId;

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      category: AppCategory.styleLog,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Text('스타일일지 카드 (id: $styleLogId) — Task 5에서 실제 바인딩 예정'),
      ),
    );
  }
}
