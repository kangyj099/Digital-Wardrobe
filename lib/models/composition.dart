import 'enums.dart';

class CompositionItemPlacement {
  const CompositionItemPlacement({
    required this.clothingItemId,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
  });

  final String clothingItemId;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int zIndex;
}

class Composition {
  const Composition({
    required this.id,
    required this.name,
    required this.items,
    this.season,
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final List<CompositionItemPlacement> items;
  final Season? season;
  final bool isDeleted;
}
