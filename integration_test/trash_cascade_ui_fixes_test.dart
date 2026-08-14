import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/screens/closet_item_detail_screen.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/screens/composition_detail_screen.dart';
import 'package:digittal_wardrobe/screens/composition_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_main_screen.dart';
import 'package:digittal_wardrobe/screens/style_log_viewer_screen.dart';
import 'package:digittal_wardrobe/screens/trash_main_screen.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/trash_gallery_tile.dart';

/// Tester가 직접 설계한 `feature/trash-cascade-ui-fixes` 런타임 검증.
///
/// 대상 5개 수정(commits c7b34dd/652dc12/37860ed): (1) 휴지통 정보 팝업 닫기(X) 버튼,
/// (2) "N일"이 이미지 위 오버레이로 분리, (3) [복원]/[영구 삭제]가 스크롤과 무관하게 고정,
/// (4) 코디 타일 "연결끊김" 배지의 실제 삭제→반영 파이프라인, (5) 옷/코디/스타일일지 상세
/// 3화면 단일삭제 토스트의 "실행취소"가 pop 이후에도 실제로 동작하는지(P0 회귀 방지) —
/// 전부 실제 앱 네비게이션(카테고리 드롭다운/키가 있는 타일 탭/"더보기 메뉴")으로 왕복
/// 검증한다. Worker의 `test/screens/*_test.dart`(합성 라우터, ref 재사용 버그 자체의
/// 최소 재현)와는 별개로, 실제 `DigitalWardrobeApp` 전체 위젯 트리+실제 GoRouter
/// 네비게이션 스택을 통해 같은 경로를 독립적으로 다시 밟는다(셀프 리뷰 사각지대 방지).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    Size size = const Size(1400, 4600),
  }) async {
    tester.view.physicalSize = size;
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

  Future<void> goToCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(CategoryToggleDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> goToTrash(WidgetTester tester) async {
    await goToCategory(tester, '설정');
    final trashRow = find.text('휴지통');
    await tester.ensureVisible(trashRow);
    await tester.pumpAndSettle();
    await tester.tap(trashRow);
    await tester.pumpAndSettle();
    expect(find.byType(TrashMainScreen), findsOneWidget);
  }

  // ── (1)(2)(3) 휴지통 정보 팝업 ──────────────────────────────────────────

  group('휴지통 정보 팝업', () {
    testWidgets('우상단 닫기(X) 버튼이 실제로 보이고 탭하면 팝업만 닫힌다(항목은 그대로)', (tester) async {
      await pumpApp(tester);
      await goToTrash(tester);

      await tester.tap(find.byType(TrashGalleryTile).first); // c07(옷장, 12일)
      await tester.pumpAndSettle();

      final closeButton = find.byTooltip('닫기');
      expect(closeButton, findsOneWidget, reason: '스펙 "우측 모서리 닫기 버튼" + 공통 규칙 "팝업은 반드시 가시적인 닫기 버튼 제공"');
      expect(find.text('복원'), findsOneWidget, reason: '팝업이 열려 있어야 이 단계가 의미 있다');

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('복원'), findsNothing, reason: '팝업이 닫혔으니 [복원] 버튼도 함께 사라져야 한다');
      expect(find.text('영구 삭제'), findsNothing);
      expect(find.byType(TrashMainScreen), findsOneWidget, reason: '팝업만 닫히고 휴지통 화면 자체는 유지되어야 한다');
      expect(find.byType(TrashGalleryTile), findsNWidgets(3), reason: '닫기는 취소 동작 — 아무 항목도 복원/삭제되지 않아야 한다');
    });

    testWidgets(
      '"N일"이 더 이상 제목 문자열에 합쳐지지 않고, 그리드 타일과 동일한 이미지-오버레이 '
      '패턴으로 별도 렌더링된다',
      (tester) async {
        await pumpApp(tester);
        await goToTrash(tester);

        await tester.tap(find.byType(TrashGalleryTile).first); // c07(옷장, 12일)
        await tester.pumpAndSettle();

        // 예전 결합 문자열("옷장 · 영구 삭제까지 12일")은 더 이상 어디에도 없어야 한다.
        expect(find.text('옷장 · 영구 삭제까지 12일'), findsNothing);

        // 제목엔 카테고리 라벨만 남는다 — 카테고리 필터칩("옷장")과 팝업 제목("옷장") 2곳에
        // 같은 텍스트가 존재하는 것이 정상(필터 Row가 배경에 그대로 남아있음).
        expect(find.text('옷장'), findsNWidgets(2), reason: '카테고리 필터칩 + 팝업 제목');

        // "12일"은 배경 그리드 타일의 기존 오버레이 + 팝업의 새 이미지 오버레이, 2곳에 있어야
        // 한다(수정 전 코드였다면 팝업 쪽엔 결합 문자열만 있어 이 텍스트 자체가 1개뿐이었을
        // 것 — 이 assertion이 곧 회귀 감지 지점).
        final daysLabelFinder = find.text('12일');
        expect(daysLabelFinder, findsNWidgets(2));

        // 두 인스턴스 모두 "이미지와 같은 Stack 안"(이미지 위 오버레이)에 있어야 한다 —
        // 팝업의 새 인스턴스가 헤더 텍스트에 붙은 게 아니라 진짜 이미지 위에 얹힌 것인지
        // 구조적으로 확인.
        for (final element in daysLabelFinder.evaluate()) {
          final stackAncestor = find.ancestor(of: find.byWidget(element.widget), matching: find.byType(Stack)).first;
          expect(
            find.descendant(of: stackAncestor, matching: find.byType(Image)),
            findsOneWidget,
            reason: '"12일" 텍스트는 Image와 같은 Stack 안(이미지 위 오버레이)에 있어야 한다',
          );
        }
      },
    );

    testWidgets(
      '좁은 세로 뷰포트에서 팝업 콘텐츠(헤더+이미지+날짜)가 실제로 넘쳐 내부 스크롤이 '
      '생겨도 [복원]/[영구 삭제] 버튼은 스크롤 위치와 무관하게 항상 보이고 탭하면 실제로 '
      '동작한다',
      (tester) async {
        // 정사각형 이미지(너비=화면폭-32) + 헤더/날짜/버튼 Row를 다 더하면 자연 높이가
        // 약 530px — 400px 뷰포트에서는 반드시 내부 스크롤이 발생해야 의미 있는 테스트다.
        await pumpApp(tester, size: const Size(390, 400));
        await goToTrash(tester);

        await tester.tap(find.byType(TrashGalleryTile).first); // c07(옷장, 12일)
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: '좁은 뷰포트에서도 RenderFlex overflow 등 크래시가 없어야 한다');

        // 팝업 콘텐츠 영역(헤더+이미지+날짜)이 실제로 스크롤 가능해야 이 테스트가 의미가
        // 있다(전제 확인).
        final scrollable = tester.widgetList<Scrollable>(find.byType(Scrollable));
        expect(scrollable, isNotEmpty);

        // 버튼은 스크롤 이전에도 이미 화면에 렌더링되어 있고 실제로 탭 가능한(hit-testable)
        // 위치에 있어야 한다(고정 노출 — 스크롤 가능 영역 밖의 형제라 클리핑되지 않음).
        final restoreButton = find.text('복원');
        expect(restoreButton, findsOneWidget);
        expect(restoreButton.hitTestable(), findsOneWidget, reason: '스크롤과 무관하게 항상 탭 가능해야 한다');

        await tester.tap(restoreButton);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: '고정된 [복원] 버튼이 실제로 눌려 정상 동작해야 한다');
        expect(find.byType(TrashGalleryTile), findsNWidgets(2), reason: 'c07이 실제로 복원되어 휴지통에서 사라져야 한다');
      },
    );
  });

  // ── (4) 코디 "연결끊김" 배지 ────────────────────────────────────────────

  group('코디 타일 "연결끊김" 배지', () {
    testWidgets(
      '초기 mock 상태에서 이미 삭제된 옷(c07)을 포함한 comp01엔 배지가 있고, 삭제된 옷이 '
      '없는 comp03엔 배지가 없다(오탐 없음)',
      (tester) async {
        await pumpApp(tester);
        await goToCategory(tester, '코디');
        expect(find.byType(CompositionMainScreen), findsOneWidget);

        final comp01Tile = find.byKey(const ValueKey('comp01'));
        final comp03Tile = find.byKey(const ValueKey('comp03'));
        expect(comp01Tile, findsOneWidget);
        expect(comp03Tile, findsOneWidget);

        expect(
          find.descendant(of: comp01Tile, matching: find.byIcon(Icons.link_off)),
          findsOneWidget,
          reason: 'comp01은 이미 소프트삭제된 c07을 참조 중이라 초기 상태부터 배지가 보여야 한다',
        );
        expect(
          find.descendant(of: comp03Tile, matching: find.byIcon(Icons.link_off)),
          findsNothing,
          reason: 'comp03(c04/c05, 둘 다 비삭제)은 배지가 없어야 한다 — 오탐 방지 확인',
        );
      },
    );

    testWidgets(
      '삭제된 옷이 없던 코디(comp03)가 사용하는 옷(c04)을 옷 상세에서 삭제하면, 코디 메인 '
      '으로 돌아왔을 때 comp03 타일에 배지가 실제로 새로 나타난다(삭제 전엔 없었음을 먼저 '
      '확인)',
      (tester) async {
        await pumpApp(tester);

        await goToCategory(tester, '코디');
        expect(
          find.descendant(of: find.byKey(const ValueKey('comp03')), matching: find.byIcon(Icons.link_off)),
          findsNothing,
          reason: '삭제 전 baseline — 아직 배지가 없어야 한다',
        );

        await goToCategory(tester, '옷장');
        expect(find.byKey(const ValueKey('c04')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('c04')));
        await tester.pumpAndSettle();
        expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

        await tester.tap(find.byTooltip('더보기 메뉴'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('삭제'));
        await tester.pumpAndSettle();

        // c04는 (비삭제) comp03이 사용 중이라 안내 팝업이 뜬다 — 확정해서 실제로 휴지통 이동.
        expect(find.text('사용 중인 코디가 있어요'), findsOneWidget);
        await tester.tap(find.text('휴지통으로 이동'));
        await tester.pumpAndSettle();

        expect(find.byType(ClosetMainScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('c04')), findsNothing);

        await goToCategory(tester, '코디');
        expect(tester.takeException(), isNull);
        expect(
          find.descendant(of: find.byKey(const ValueKey('comp03')), matching: find.byIcon(Icons.link_off)),
          findsOneWidget,
          reason: 'c04 삭제 이후 comp03 타일에 연결끊김 배지가 실제로 나타나야 한다',
        );
      },
    );
  });

  // ── (5) 상세 화면 3곳의 "실행취소" 토스트(P0) ──────────────────────────

  group('상세 화면 삭제 토스트 "실행취소" — pop 이후 실제 복원', () {
    testWidgets('옷 상세(c02, 미사용) — 삭제→토스트→"실행취소" 탭 시 실제로 복원되어 옷장 메인에 다시 보이고 휴지통엔 없다', (tester) async {
      await pumpApp(tester);

      expect(find.byKey(const ValueKey('c02')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('c02')));
      await tester.pumpAndSettle();
      expect(find.byType(ClosetItemDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.text('휴지통으로 이동됨'), findsOneWidget);
      expect(find.text('실행취소'), findsOneWidget);

      await tester.tap(find.text('실행취소'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'P0 회귀: pop 이후 ref로 읽으면 release에서도 StateError가 났던 지점');
      expect(find.byKey(const ValueKey('c02')), findsOneWidget, reason: '복원되어 옷장 메인 그리드에 다시 보여야 한다');

      await goToTrash(tester);
      expect(find.byKey(const ValueKey('c02')), findsNothing, reason: '복원됐으니 휴지통엔 더 이상 없어야 한다');
    });

    testWidgets('코디 상세(comp01) — 삭제→토스트→"실행취소" 탭 시 실제로 복원되어 코디 메인에 다시 보이고 휴지통엔 없다', (tester) async {
      await pumpApp(tester);

      await goToCategory(tester, '코디');
      expect(find.byKey(const ValueKey('comp01')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('comp01')));
      await tester.pumpAndSettle();
      expect(find.byType(CompositionDetailScreen), findsOneWidget);

      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.byType(CompositionMainScreen), findsOneWidget);
      expect(find.text('휴지통으로 이동됨'), findsOneWidget);
      expect(find.text('실행취소'), findsOneWidget);

      await tester.tap(find.text('실행취소'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'P0 회귀: pop 이후 ref로 읽으면 release에서도 StateError가 났던 지점');
      expect(find.byKey(const ValueKey('comp01')), findsOneWidget, reason: '복원되어 코디 메인 그리드에 다시 보여야 한다');

      await goToTrash(tester);
      expect(find.byKey(const ValueKey('comp01')), findsNothing, reason: '복원됐으니 휴지통엔 더 이상 없어야 한다');
    });

    testWidgets('스타일일지 열람(log01) — 삭제→토스트→"실행취소" 탭 시 실제로 복원되어 스타일일지 메인에 다시 보이고 휴지통엔 없다', (tester) async {
      await pumpApp(tester);

      await goToCategory(tester, '스타일일지');
      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('log01')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('log01')));
      await tester.pumpAndSettle();
      expect(find.byType(StyleLogViewerScreen), findsOneWidget);

      await tester.tap(find.byTooltip('더보기 메뉴'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.byType(StyleLogMainScreen), findsOneWidget);
      expect(find.text('휴지통으로 이동됨'), findsOneWidget);
      expect(find.text('실행취소'), findsOneWidget);

      await tester.tap(find.text('실행취소'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'P0 회귀: pop 이후 ref로 읽으면 release에서도 StateError가 났던 지점');
      expect(find.byKey(const ValueKey('log01')), findsOneWidget, reason: '복원되어 스타일일지 메인 그리드에 다시 보여야 한다');

      await goToTrash(tester);
      expect(find.byKey(const ValueKey('log01')), findsNothing, reason: '복원됐으니 휴지통엔 더 이상 없어야 한다');
    });
  });
}
