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

/// 캡처 전 이미지 프리캐시([_precacheItemImages])의 전체 대기 상한. 이 안에 디코드가 안
/// 끝나면 캡처를 포기한다(위 [captureCompositionSnapshot] 문서의 "실패하면 포기" 근거).
/// 값 근거: 코디 1개의 상한은 15장(`docs/reference/data/00_DataSchema.md` §4 "≤15 items")이고
/// 이 이미지들은 직전까지 화면에 떠 있던 것들이라 정상 경로에선 수십 ms 안에 끝난다 —
/// 5초는 "정상적으로는 절대 안 걸리는" 여유값이며, 커밋 UI가 무한정 멈추는 것만 막는
/// 상한선이다.
const Duration _precacheTimeout = Duration(seconds: 5);

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
/// **콜드 디코드 대응(§13.1이 예고한 리스크, 실기기에서 실제로 재현됨)**: 아이템 이미지가
/// 이미지 캐시에 없으면(`Image.asset`의 콜드 디코드) 아래 `endOfFrame` 두 번 대기 안에
/// 디코딩이 안 끝나 **그 아이템이 빠진 채로**, 최악의 경우 전부 빈 배경만 캡처된다. Tester가
/// 실기기에서 재현: 커밋 직전에 이미지 캐시를 비우면(=OS 메모리 압박 시 Flutter가 실제로
/// 하는 동작) 5회 중 3회가 완전 백지, 1회가 부분 캡처였다. 그래서 오버레이를 마운트하기
/// **전에** 모든 아이템 이미지를 [precacheImage]로 강제 디코드해 캐시에 올려두고 기다린다 —
/// 캐시에 이미 있으면 `Image.asset`의 스트림 리스너가 첫 빌드에서 동기적으로 이미지를
/// 받으므로 첫 페인트부터 그려진 상태가 된다.
///
/// 개별 이미지 로드 실패는 무시하고 진행한다(그 아이템은 화면에서도 안 보이므로 스냅샷에서
/// 빠지는 게 일관적임). 반면 전체 프리캐시가 [_precacheTimeout] 안에 안 끝나면 예외를 던져
/// **캡처 자체를 포기**한다 — 백지 스냅샷을 저장해 기존 커버를 덮어쓰는 것보다, §13.3의
/// 실패 처리(이전 `coverImagePath` 유지)로 빠지는 쪽이 안전하기 때문이다.
Future<Uint8List> captureCompositionSnapshot(
  BuildContext context, {
  required List<ArtboardItem> items,
  required ArtboardBackgroundColor backgroundColor,
  double captureSize = 1024,
}) async {
  await _precacheItemImages(context, items);
  if (!context.mounted) {
    throw StateError('captureCompositionSnapshot: 프리캐시 대기 중 화면이 unmount됐습니다.');
  }

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
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('captureCompositionSnapshot: PNG 인코딩에 실패했습니다.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      // `toImage()`가 넘겨준 `ui.Image`는 GC 대상이 아닌 네이티브 리소스라 명시적으로
      // 해제해야 한다(1024×1024 RGBA ≈ 4MB — 커밋마다 누수되면 금방 커진다).
      image.dispose();
    }
  } finally {
    // remove()(Overlay에서 분리)와 dispose()(리소스 해제)는 분리된 2단계 생명주기다
    // (`static_artboard.dart`/`interactive_artboard.dart`의 동일 처리 참고).
    entry.remove();
    entry.dispose();
  }
}

/// [items]의 이미지를 전부 이미지 캐시에 올려둔다 — 캡처 시점에 콜드 디코드가 남아 있지
/// 않게 하기 위함(위 [captureCompositionSnapshot] 문서의 "콜드 디코드 대응" 참고).
///
/// 같은 `imagePath`가 여러 아이템에 쓰일 수 있으므로 경로 기준으로 중복을 제거한다.
/// [ArtboardItemView]가 `Image.asset(item.imagePath)`로 그리므로 여기서도 동일한
/// `AssetImage(path)` 키로 프리캐시해야 캐시가 실제로 적중한다.
///
/// 개별 실패는 [precacheImage]의 `onError`로 삼켜서 나머지 이미지의 프리캐시를 막지 않는다
/// (로드 자체가 안 되는 이미지는 화면에서도 안 보이므로 스냅샷에서 빠지는 게 일관적).
/// 전체가 [_precacheTimeout]을 넘기면 `TimeoutException`이 그대로 호출부로 전파돼 캡처가
/// 중단된다.
Future<void> _precacheItemImages(BuildContext context, List<ArtboardItem> items) async {
  final distinctPaths = {for (final item in items) item.imagePath};
  if (distinctPaths.isEmpty) return;
  await Future.wait([
    for (final path in distinctPaths)
      precacheImage(
        AssetImage(path),
        context,
        onError: (error, stackTrace) {
          debugPrint('captureCompositionSnapshot: 이미지 프리캐시 실패(무시하고 진행) $path — $error');
        },
      ),
  ]).timeout(_precacheTimeout);
}
