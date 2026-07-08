import '../models/clothing_item.dart';
import '../models/composition.dart';
import '../models/style_log.dart';

final List<ClothingItem> mockClothingItems = [
  const ClothingItem(id: 'c01', name: 'padding jacket', category: 'outer', color: 'navy', season: '겨울', imagePath: 'assets/images/mock/item_01.jpg', location: '옷장 1단', wearCount: 5),
  const ClothingItem(id: 'c02', name: 'long coat', category: 'outer', color: 'beige', season: '겨울', imagePath: 'assets/images/mock/item_02.jpg', location: '옷장 1단', wearCount: 2),
  const ClothingItem(id: 'c03', name: 'knit', category: 'top', color: 'ivory', season: '겨울', imagePath: 'assets/images/mock/item_03.jpg', wearCount: 8),
  const ClothingItem(id: 'c04', name: 'scarf', category: 'accessory', color: 'gray', season: '겨울', imagePath: 'assets/images/mock/item_04.jpg', wearCount: 1),
  const ClothingItem(id: 'c05', name: 'gloves', category: 'accessory', color: 'black', season: '겨울', imagePath: 'assets/images/mock/item_05.jpg', wearCount: 0),
  const ClothingItem(id: 'c06', name: 'fleece pants', category: 'bottom', color: 'gray', season: '겨울', imagePath: 'assets/images/mock/item_06.jpg', isIncomplete: true),
  const ClothingItem(id: 'c07', name: 'boots', category: 'shoes', color: 'brown', season: '겨울', imagePath: 'assets/images/mock/item_07.jpg', wearCount: 3),
  const ClothingItem(id: 'c08', name: 'cardigan', category: 'top', color: 'camel', season: '겨울', imagePath: 'assets/images/mock/item_08.jpg', wearCount: 4),
  const ClothingItem(id: 'c09', name: 'beanie', category: 'accessory', color: 'black', season: '겨울', imagePath: 'assets/images/mock/item_09.jpg', wearCount: 2),
  const ClothingItem(id: 'c10', name: 'wool socks', category: 'accessory', color: 'gray', season: '겨울', imagePath: 'assets/images/mock/item_10.jpg', wearCount: 6),
  const ClothingItem(id: 'c11', name: 'denim jeans', category: 'bottom', color: 'blue', season: '사계절', imagePath: 'assets/images/mock/item_11.jpg', wearCount: 12),
  const ClothingItem(id: 'c12', name: 'white sneakers', category: 'shoes', color: 'white', season: '사계절', imagePath: 'assets/images/mock/item_12.jpg', wearCount: 9),
];

final List<Composition> mockCompositions = [
  const Composition(
    id: 'comp01',
    name: '겨울 데일리',
    season: '겨울',
    items: [
      CompositionItemPlacement(clothingItemId: 'c01', x: 40, y: 40, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c03', x: 60, y: 120, zIndex: 1),
      CompositionItemPlacement(clothingItemId: 'c11', x: 60, y: 260, zIndex: 2),
      CompositionItemPlacement(clothingItemId: 'c07', x: 80, y: 380, zIndex: 3),
    ],
  ),
  const Composition(
    id: 'comp02',
    name: '포멀 코디',
    season: '겨울',
    items: [
      CompositionItemPlacement(clothingItemId: 'c02', x: 40, y: 40, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c08', x: 70, y: 140, zIndex: 1),
    ],
  ),
];

final List<StyleLog> mockStyleLogs = [
  StyleLog(
    id: 'log01',
    coverImagePath: 'assets/images/mock/item_01.jpg',
    wornDate: DateTime(2026, 1, 5),
    linkedCompositionId: 'comp01',
    additionalImagePaths: const ['assets/images/mock/item_03.jpg', 'assets/images/mock/item_11.jpg'],
    location: '집',
  ),
  StyleLog(
    id: 'log02',
    coverImagePath: 'assets/images/mock/item_02.jpg',
    wornDate: DateTime(2026, 1, 10),
    linkedCompositionId: 'comp02',
    location: '회사',
  ),
];
