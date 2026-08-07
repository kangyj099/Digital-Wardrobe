// lib/widgets/interactive_artboard/artboard_background_color.dart
import 'package:flutter/material.dart';
import '../../models/enums.dart';

export '../../models/enums.dart' show ArtboardBackgroundColor;

/// `ArtboardBackgroundColor` → `Color` 매핑. `Color`가 `package:flutter/material.dart`
/// 의존이라, enum 정의 자체(`lib/models/enums.dart`, 순수 Dart)와 분리해 위젯 레이어
/// extension으로 유지한다 — `lib/models/`가 Flutter UI 레이어에 의존하지 않게 하기
/// 위함(Audit 지적, 2026-08-07 레이어 위반 해소. 이전엔 이 파일이 enum 정의 자체를
/// 갖고 있어 `lib/models/composition.dart`/`composition_draft.dart`가 위젯 레이어를
/// import해야 했다).
extension ArtboardBackgroundColorValue on ArtboardBackgroundColor {
  Color get value => switch (this) {
        ArtboardBackgroundColor.white => Colors.white,
        ArtboardBackgroundColor.lightGray => Colors.grey.shade300,
        ArtboardBackgroundColor.darkGray => Colors.grey.shade800,
        ArtboardBackgroundColor.black => Colors.black,
      };
}
