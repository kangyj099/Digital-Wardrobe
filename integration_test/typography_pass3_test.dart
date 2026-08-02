import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/theme/app_typography.dart';
import 'package:digittal_wardrobe/widgets/composition_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';
import 'package:digittal_wardrobe/widgets/status_badge.dart';

/// Typography Pass 3 확정값(Decision.md) 실 구동 검증. Review 통과분(findings 없음) 대상
/// Tester 시나리오 — Review는 정적 분석(값 일치, `flutter analyze` 클린, `actionMinimal`의
/// color 미지정이 상속 체인으로 해석되는 것)까지만 확인했고, 실제 렌더링(위젯 트리 구동)은
/// 이 파일에서 처음 확인한다.
///
/// 대상:
/// 1) `labelSmall` 11px→13px 확대 — 갤러리 타일 카테고리/시즌/날짜 태그, `StatusBadge`.
/// 2) 신규 role `AppTypography.actionMinimal`(11px, w500, color 미지정) — 옷장/코디/
///    스타일일지 메인 "선택" 버튼.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
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
    return container;
  }

  Finder categoryDropdownFinder() =>
      find.byType(CategoryToggleDropdown);

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(categoryDropdownFinder());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// "선택" 버튼의 실제 렌더링 텍스트 스타일을 검사한다: fontSize/weight/family가
  /// `AppTypography.actionMinimal`과 정확히 일치하고, 색이 상속 체인을 타고 실제로
  /// 불투명한 값으로 해석되었는지(완전 투명/미해석 null이 아닌지) 렌더 트리에서 직접 확인한다.
  void expectActionMinimalRendered(WidgetTester tester) {
    final textFinder = find.text('선택');
    expect(textFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(textFinder);
    expect(textWidget.style, AppTypography.actionMinimal);
    expect(textWidget.style?.fontSize, 11);
    expect(textWidget.style?.fontWeight, FontWeight.w500);
    expect(textWidget.style?.fontFamily, 'Pretendard');

    final paragraph = tester.renderObject<RenderParagraph>(textFinder);
    final resolvedColor = paragraph.text.style?.color;
    expect(
      resolvedColor,
      isNotNull,
      reason: '"선택" 버튼 색이 TextButton→Material→DefaultTextStyle 상속 체인을 타고 '
          '실제로 해석되지 못하면(null) 렌더링 시 기본 검정 또는 예기치 않은 색으로 떨어질 수 있다.',
    );
    expect(
      resolvedColor!.a,
      greaterThan(0),
      reason: '완전 투명(alpha=0)이면 화면상 빈 텍스트처럼 보인다.',
    );
  }

  double labelSmallRenderedFontSize(WidgetTester tester, Finder textFinder) {
    final paragraph = tester.renderObject<RenderParagraph>(textFinder);
    return paragraph.text.style!.fontSize!;
  }

  // ── 1) "선택" 버튼(actionMinimal) — 옷장/코디/스타일일지 메인 3화면 ──────────────

  testWidgets(
    '옷장 메인 "선택" 버튼이 크래시 없이 렌더링되고 actionMinimal(11px, w500)로 렌더된다',
    (tester) async {
      await pumpApp(tester);

      expect(tester.takeException(), isNull);
      expectActionMinimalRendered(tester);
    },
  );

  testWidgets(
    '코디 메인 "선택" 버튼이 크래시 없이 렌더링되고 actionMinimal(11px, w500)로 렌더된다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expectActionMinimalRendered(tester);
    },
  );

  testWidgets(
    '스타일일지 메인 "선택" 버튼이 크래시 없이 렌더링되고 actionMinimal(11px, w500)로 렌더된다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');

      expect(tester.takeException(), isNull);
      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expectActionMinimalRendered(tester);
    },
  );

  testWidgets(
    '옷장 메인에서 "선택" 텍스트(actionMinimal, 11px)가 같은 화면의 갤러리 타일 카테고리 '
    '태그(labelSmall, 13px)보다 실제 렌더 폰트 크기가 작다 — "앱 전체에서 가장 작은 텍스트" '
    '요구사항의 실측 확인',
    (tester) async {
      await pumpApp(tester);

      final actionSize = labelSmallRenderedFontSize(tester, find.text('선택'));
      // c01(한벌옷) 타일의 카테고리 태그.
      final tagFinder = find.descendant(
        of: find.byKey(const ValueKey('c01')),
        matching: find.text('한벌옷'),
      );
      expect(tagFinder, findsOneWidget);
      final tagSize = labelSmallRenderedFontSize(tester, tagFinder);

      expect(actionSize, 11);
      expect(tagSize, 13);
      expect(actionSize, lessThan(tagSize));
    },
  );

  // ── 2) labelSmall 13px — StatusBadge / 갤러리 타일 태그 ────────────────────────

  testWidgets(
    '옷장 메인 부팅 시 "미완성" 배지가 실제로 13px(labelSmall)로 렌더링된다',
    (tester) async {
      await pumpApp(tester);

      expect(find.byType(StatusBadge), findsOneWidget);
      final badgeText = find.descendant(
        of: find.byType(StatusBadge),
        matching: find.text('미완성'),
      );
      expect(badgeText, findsOneWidget);
      expect(labelSmallRenderedFontSize(tester, badgeText), 13);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '옷장 메인 그리드 밀도를 최대(4, 가장 좁은 타일)로 전환해도 카테고리 태그·미완성 배지가 '
    '13px로 커진 채 오버플로 렌더 에러 없이 모두 표시된다',
    (tester) async {
      await pumpApp(tester);

      // 기본값 mid(2) → 탭 1회로 min(1) → 탭 1회로 max(4).
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4, reason: '밀도 전환이 의도대로 최대(4열)에 도달했는지 사전 확인.');

      expect(tester.takeException(), isNull);
      // mock 옷장 데이터는 12개(c01~c12)지만 c07/c08은 소프트 삭제(isDeleted: true)되어 휴지통으로
      // 이동해 옷장 그리드에서 제외된다(Group B) — 그리드에 실제로 렌더되는 타일은 12개가 아니라 10개.
      expect(find.byType(SelectableGalleryTile), findsNWidgets(10));
      expect(find.byType(StatusBadge), findsOneWidget);

      // 모든 타일의 라벨박스(ConstrainedBox)가 자기 타일 경계를 넘지 않는지 전수 확인
      // (13px로 커진 텍스트가 가장 좁은 타일에서 overflow를 일으키지 않는지).
      final tileFinders = find.byType(SelectableGalleryTile);
      final tileCount = tester.widgetList(tileFinders).length;
      for (var i = 0; i < tileCount; i++) {
        final tileFinder = tileFinders.at(i);
        final tileRect = tester.getRect(tileFinder);
        final labelBoxFinder = find.descendant(
          of: tileFinder,
          matching: find.byType(ConstrainedBox),
        );
        expect(labelBoxFinder, findsOneWidget);
        final labelRect = tester.getRect(labelBoxFinder);
        expect(
          labelRect.right,
          lessThanOrEqualTo(tileRect.right + 0.5),
          reason: '타일 $i 라벨박스가 우측 경계를 넘음. tileRect=$tileRect labelRect=$labelRect',
        );
        expect(
          labelRect.left,
          greaterThanOrEqualTo(tileRect.left - 0.5),
          reason: '타일 $i 라벨박스가 좌측 경계를 넘음.',
        );
      }
    },
  );

  testWidgets(
    '코디 메인 그리드 밀도를 최대(4)로 전환해도 시즌 태그가 13px로 커진 채 오버플로 없이 '
    '표시된다',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '코디');

      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionGalleryTile), findsNWidgets(2));
    },
  );

  testWidgets(
    '스타일일지 메인의 날짜·장소 태그(가장 긴 라벨 형태)가 13px(labelSmall)로 렌더링되고, '
    '오버플로 에러 없이 ellipsis로 처리된다(그리드 밀도 토글이 없는 화면이라 기본 2열 그리드 '
    '기준)',
    (tester) async {
      await pumpApp(tester);
      await goToCategory(tester, '스타일일지');

      final tagFinder = find.textContaining('2026-01-10');
      expect(tagFinder, findsOneWidget);
      expect(labelSmallRenderedFontSize(tester, tagFinder), 13);

      final tileFinder = find.byKey(const ValueKey('log02'));
      final tileRect = tester.getRect(tileFinder);
      final labelBoxFinder = find.descendant(
        of: tileFinder,
        matching: find.byType(ConstrainedBox),
      );
      expect(labelBoxFinder, findsOneWidget);
      final labelRect = tester.getRect(labelBoxFinder);
      expect(labelRect.right, lessThanOrEqualTo(tileRect.right + 0.5));
      expect(labelRect.left, greaterThanOrEqualTo(tileRect.left - 0.5));
      expect(tester.takeException(), isNull);
    },
  );

  // ── 3) 비정형 사용 흐름 — 화면 이동을 끼워 "선택" 버튼을 반복 탭 ────────────────────

  testWidgets(
    '[비정형 사용 흐름] "선택" 버튼 탭은 no-op이 아니라 다중선택 모드 진입 액션이다 — 탭 시 '
    '헤더가 "N개 선택"+닫기 버튼으로 바뀌고, 닫기로 나가면 actionMinimal "선택" 버튼이 '
    '복원되며, 화면 전환 후에도(코디 메인) 같은 흐름이 크래시 없이 재현된다',
    (tester) async {
      await pumpApp(tester);

      // 최초 상태: "선택" 버튼(actionMinimal)이 렌더된다.
      expectActionMinimalRendered(tester);

      // 탭 1회 → 다중선택 모드 진입. onPressed가 실제로 setState(_multiSelectMode = true)를
      // 실행하므로 "선택" 텍스트버튼은 사라지고 "0개 선택" 필+닫기 버튼으로 교체된다.
      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('선택'), findsNothing);
      expect(find.text('0개 선택'), findsOneWidget);
      expect(find.byTooltip('닫기'), findsOneWidget);

      // 닫기 버튼으로 다중선택 모드를 빠져나오면 "선택" 버튼(actionMinimal)이 복원된다.
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('0개 선택'), findsNothing);
      expectActionMinimalRendered(tester);

      // 화면 전환(코디 메인) 후에도 같은 진입 흐름이 재현된다 — 새 화면 인스턴스라
      // `_multiSelectMode`는 false로 초기화된 상태에서 시작한다.
      await goToCategory(tester, '코디');
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expectActionMinimalRendered(tester);

      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(find.text('선택'), findsNothing);
      expect(find.text('0개 선택'), findsOneWidget);
      expect(find.byTooltip('닫기'), findsOneWidget);
    },
  );
}
