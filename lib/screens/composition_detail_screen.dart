import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'app_detail_scaffold.dart';

/// Task 4에서 실제 데이터 바인딩으로 교체될 임시 skeleton body.
class CompositionDetailScreen extends StatelessWidget {
  const CompositionDetailScreen({super.key, required this.compositionId});

  final String compositionId;

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      category: AppCategory.composition,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Text('코디 상세 (id: $compositionId) — Task 4에서 실제 바인딩 예정'),
      ),
    );
  }
}
