import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/enums.dart';
import '../theme/app_spacing.dart';
import 'category_toggle_dropdown.dart';
import 'frosted_back_button.dart';
import 'overlay_header.dart';

/// 화면 관통 공용 UI 셸 — 뒤로가기/카테고리 토글/그룹형 드릴다운 바를 화면마다 개별
/// 구현하지 않고 이 Scaffold 하나가 소유한다
/// (`docs/superpowers/specs/2026-07-12-cross-screen-ui-shell-design.md` §2 "B안").
///
/// `docs/history/Decision.md`("Step②(Component Library) 1차 라운드 제작 범위 확정 +
/// `AppMainScaffold` 내부 슬롯 구조 지시")가 못박은 구속 조건: Header는 Leading/Title/
/// Actions(slot) 3분할로 만들고, Detail 화면은 별도 Scaffold를 새로 만들지 않고 이 Scaffold의
/// `groupingBar` 슬롯만 비워 재사용한다.
///
/// - **Leading**: [showCategoryToggle]이 true일 때 이 Scaffold가 직접 꽂는
///   [CategoryToggleDropdown] — 화면마다 다시 구현하지 않는다.
/// - **Title**: [headerTitle] — 화면별로 달라지는 헤더 중앙 콘텐츠(옷장 메인의 계절
///   드롭다운/밀도·정렬 아이콘 등). 없으면 Leading만 남는다.
/// - **Actions**: [headerActions] — 헤더 우측(트레일링) 슬롯. 임의 `Widget` 목록을 받는
///   범용 구조라, Detail 화면(Step④)이 `DetailHeaderActions`(드롭다운+⋯메뉴 composite)를
///   그대로 꽂아 쓸 수 있다. Detail처럼 자체 토글이 내장된 composite를 Actions에 꽂을
///   때는 [showCategoryToggle]을 false로 꺼서 Leading과 중복 렌더링되지 않게 한다.
///
/// [groupingBar]는 그룹형 드릴다운 전용 슬롯(옷장/코디 메인만 사용, 그 외 화면은 null로
/// 비워둔다 — Detail도 이 방식으로 처리). 실제 그룹형 드릴다운 UI는 Step③ 몫이라 지금은
/// placeholder(`skeletonRegion` 등)를 그대로 전달해도 된다.
class AppMainScaffold extends StatelessWidget {
  const AppMainScaffold({
    super.key,
    required this.current,
    required this.body,
    this.showBackButton = true,
    this.showCategoryToggle = true,
    this.headerTitle,
    this.headerActions = const [],
    this.groupingBar,
    this.floatingActionButton,
  });

  /// 헤더 Leading의 [CategoryToggleDropdown]에 넘길 현재 카테고리.
  final AppCategory current;

  /// 본문 슬롯.
  final Widget body;

  /// 뒤로가기 버튼([FrostedBackButton]) 노출 여부. true여도 실제로는
  /// `context.canPop()`이 true일 때만 렌더링된다(스택 최상단이면 자리 자체를 차지하지 않음).
  final bool showBackButton;

  /// 헤더 Leading에 [CategoryToggleDropdown]을 자동으로 꽂을지 여부.
  final bool showCategoryToggle;

  /// 헤더 Title(중앙) 슬롯 — 화면별 필터/토글 등 가변 콘텐츠.
  final Widget? headerTitle;

  /// 헤더 Actions(우측/트레일링) 슬롯 — 임의 Widget을 받는 범용 구조.
  final List<Widget> headerActions;

  /// 그룹형 드릴다운 바 슬롯. null이면 자리 자체를 차지하지 않는다.
  final Widget? groupingBar;

  /// FAB passthrough — `Scaffold.floatingActionButton`으로 그대로 전달.
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPop = context.canPop();

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
            Column(
              children: [
                // 디버그 빌드에서만 목업 상태바를 그린다. 릴리즈에서도 동일한 높이를 예약해
                // 레이아웃(children 개수)이 빌드 모드에 따라 흔들리지 않게 한다.
                SizedBox(
                  height: 24,
                  child: kDebugMode ? _buildDebugStatusBar(context) : null,
                ),
                OverlayHeader(
                  actions: headerActions,
                  child: Row(
                    children: [
                      if (showCategoryToggle) ...[
                        CategoryToggleDropdown(current: current),
                        if (headerTitle != null) const SizedBox(width: AppSpacing.md),
                      ],
                      if (headerTitle != null) Expanded(child: headerTitle!),
                    ],
                  ),
                ),
                ?groupingBar,
                Expanded(child: body),
              ],
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
