import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'app_detail_scaffold.dart';

/// Task 3에서 실제 데이터 바인딩으로 교체될 임시 skeleton body.
class ClosetItemDetailScreen extends StatelessWidget {
  const ClosetItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      category: AppCategory.closet,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Text('옷 상세 정보 (id: $itemId) — Task 3에서 실제 바인딩 예정'),
      ),
    );
  }
}
