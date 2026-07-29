import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/theme/app_colors.dart';
import 'package:digittal_wardrobe/theme/app_theme.dart';
import 'package:digittal_wardrobe/widgets/glass_pill.dart';
import 'package:digittal_wardrobe/widgets/glass_toast.dart';

void main() {
  testWidgets(
    '실행취소 버튼에 메시지 영역과 구분되는 배경색(primaryLight)이 적용되어 탭 가능한 요소로 '
    '시각적으로 구분된다(Visual Review 피드백: 버튼 가시성 부족)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => GlassToast.show(
                context,
                message: '휴지통으로 이동됨',
                actionLabel: '실행취소',
                onAction: () {},
              ),
              child: const Text('트리거'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('트리거'));
      await tester.pump();

      final context = tester.element(find.text('실행취소'));
      final expectedBackground =
          Theme.of(context).extension<AppSemanticColors>()!.primaryLight;

      final button = tester.widget<TextButton>(find.widgetWithText(TextButton, '실행취소'));
      final resolvedBackground =
          button.style?.backgroundColor?.resolve(<WidgetState>{});

      expect(
        resolvedBackground,
        expectedBackground,
        reason: '메시지 영역과 대비되는 배경 pill이 있어야 실행취소가 탭 가능한 버튼으로 인지된다',
      );

      // 액션을 탭하지 않아 auto-remove 타이머가 아직 대기 중인 채로 테스트가 끝나면
      // "pending timer" 불변조건 검사에 걸린다 — 타이머가 실제로 발화하도록 흘려보낸다.
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('메시지와 액션 라벨이 렌더링되고 액션 탭 시 콜백이 호출된다', (tester) async {
    var actionTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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

  testWidgets(
    'left+right Positioned로 폭 전체를 받아도 pill은 화면 폭까지 stretch되지 않고, '
    'pill 바깥의 투명 영역은 히트테스트를 아래 위젯으로 통과시킨다(회귀: 풀폭 투명 히트박스가 '
    '아래 요소의 탭을 가로채던 버그)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var underneathTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Stack(
              children: [
                // 화면 전체를 덮는 sentinel — toast의 invisible한 풀폭 히트박스가 살아있다면
                // 그 위에 겹쳐서 이 탭을 가로챈다.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => underneathTapped = true,
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () => GlassToast.show(context, message: '짧음'),
                      child: const Text('트리거'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('트리거'));
      await tester.pump();

      // pill(짧은 메시지 하나뿐)은 800 폭보다 훨씬 좁아야 한다 — GlassPill 자체 크기 확인.
      final pillSize = tester.getSize(find.byType(GlassPill));
      expect(pillSize.width, lessThan(400), reason: '짧은 메시지의 pill이 화면 폭 800의 절반 이상을 차지하면 안 된다');

      // GlassPill을 감싸는 가장 가까운 Material(toast 자신의 Material) 크기도 pill과
      // 마찬가지로 좁아야 한다 — 이게 화면 폭까지 늘어나 있으면 그 투명한 여백이 히트테스트를
      // 계속 가로챈다(버그의 직접 원인).
      final toastMaterialSize = tester.getSize(
        find.ancestor(of: find.byType(GlassPill), matching: find.byType(Material)).first,
      );
      expect(toastMaterialSize.width, lessThan(400));

      // 옛 풀폭 히트박스 안(화면 오른쪽 끝 근처)이지만 pill의 실제 시각 영역 바깥인 지점을
      // 탭한다 — pill은 화면 중앙에 좁게 떠 있으므로 x=760은 pill 바깥이다.
      await tester.tapAt(const Offset(760, 545));
      await tester.pump();

      expect(underneathTapped, isTrue, reason: 'pill 바깥의 투명 영역 탭은 아래 GestureDetector로 통과해야 한다');

      // toast의 auto-remove 타이머(4초)가 아직 대기 중인 채로 테스트가 끝나면
      // "pending timer" 불변조건 검사에 걸린다 — 타이머가 실제로 발화해 entry가
      // 스스로 제거되도록 그만큼 시간을 흘려보낸다.
      await tester.pump(const Duration(seconds: 5));
    },
  );
}
