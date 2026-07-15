import 'package:flutter/material.dart';
import '../models/enums.dart';
import 'app_detail_scaffold.dart';

/// Step④(Detail 화면 적용) 산출물 — 공용 셸([AppDetailScaffold])에 연결됨. 자세한 배경은
/// `lib/screens/closet_item_detail_screen.dart`의 클래스 주석 참고(동일 패턴).
class StyleLogViewerScreen extends StatelessWidget {
  const StyleLogViewerScreen({super.key, required this.styleLogId});

  final String styleLogId;

  @override
  Widget build(BuildContext context) {
    return AppDetailScaffold(
      category: AppCategory.styleLog,
      placeholderLabel: '스타일일지 카드 (id: $styleLogId) — 대표→코디→추가사진 슬라이드 + 날짜/장소',
      crossReferenceLabel: '연결된 코디 — Step⑦에서 연동 예정',
    );
  }
}
