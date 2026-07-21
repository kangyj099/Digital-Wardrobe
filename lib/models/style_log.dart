class StyleLog {
  const StyleLog({
    required this.id,
    required this.coverImagePath,
    required this.wornDate,
    this.linkedCompositionId,
    this.additionalImagePaths = const [],
    this.location = '',
    this.isIncomplete = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String id;
  final String coverImagePath;
  final DateTime wornDate;
  final String? linkedCompositionId;
  final List<String> additionalImagePaths;
  final String location;
  final bool isIncomplete;
  final bool isDeleted;
  final DateTime? deletedAt;

  static const Object _unset = Object();

  StyleLog copyWith({
    String? id,
    String? coverImagePath,
    DateTime? wornDate,
    Object? linkedCompositionId = _unset,
    List<String>? additionalImagePaths,
    String? location,
    bool? isIncomplete,
    bool? isDeleted,
    Object? deletedAt = _unset,
  }) {
    return StyleLog(
      id: id ?? this.id,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      wornDate: wornDate ?? this.wornDate,
      linkedCompositionId: identical(linkedCompositionId, _unset)
          ? this.linkedCompositionId
          : linkedCompositionId as String?,
      additionalImagePaths: additionalImagePaths ?? this.additionalImagePaths,
      location: location ?? this.location,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
