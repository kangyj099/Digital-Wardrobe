import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../theme/app_spacing.dart';
import 'category_toggle_dropdown.dart';
import 'frosted_back_button.dart';

/// 화면 관통 공용 UI 셸 — 뒤로가기/카테고리 토글을 화면마다 개별 구현하지 않고 이
/// Scaffold 하나가 소유한다
/// (`docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §2 "B안").
///
/// `Stack` 기반 구조 — `docs/superpowers/specs/2026-07-13-scroll-container-and-header-hud-architecture.md`
/// §1/§6 계약대로, `body`(보통 [AppScrollContainer]로 감싼 스크롤 콘텐츠)가 상태표시줄 바로
/// 아래부터 화면 전체를 차지하고, Header/HUD 조작 요소는 그 위에 `Positioned`로 뜬다(레이아웃
/// 공간을 차지하지 않음). Header가 차지하는 시각적 자리는 `body` 내부의 Content
/// Spacer([contentSpacerHeight])가 담당한다 — 실제 렌더링 위치가 어긋나지 않으려면
/// `body`를 구성하는 화면이 이 정적 메서드로 계산한 값을 스크롤 콘텐츠 상단 padding으로
/// 그대로 써야 한다(`lib/screens/closet_main_screen.dart` 등 사용례 참고).
///
/// **Header/HUD Pinned Rule(`docs/history/Decision.md`)**: 조작 요소(카테고리 토글,
/// 계절 필터, 밀도 버튼, 선택 버튼 등)는 각각 물리적으로 독립된 [GlassPill]/
/// [GlassCircleButton]이어야 하고, 이 Scaffold는 그 위젯들을 하나의 `Container`/decoration
/// 있는 `Row`로 묶지 않는다 — 아래 각 슬롯이 각자 독립된 `Positioned`로 배치된다.
///
/// - **Row 1**(카테고리 토글 + 헤더 액션): [showCategoryToggle]이 true면 좌측에
///   [CategoryToggleDropdown]을 독립 Positioned로 꽂는다. [headerActions]는 우측에
///   놓이는, 이미 각자 독립적으로 글래스 스타일링된 위젯 리스트다(예: "선택" 버튼을
///   `GlassPill`로 감싼 것) — 이 Scaffold는 배치만 하고 스타일을 추가로 씌우지 않는다.
/// - **Row 2**([secondaryControlsLeft]/[secondaryControlsRight]): 두 번째 툴바 행 —
///   좌/우 각각 독립 Positioned. 옷장/코디 메인의 분류 기준 드릴다운 캡슐(좌)과 밀도·정렬
///   버튼(우) 등에 쓰인다. 둘 다 비어 있으면 이 행 자체가 렌더링되지 않는다.
/// - 그룹형 드릴다운 전용 슬롯(`groupingBar`)은 삭제됨(2026-07-19, 화면별
///   `ClassificationDrilldownCapsule`로 대체 — `lib/screens/closet_main_screen.dart`/
///   `composition_main_screen.dart`가 Row 2 좌측에 floating pill로 직접 꽂는다).
class AppMainScaffold extends StatelessWidget {
  const AppMainScaffold({
    super.key,
    required this.current,
    required this.body,
    this.showBackButton = true,
    this.showCategoryToggle = true,
    this.headerActions = const [],
    this.secondaryControlsLeft = const [],
    this.secondaryControlsRight = const [],
    this.floatingActionButton,
  });

  /// 헤더 Row 1 좌측의 [CategoryToggleDropdown]에 넘길 현재 카테고리.
  final AppCategory current;

  /// 본문 슬롯 — 보통 [AppScrollContainer]로 감싼 스크롤 콘텐츠.
  final Widget body;

  /// 뒤로가기 버튼([FrostedBackButton]) 노출 여부. true여도 실제로는
  /// `context.canPop()`이 true일 때만 렌더링된다(스택 최상단이면 자리 자체를 차지하지 않음).
  final bool showBackButton;

  /// Row 1 좌측에 [CategoryToggleDropdown]을 자동으로 꽂을지 여부.
  final bool showCategoryToggle;

  /// Row 1 우측 슬롯 — 이미 각자 독립적으로 글래스 스타일링된 위젯 리스트(예: "선택" 버튼).
  final List<Widget> headerActions;

  /// Row 2 좌측 슬롯 — 이미 각자 독립적으로 글래스 스타일링된 위젯 리스트.
  final List<Widget> secondaryControlsLeft;

  /// Row 2 우측 슬롯 — 이미 각자 독립적으로 글래스 스타일링된 위젯 리스트.
  final List<Widget> secondaryControlsRight;

  /// FAB passthrough — `Scaffold.floatingActionButton`으로 그대로 전달.
  final Widget? floatingActionButton;

  /// 디버그 목업 상태바가 항상 예약하는 높이(릴리즈에서도 레이아웃 안정성을 위해 예약).
  static const double statusBarHeight = 24;

  /// 모든 floating control([GlassPill]/[GlassCircleButton])이 공유하는 고정 높이 —
  /// [kMinInteractiveDimension](48)과 동일. Content Spacer가 실측 대신 이 고정값으로
  /// 헤더 높이를 계산할 수 있는 전제.
  static const double controlHeight = kMinInteractiveDimension;

  /// 상태바/Row1/Row2 밴드 사이의 간격.
  static const double rowGap = AppSpacing.xs;

  /// Content Spacer(스펙 §4) 계산 — 화면이 `body`(보통 [AppScrollContainer]) 내부
  /// 스크롤 콘텐츠의 상단 padding으로 그대로 써야 하는 값. 실측이 아니라 이 Scaffold가
  /// 실제로 Positioned하는 밴드 높이(고정값) 합산이라 스펙 §4 "알려진 고정값" 경로를
  /// 그대로 따른다.
  static double contentSpacerHeight({bool hasSecondaryRow = false}) {
    double height = rowGap + controlHeight; // Row 1
    if (hasSecondaryRow) height += rowGap + controlHeight; // Row 2
    height += rowGap; // 마지막 밴드와 실제 콘텐츠 사이 여백
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPop = context.canPop();

    final row1Top = statusBarHeight + rowGap;
    final row2Top = row1Top + controlHeight + rowGap;

    return Scaffold(
      body: Container(
        color: colorScheme.surface,
        child: Stack(
          children: [
            // 우상단 세이지 틴트 — 장식용 배경 오버레이(스크롤/상호작용에 반응하지 않는 정적 레이어).
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.secondary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 디버그 빌드에서만 목업 상태바를 그린다. 릴리즈에서도 동일한 높이를 예약해
            // 레이아웃이 빌드 모드에 따라 흔들리지 않게 한다. Stack 최상단 레이어.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: statusBarHeight,
                child: kDebugMode ? _buildDebugStatusBar(context) : null,
              ),
            ),

            // 콘텐츠 — Header/HUD는 레이아웃 공간을 차지하지 않고 이 위에 얹힌다(스펙 §1).
            // 실제 콘텐츠 시작 위치는 body 내부의 Content Spacer가 결정한다.
            Positioned.fill(top: statusBarHeight, child: body),

            // Row 1: 카테고리 토글(좌) — 독립 Positioned.
            if (showCategoryToggle)
              Positioned(
                top: row1Top,
                left: AppSpacing.md,
                child: CategoryToggleDropdown(current: current),
              ),
            // Row 1: 헤더 액션(우) — 각 위젯이 이미 독립적으로 글래스 스타일링되어 있으므로
            // 이 Row는 배치용 레이아웃일 뿐 시각적 표면(배경/보더/그림자)을 추가하지 않는다.
            if (headerActions.isNotEmpty)
              Positioned(
                top: row1Top,
                right: AppSpacing.md,
                child: Row(mainAxisSize: MainAxisSize.min, children: _withGaps(headerActions)),
              ),

            // Row 2: secondaryControls — 좌/우 각각 독립 Positioned.
            if (secondaryControlsLeft.isNotEmpty)
              Positioned(
                top: row2Top,
                left: AppSpacing.md,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _withGaps(secondaryControlsLeft),
                ),
              ),
            if (secondaryControlsRight.isNotEmpty)
              Positioned(
                top: row2Top,
                right: AppSpacing.md,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _withGaps(secondaryControlsRight),
                ),
              ),

            // 뒤로 갈 곳이 있을 때만 렌더링(스택 최상단에 없으면 자리 자체를 차지하지 않음).
            // 우측은 흔히 floatingActionButton이 쓰고 있어 좌측에 배치.
            if (showBackButton && canPop)
              Positioned(
                left: AppSpacing.md,
                bottom: AppSpacing.md,
                child: FrostedBackButton(onTap: () => context.pop()),
              ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  List<Widget> _withGaps(List<Widget> children) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) result.add(const SizedBox(width: AppSpacing.xs));
      result.add(children[i]);
    }
    return result;
  }

  Widget _buildDebugStatusBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('9:41', style: TextStyle(fontSize: 12)),
          Row(
            children: [
              Icon(Icons.signal_cellular_alt, size: 14),
              SizedBox(width: AppSpacing.xxs),
              Icon(Icons.wifi, size: 14),
              SizedBox(width: AppSpacing.xxs),
              Icon(Icons.battery_full, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
