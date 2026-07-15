import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'app_detail_scaffold.dart';

/// Step④(Detail 화면 적용) 산출물 — 공용 셸([AppDetailScaffold])에 연결됨. 자세한 배경은
/// `lib/screens/closet_item_detail_screen.dart`의 클래스 주석 참고(동일 패턴).
class CompositionDetailScreen extends StatelessWidget {
  const CompositionDetailScreen({super.key, required this.compositionId});

  final String compositionId;

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      category: AppCategory.composition,
      placeholderLabel: '코디 상세 (id: $compositionId) — 아트보드 스냅샷 + 사용된 옷 목록',
      crossReferenceLabel: '연결된 스타일일지 — Step⑦에서 연동 예정',
    );
  }
}
