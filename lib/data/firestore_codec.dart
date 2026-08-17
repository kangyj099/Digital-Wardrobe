/// Firestore 문서와 Dart 모델 사이의 공통 변환 규칙.
///
/// `lib/data/`는 직렬화·매핑 전용이다. Riverpod 상태를 건드리지 않고 Flutter UI에도
/// 의존하지 않는다. `lib/services/`가 "Riverpod 없는 순수 async I/O"로 나뉜 것과 같은
/// 기준의 분리다(`docs/reference/data/00_DataSchema.md` §13.3).
///
/// **모델이 `cloud_firestore`를 직접 import하지 않게 하려고 이 계층을 뒀다.**
/// `lib/models/`가 Flutter UI 레이어에 의존하지 않는다는 규칙이 이미 있고
/// (`enums.dart`의 `ArtboardBackgroundColor` 주석, 2026-08-07 Audit이 확립),
/// `Timestamp`를 모델에 들이는 것도 같은 종류의 위반이다.
///
/// ## 규칙
///
/// * 폐쇄 어휘는 **enum 이름 문자열**로 저장한다(§3). 라벨(한글)이 아니다.
/// * 날짜는 Firestore `Timestamp`로 저장한다.
/// * nullable 필드도 키를 생략하지 않고 명시적으로 `null`을 쓴다. 필드 부재와 null이
///   갈라지면 부분 업데이트에서 의미가 흔들린다.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// enum 이름 문자열을 enum 값으로 되돌린다.
///
/// 모르는 이름이면 null을 준다. 던지지 않는 이유는 이 함수가 서버에서 온 데이터를
/// 읽는 경로이기 때문이다. 앱보다 새로운 버전이 쓴 값이나 폐기된 값 하나 때문에
/// 문서 전체를 못 읽게 되는 편이 더 나쁘다.
///
/// 이 프로젝트의 폐쇄 어휘 필드는 전부 nullable이라 null이 "미분류"로 자연스럽게 흡수된다.
T? enumFromName<T extends Enum>(List<T> values, Object? raw) {
  if (raw is! String) return null;
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return null;
}

/// enum을 저장용 이름 문자열로 바꾼다.
String? enumToName(Enum? value) => value?.name;

/// `Timestamp`(또는 이미 변환된 `DateTime`)를 `DateTime`으로 읽는다.
///
/// 쓰기 경로에서는 `DateTime`을 그대로 넘겨도 된다. Firestore SDK가 알아서
/// `Timestamp`로 바꾼다. 읽기 경로는 항상 `Timestamp`로 돌아오므로 이 함수가 필요하다.
DateTime? dateTimeFromFirestore(Object? raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  return null;
}

/// non-nullable 날짜 필드용. 값이 없거나 타입이 다르면 던진다.
///
/// [field]와 [documentId]는 어느 문서의 어느 필드가 깨졌는지 로그에서 바로 짚기 위한 것이다.
DateTime requiredDateTime(Object? raw, {required String field, required String documentId}) {
  final value = dateTimeFromFirestore(raw);
  if (value == null) {
    throw FormatException(
      '문서 "$documentId"의 필수 날짜 필드 "$field"를 읽을 수 없다(값: $raw).',
    );
  }
  return value;
}

/// non-nullable 문자열 필드용. 없으면 [fallback]을 쓴다.
///
/// 스키마상 기본값이 있는 필드(`location`/`memo` 등)를 위한 것이다.
String stringOr(Object? raw, String fallback) => raw is String ? raw : fallback;

/// non-nullable bool 필드용.
bool boolOr(Object? raw, bool fallback) => raw is bool ? raw : fallback;

/// non-nullable int 필드용. Firestore의 숫자는 `int`/`double` 양쪽으로 올 수 있다.
int intOr(Object? raw, int fallback) {
  if (raw is int) return raw;
  if (raw is double) return raw.toInt();
  return fallback;
}

/// non-nullable double 필드용. Firestore는 정수로 저장된 값을 `int`로 돌려주므로
/// `as double` 캐스트는 런타임에 터진다.
double doubleOr(Object? raw, double fallback) {
  if (raw is double) return raw;
  if (raw is int) return raw.toDouble();
  return fallback;
}

/// 문자열 배열 필드용. 문자열이 아닌 원소는 버린다.
List<String> stringListFrom(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final element in raw)
      if (element is String) element,
  ];
}
