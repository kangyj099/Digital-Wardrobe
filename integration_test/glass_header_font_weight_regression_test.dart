import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/classification_drilldown_capsule.dart';

/// Tester 검증 — 프로스티드 글래스 수정 배치의 폰트 굵기 변경(카테고리 드롭다운
/// `FontWeight.bold`, 분류 드릴다운 캡슐 `FontWeight.w600`) 실측. Review가 코드로
/// 확인한 것과 별개로, 실제 라이브 위젯 트리에서 그 스타일이 정말 적용되어 있는지
/// (텍스트 위젯 속성 기준 — 실제 렌더된 글리프의 굵기 자체를 픽셀로 판별하는 것은
/// 이 환경에서 불가능하므로, "의도된 스타일이 실제로 배선되어 있는가"까지 확인).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DigitalWardrobeApp()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    '카테고리 드롭다운 트리거("옷장") 텍스트가 실제로 titleMedium 기본 굵기(w600)보다 굵은 '
    'FontWeight.bold(w700)로 렌더링된다',
    (tester) async {
      await pumpApp(tester);
      final context = tester.element(find.byType(CategoryToggleDropdown));
      final baseWeight = Theme.of(context).textTheme.titleMedium!.fontWeight;

      final triggerText = tester.widget<Text>(
        find.descendant(of: find.byType(CategoryToggleDropdown), matching: find.text('옷장')),
      );
      expect(triggerText.style?.fontWeight, FontWeight.bold);
      expect(triggerText.style?.fontWeight, isNot(baseWeight), reason: '공용 titleMedium(w600)보다 굵어야 한다(w700)');
    },
  );

  testWidgets(
    '분류 드릴다운 캡슐 트리거("전체보기") 텍스트가 실제로 labelSmall 기본 굵기(w500)보다 굵은 '
    'FontWeight.w600으로 렌더링된다',
    (tester) async {
      await pumpApp(tester);
      final context = tester.element(find.byType(ClassificationDrilldownCapsule));
      final baseWeight = Theme.of(context).textTheme.labelSmall!.fontWeight;

      final triggerText = tester.widget<Text>(
        find.descendant(of: find.byType(ClassificationDrilldownCapsule), matching: find.text('전체보기')),
      );
      expect(triggerText.style?.fontWeight, FontWeight.w600);
      expect(triggerText.style?.fontWeight, isNot(baseWeight), reason: '공용 labelSmall(w500)보다 굵어야 한다(w600)');
    },
  );
}
