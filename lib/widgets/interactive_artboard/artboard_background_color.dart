// lib/widgets/interactive_artboard/artboard_background_color.dart
import 'package:flutter/material.dart';

/// 아트보드 배경색의 닫힌 값 집합(스펙 §11.1) — `02_코디.md` "MVP는 흰색/회색/검은색
/// 단색만 지원" 요구사항을 4단계(사용자 확정, 2026-07-19)로 구현한다. `Color`를 위젯
/// 경계로 임의값 주고받지 않고 enum으로 모델링한다(`lib/models/enums.dart`의
/// `Season`/`Weather`와 동일한 패턴 — 닫힌 어휘는 enum, annotated String 아님).
enum ArtboardBackgroundColor {
  white,
  lightGray,
  darkGray,
  black;

  Color get value => switch (this) {
        ArtboardBackgroundColor.white => Colors.white,
        ArtboardBackgroundColor.lightGray => Colors.grey.shade300,
        ArtboardBackgroundColor.darkGray => Colors.grey.shade800,
        ArtboardBackgroundColor.black => Colors.black,
      };
}
