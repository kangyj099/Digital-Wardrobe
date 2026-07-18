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
  });

  final String id;
  final String coverImagePath;
  final DateTime wornDate;
  final String? linkedCompositionId;
  final List<String> additionalImagePaths;
  final String location;
  final bool isIncomplete;
  final bool isDeleted;

  StyleLog copyWith({
    String? id,
    String? coverImagePath,
    DateTime? wornDate,
    String? linkedCompositionId,
    List<String>? additionalImagePaths,
    String? location,
    bool? isIncomplete,
    bool? isDeleted,
  }) {
    return StyleLog(
      id: id ?? this.id,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      wornDate: wornDate ?? this.wornDate,
      linkedCompositionId: linkedCompositionId ?? this.linkedCompositionId,
      additionalImagePaths: additionalImagePaths ?? this.additionalImagePaths,
      location: location ?? this.location,
      isIncomplete: isIncomplete ?? this.isIncomplete,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
