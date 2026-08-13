import 'package:flutter_test/flutter_test.dart';
import 'package:digittal_wardrobe/services/composition_snapshot_service.dart';

/// `saveCompositionSnapshot` 자체(실제 파일 I/O, `path_provider` 플랫폼 채널 필요)는
/// 순수 위젯/유닛 테스트로 의미 있게 검증하기 어렵다 — 실제 PNG가 실제로 쓰이는지는
/// 통합테스트/실기기 검증 대상(Task 매니페스트의 Verification 섹션 참고). 여기서는 I/O가
/// 없는 순수 판정 함수 [isBundledAssetPath]만 다룬다.
void main() {
  group('isBundledAssetPath', () {
    test('assets/로 시작하면 true(번들 에셋 경로)', () {
      expect(isBundledAssetPath('assets/images/mock/IMG_4259_preview_rev_1.png'), isTrue);
    });

    test('로컬 파일시스템 절대 경로면 false', () {
      expect(
        isBundledAssetPath('C:/Users/user/AppData/composition_snapshots/comp01_123.png'),
        isFalse,
      );
      expect(isBundledAssetPath('/data/user/0/app/composition_snapshots/comp01_123.png'), isFalse);
    });
  });
}
