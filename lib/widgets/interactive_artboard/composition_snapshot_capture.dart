// lib/widgets/interactive_artboard/composition_snapshot_capture.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'artboard_background_color.dart';
import 'artboard_item.dart';
import 'static_artboard.dart';

/// [items]를 [backgroundColor] 배경의 [captureSize]×[captureSize] 정사각형 캔버스에
/// `StaticArtboard`로 오프스크린 렌더링해 PNG 바이트로 캡처한다
/// (`docs/reference/data/00_DataSchema.md` §13.1, `docs/history/Decision.md` "코디 스냅샷
/// 캡처/로컬 저장 아키텍처 확정").
///
/// 캡처 대상이 `InteractiveArtboard`가 아니라 [StaticArtboard]인 이유: `InteractiveArtboard`는
/// 배경색 버튼/선택 테두리/핸들 같은 편집기 전용 크롬을 같은 `Stack`에 그려서 캡처에 섞여
/// 들어간다 — `StaticArtboard`는 이미 아이템+배경만 렌더링한다.
///
/// **`Opacity(opacity: 0)`로 감싸면 절대 안 된다** — `RenderOpacity.paint()`는
/// `alpha == 0`이면 자식을 아예 페인트하지 않아, 그 안의 `RepaintBoundary`에 레이어가
/// 붙지 않고 `toImage()`의 `layer! as OffsetLayer`가 무조건 실패한다(Review가 Flutter SDK
/// 소스로 직접 검증한 P0, `docs/history/Decision.md` 참고). 화면 밖 위치(큰 음수
/// `Positioned` offset)와 페인트 여부는 서로 독립적이라, 화면 밖에 두기만 해도 정상적으로
/// 페인트되고 캡처된다.
///
/// 캡처 크기는 호출부의 `MediaQuery`가 아니라 고정 논리 크기([captureSize], 기본
/// 1024×1024 @ `pixelRatio: 1.0`)를 쓴다 — 출력 해상도를 결정적으로 유지하기 위함.
/// `baseItemSizeFraction`이 캔버스 짧은 변 대비 비율이라, 절대 픽셀 크기와 무관하게 화면에
/// 보이던 것과 동일한 비율로 아이템이 배치된다.
///
/// **알려진 리스크(여기서 완전히 해결하지 않음)**: 이 세션에서 한 번도 렌더링된 적 없는
/// `ClothingItem.imagePath`(콜드 `Image.asset` 디코드)는 이 캡처의 `endOfFrame` 대기 안에
/// 디코딩이 안 끝나 빈 타일로 캡처될 수 있다. 두 트리거 지점(에디터 커밋/정리 write-back)
/// 모두 같은 이미지가 방금 화면에 보이던 직후라 이미지 캐시가 warm한 게 보통이다 — 실제
/// 테스트에서 문제가 보이면 캡처 전 `precacheImage()`가 완화책.
Future<Uint8List> captureCompositionSnapshot(
  BuildContext context, {
  required List<ArtboardItem> items,
  required ArtboardBackgroundColor backgroundColor,
  double captureSize = 1024,
}) async {
  final boundaryKey = GlobalKey();
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) => Positioned(
      // 화면 밖(큰 음수 offset)에 마운트 — 위 문서 참고, `Opacity(0)` 대체 금지.
      left: -captureSize * 4,
      top: 0,
      width: captureSize,
      height: captureSize,
      child: StaticArtboard(
        boundaryKey: boundaryKey,
        items: items,
        backgroundColor: backgroundColor,
        // 캡처 전용 오프스크린 인스턴스 — 탭/롱프레스 인터랙션은 실제로 발생하지 않는다.
        onItemTap: (_) {},
        onEditRequested: () {},
      ),
    ),
  );

  try {
    overlay.insert(entry);
    // 표준 Flutter widget-to-image 안전 마진 — 페인트가 실제로 끝난 뒤에 캡처하기 위해
    // 프레임 완료를 두 번 기다린다.
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;

    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('captureCompositionSnapshot: RepaintBoundary 렌더 객체를 찾지 못했습니다.');
    }
    final image = await renderObject.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('captureCompositionSnapshot: PNG 인코딩에 실패했습니다.');
    }
    return byteData.buffer.asUint8List();
  } finally {
    // remove()(Overlay에서 분리)와 dispose()(리소스 해제)는 분리된 2단계 생명주기다
    // (`static_artboard.dart`/`interactive_artboard.dart`의 동일 처리 참고).
    entry.remove();
    entry.dispose();
  }
}
