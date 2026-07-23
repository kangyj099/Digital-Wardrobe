/// 소분류 provider의 상태 3가지: 미선택(그룹 개요) / 특정 값으로 드릴인 / 미분류로 드릴인.
/// provider 자체가 null이면 미선택, non-null이면 드릴인(그 안의 [value]가 null이면 미분류).
class DrilledValue<T> {
  const DrilledValue.value(T v) : value = v;
  const DrilledValue.unclassified() : value = null;

  final T? value;

  bool get isUnclassified => value == null;

  @override
  bool operator ==(Object other) => other is DrilledValue<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// 분류 기준 드릴다운의 "그룹 개요" 상태에서 그리는 폴더형 카드 한 장의 데이터.
class ClassificationGroupSummary {
  const ClassificationGroupSummary({
    required this.label,
    required this.thumbnailPaths,
    required this.count,
    required this.value,
  });

  final String label;

  /// 콜라주용, 최대 4장.
  final List<String> thumbnailPaths;
  final int count;

  /// 탭 시 드릴인 provider에 그대로 세팅할 값. `null`이면 미분류 카드.
  final Object? value;
}

/// index 기반(연도/열거형 index) nullable 정렬 — null은 항상 "가장 큰 값"으로 취급해
/// [ascending]이면 맨 뒤, 아니면 맨 앞으로 보낸다
/// (스펙 §3.4 — 옷장/코디 provider가 공유하는 유일한 정렬 헬퍼).
int compareNullableIndexLast(int? a, int? b, {required bool ascending}) {
  if (a == null && b == null) return 0;
  if (a == null) return ascending ? 1 : -1;
  if (b == null) return ascending ? -1 : 1;
  return ascending ? a.compareTo(b) : b.compareTo(a);
}
