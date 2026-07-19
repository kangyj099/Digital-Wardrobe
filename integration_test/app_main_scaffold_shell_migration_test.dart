import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:digittal_wardrobe/main.dart';
import 'package:digittal_wardrobe/models/enums.dart';
import 'package:digittal_wardrobe/providers/closet_providers.dart';
import 'package:digittal_wardrobe/screens/closet_main_screen.dart';
import 'package:digittal_wardrobe/widgets/app_main_scaffold.dart';
import 'package:digittal_wardrobe/widgets/category_toggle_dropdown.dart';
import 'package:digittal_wardrobe/widgets/selectable_gallery_tile.dart';

/// Task 2-B(`AppMainScaffold` 조립 + 옷장 메인 마이그레이션, 커밋 `b9d0674`) Tester 검증.
///
/// `closet_main_screen_test.dart`(28개)와 `closet_main_shell_widgets_regression_test.dart`
/// (4개)가 이미 커버하는 계절/밀도/FAB/카테고리 이동/뒤로가기 시나리오는 중복 작성하지 않는다.
/// 이 파일은 그 두 스위트가 다루지 않은, 이번 마이그레이션에서 특히 중요한 두 축만 다룬다:
///
/// 1) Detail 화면 재사용 전제 조건(그룹형 드릴다운 슬롯 없이도 셸이 정상 동작해야 함,
///    해당 슬롯 자체는 2026-07-19 `AppMainScaffold`에서 삭제됨) — Worker의 위젯테스트
///    (`test/widgets/app_main_scaffold_test.dart`)는 고립된 `SizedBox.shrink()` body와 자체
///    테스트 라우터로만 검증했다. 여기서는 실제 앱(`DigitalWardrobeApp`, 실 테마/실
///    Riverpod ProviderScope/실 go_router Navigator) 위에서, 실제 화면(`ClosetMainScreen`)
///    context로부터 `Navigator.of(context).push(...)`로 `AppMainScaffold`를 띄워
///    `context.canPop()`/`context.pop()`이 go_router의 진짜 Navigator 스택 기준으로 정상
///    동작하는지, 레이아웃이 깨지지 않는지, pop 후 원래 화면(밀도 등 Riverpod 상태)이
///    그대로 유지되는지 확인한다.
/// 2) 기존 통합테스트가 전부 `physicalSize = 1400x...`(그리드 lazy-build 회피용 특수 뷰포트)를
///    쓰고 있어, 실제 모바일 화면 폭에서 헤더(카테고리 토글+계절 드롭다운+밀도/정렬 아이콘+
///    "선택" 액션 버튼이 한 Row에 모두 들어감)가 오버플로 없이 렌더링되는지 아직 확인된 적이
///    없다. 여기서는 좁은 실제 모바일 폭(360px)에서 전체 앱을 구동해 확인한다.
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

  // ── 그룹형 드릴다운 슬롯 없이(삭제됨), 실제 앱 러닝 컨텍스트 ────────────────────────

  testWidgets(
    'AppMainScaffold(groupingBar 슬롯 삭제 이후 버전)가 실제 앱(실 테마/실 Riverpod/실 '
    'go_router Navigator) 위에서 레이아웃 붕괴·예외 없이 렌더링되고, 헤더(카테고리 토글)와 '
    '뒤로가기 버튼이 정상 동작하며, 뒤로가기로 복귀하면 이전에 바꿔둔 옷장 메인 밀도 상태가 '
    '그대로 유지된다',
    (tester) async {
      final container = await pumpApp(tester);

      // pop 후 상태 유지 여부를 확인하기 위해, push 전에 밀도를 기본값(2)에서 1로 미리 바꾼다.
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();
      expect(container.read(closetDensityProvider), 1);

      final context = tester.element(find.byType(SelectableGalleryTile).first);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AppMainScaffold(
            current: AppCategory.closet,
            body: Text('groupingBar 없음 — Detail 재사용 시나리오 시뮬레이션'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('groupingBar 없음 — Detail 재사용 시나리오 시뮬레이션'), findsOneWidget);
      // Leading(카테고리 토글)은 그룹형 드릴다운 슬롯 유무와 무관하게 정상 렌더링되어야 한다.
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);
      // 실제 go_router Navigator 스택에 새로 push됐으므로 canPop()==true → 뒤로가기 버튼 노출.
      expect(find.byTooltip('뒤로가기'), findsOneWidget);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.text('groupingBar 없음 — Detail 재사용 시나리오 시뮬레이션'), findsNothing);
      // pop 이후에도 push 전에 바꿔둔 Riverpod 상태(밀도=1)가 그대로 유지된다.
      expect(container.read(closetDensityProvider), 1);
    },
  );

  // ── 실제 모바일 폭(360px)에서의 헤더 오버플로 여부 ───────────────────────────

  testWidgets(
    '좁은 실제 모바일 폭(360px)에서도 옷장 메인 헤더(카테고리 토글+계절 드롭다운+밀도/정렬 '
    '아이콘+"선택" 버튼)가 오버플로 예외 없이 렌더링되고, 계절 필터·밀도 토글·FAB 펼침이 '
    '동일하게 동작한다',
    (tester) async {
      await pumpApp(tester, size: const Size(360, 1400));

      expect(tester.takeException(), isNull);
      expect(find.byType(ClosetMainScreen), findsOneWidget);
      expect(find.byType(CategoryToggleDropdown), findsOneWidget);
      expect(find.text('선택'), findsOneWidget);

      // 분류 기준 캡슐 동작 확인(좁은 폭에서도 드롭다운 오버레이가 정상 표시되는지) — "계절"
      // 중분류를 고른 뒤 소분류로 "여름"까지 드릴인.
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('계절').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(DropdownButton<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('여름').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 밀도 토글 동작 확인.
      await tester.tap(find.byTooltip('그리드 밀도 전환'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // FAB 펼침 시 긴 라벨("이 분류에 여러 장 추가하기")도 오버플로 없이 표시되는지.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('이 분류에 여러 장 추가하기'), findsOneWidget);
    },
  );

  // ── 비정형 사용 흐름: 계절 드롭다운을 연 채로 FAB 위치를 탭 ─────────────────────

  testWidgets(
    '계절 드롭다운 오버레이가 열려 있는 상태에서 FAB 위치를 탭해도(정해진 순서를 벗어난 조작) '
    '크래시 없이 처리된다 — Flutter DropdownButton의 모달 배리어가 그 첫 탭을 "바깥 탭으로 '
    '드롭다운 닫기"로 소비하고(FAB로 히트테스트가 전달되지 않음, 정상 프레임워크 동작) FAB는 '
    '펼쳐지지 않으며, 그 다음 탭에서야 실제로 FAB가 펼쳐진다',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      // 기본 중분류가 "전체보기"라, 열림 여부는 오버레이에서만 보이는 다른 옵션("옷 종류")으로
      // 판단한다.
      expect(find.text('옷 종류'), findsWidgets); // 드롭다운 오버레이가 열려 있음

      // 드롭다운이 열린 채로 옵션을 선택하지 않고 FAB 위치를 탭한다(warnIfMissed: false —
      // 모달 배리어가 이 탭을 가로챌 것으로 예상되는 상황을 의도적으로 재현하는 것이라
      // Flutter의 "hit test 안 됨" 경고가 예상된 결과임을 명시).
      await tester.tap(find.byType(FloatingActionButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // 첫 탭은 드롭다운을 닫는 데만 소비되어(오버레이의 "옷 종류" 옵션이 사라짐) FAB는 아직
      // 접힌 상태.
      expect(find.text('옷 종류'), findsNothing);
      expect(find.text('한 장 추가하기'), findsNothing);

      // 드롭다운이 닫힌 지금은 같은 위치를 탭하면 실제로 FAB가 히트테스트되어 펼쳐진다.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('한 장 추가하기'), findsOneWidget);
      expect(find.text('여러 장 추가하기'), findsOneWidget);
    },
  );
}
