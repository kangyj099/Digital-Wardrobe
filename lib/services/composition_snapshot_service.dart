// lib/services/composition_snapshot_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// `lib/services/` 첫 사례 — Riverpod 상태를 다루지 않는 순수 비동기 I/O/플랫폼 연동
/// 로직은 이 폴더, Riverpod 상태를 다루는 로직은 계속 `providers/`(`docs/history/
/// Decision.md` "코디 스냅샷 캡처/로컬 저장 아키텍처 확정" — 이후 기능(export/import,
/// 업로드 큐, AI 분석 등)도 따르는 확정된 규칙).

/// [path]가 번들 에셋 경로(`assets/...`, mock 데이터가 쓰는 형태)면 true — 이런 경로는
/// `Image.asset`으로 열어야 하고, [saveCompositionSnapshot]의 이전 파일 삭제 대상도
/// 아니다(에셋은 로컬 파일시스템에 실제로 존재하는 런타임 파일이 아니라 앱 번들에
/// 포함된 리소스이므로 삭제 시도 자체가 무의미/위험).
bool isBundledAssetPath(String path) => path.startsWith('assets/');

/// [compositionId] 코디의 평면 렌더 스냅샷 PNG([pngBytes])를 앱 전용 로컬 디렉토리
/// (`<applicationSupportDirectory>/composition_snapshots/`)에 저장하고, 새로 저장된
/// 파일의 절대 경로를 반환한다(`docs/reference/data/00_DataSchema.md` §13.3).
///
/// 캐시/임시 디렉토리가 아니라 `getApplicationSupportDirectory()`를 쓴다 — OS가 예고
/// 없이 비울 수 있는 캐시/임시 디렉토리를 쓰면 "목록/상세는 항상 스냅샷 사용, 안 깨짐"
/// 보장이 깨진다. 앱 전용 디렉토리라 별도 플랫폼 저장 권한도 필요 없다.
///
/// 파일명은 매 호출마다 새로 발급한다(`{compositionId}_{microsecondsSinceEpoch}.png`) —
/// `Image.file`의 캐시가 경로 기준(mtime 아님)이라, 고정 파일명을 덮어쓰면 재생성 후에도
/// 이전 캐시 이미지가 계속 화면에 보이는 문제가 생긴다. 신규 코디 id 발급 시 이미 쓰는
/// `'comp_${DateTime.now().microsecondsSinceEpoch}'` 패턴과 같은 disambiguation이다.
///
/// [previousCoverImagePath]가 있고 번들 에셋 경로가 아니면([isBundledAssetPath]), 새
/// 파일 저장 성공 후 그 이전 파일을 best-effort로 삭제한다 — 삭제가 실패해도(파일 잠금
/// 등) 무시하고 재시도하지 않는다. 실패해도 이 함수 자체의 성공(새 스냅샷 저장)에는
/// 영향 없다.
Future<String> saveCompositionSnapshot({
  required String compositionId,
  required Uint8List pngBytes,
  String? previousCoverImagePath,
}) async {
  final supportDir = await getApplicationSupportDirectory();
  final snapshotDir = Directory('${supportDir.path}/composition_snapshots');
  await snapshotDir.create(recursive: true);

  final fileName = '${compositionId}_${DateTime.now().microsecondsSinceEpoch}.png';
  final file = File('${snapshotDir.path}/$fileName');
  await file.writeAsBytes(pngBytes);

  await deleteCompositionSnapshot(previousCoverImagePath);

  return file.path;
}

/// [coverImagePath]가 가리키는 스냅샷 파일을 best-effort로 지운다 — 실패해도(파일 잠금 등)
/// 삼키고 재시도하지 않는다(§13.3). `null`이거나 번들 에셋 경로면 아무것도 하지 않는다
/// (에셋은 앱 번들 리소스라 삭제 대상이 아니다).
///
/// 호출 지점 2곳: 재생성 시 이전 파일 정리([saveCompositionSnapshot] 내부), 그리고 코디
/// 영구삭제(purge) 시 정리(`CompositionsNotifier.purgeMany`) — 후자가 없으면 purge된 코디의
/// 스냅샷이 디스크에 영원히 남는다.
Future<void> deleteCompositionSnapshot(String? coverImagePath) async {
  if (coverImagePath == null || isBundledAssetPath(coverImagePath)) return;
  try {
    await File(coverImagePath).delete();
  } on FileSystemException {
    // best-effort — 실패해도 무시(§13.3).
  }
}
