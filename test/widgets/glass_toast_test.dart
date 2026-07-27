import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/widgets/glass_toast.dart';

void main() {
  testWidgets('메시지와 액션 라벨이 렌더링되고 액션 탭 시 콜백이 호출된다', (tester) async {
    var actionTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => GlassToast.show(
              context,
              message: '휴지통으로 이동됨',
              actionLabel: '실행취소',
              onAction: () => actionTapped = true,
            ),
            child: const Text('트리거'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('트리거'));
    await tester.pump();
    expect(find.text('휴지통으로 이동됨'), findsOneWidget);
    expect(find.text('실행취소'), findsOneWidget);
    await tester.tap(find.text('실행취소'));
    expect(actionTapped, isTrue);
  });
}
