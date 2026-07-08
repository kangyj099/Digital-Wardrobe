import '../models/clothing_item.dart';
import '../models/composition.dart';
import '../models/style_log.dart';

final List<ClothingItem> mockClothingItems = [
  const ClothingItem(id: 'c01', name: '플로럴 원피스', category: 'dress', color: 'pink', season: '봄', material: '면', imagePath: 'assets/images/mock/IMG_4259_preview_rev_1.png', location: '옷장 2단', wearCount: 3),
  const ClothingItem(id: 'c02', name: '데님 팬츠', category: 'bottom', color: 'black', season: '사계절', material: '데님', imagePath: 'assets/images/mock/IMG_4260_preview_rev_1.png', wearCount: 9),
  const ClothingItem(id: 'c03', name: '그래픽 와이드팬츠', category: 'bottom', color: 'khaki', season: '사계절', material: '데님', imagePath: 'assets/images/mock/IMG_4261_preview_rev_1.png', wearCount: 4),
  const ClothingItem(id: 'c04', name: '트렌치코트', category: 'outer', color: 'brown', season: '가을', material: '가죽', imagePath: 'assets/images/mock/IMG_4264_preview_rev_1.png', location: '옷장 1단', wearCount: 2),
  const ClothingItem(id: 'c05', name: '스트라이프 블라우스', category: 'top', color: 'burgundy', season: '사계절', material: '실크·새틴', imagePath: 'assets/images/mock/IMG_4267_preview_rev_1.png', wearCount: 5),
  const ClothingItem(id: 'c06', name: '코튼 반바지', category: 'bottom', color: 'sage', season: '여름', material: '면', imagePath: 'assets/images/mock/IMG_4273.PNG', isIncomplete: true),
  const ClothingItem(id: 'c07', name: '리넨 반바지', category: 'bottom', color: 'blue', season: '여름', material: '리넨', imagePath: 'assets/images/mock/IMG_4275.PNG', wearCount: 6),
  const ClothingItem(id: 'c08', name: '슬립 드레스', category: 'dress', color: 'black', season: '사계절', material: '면', imagePath: 'assets/images/mock/IMG_4276.PNG', wearCount: 1),
  const ClothingItem(id: 'c09', name: '레더 재킷', category: 'outer', color: 'black', season: '가을', material: '가죽', imagePath: 'assets/images/mock/IMG_4277.PNG', location: '옷장 1단', wearCount: 7),
  const ClothingItem(id: 'c10', name: '그래픽 반팔티', category: 'top', color: 'white', season: '여름', material: '면', imagePath: 'assets/images/mock/IMG_4257_preview_rev_1.png', wearCount: 12),
  const ClothingItem(id: 'c11', name: '그래픽 맨투맨', category: 'top', color: 'pink', season: '봄', material: '면', imagePath: 'assets/images/mock/IMG_4262_preview_rev_1.png', wearCount: 8),
  const ClothingItem(id: 'c12', name: '플로럴 스커트', category: 'bottom', color: 'multi', season: '봄', material: '면', imagePath: 'assets/images/mock/IMG_4268-removebg-preview.png', wearCount: 2),
];

final List<Composition> mockCompositions = [
  const Composition(
    id: 'comp01',
    name: '데일리 룩',
    season: '봄',
    items: [
      CompositionItemPlacement(clothingItemId: 'c01', x: 40, y: 40, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c11', x: 60, y: 120, zIndex: 1),
      CompositionItemPlacement(clothingItemId: 'c07', x: 60, y: 260, zIndex: 2),
      CompositionItemPlacement(clothingItemId: 'c03', x: 80, y: 380, zIndex: 3),
    ],
  ),
  const Composition(
    id: 'comp02',
    name: '포멀 코디',
    season: '가을',
    items: [
      CompositionItemPlacement(clothingItemId: 'c04', x: 40, y: 40, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c05', x: 70, y: 140, zIndex: 1),
    ],
  ),
];

final List<StyleLog> mockStyleLogs = [
  StyleLog(
    id: 'log01',
    coverImagePath: 'assets/images/mock/IMG_4259_preview_rev_1.png',
    wornDate: DateTime(2026, 1, 5),
    linkedCompositionId: 'comp01',
    additionalImagePaths: const ['assets/images/mock/IMG_4262_preview_rev_1.png', 'assets/images/mock/IMG_4275.PNG'],
    location: '집',
  ),
  StyleLog(
    id: 'log02',
    coverImagePath: 'assets/images/mock/IMG_4264_preview_rev_1.png',
    wornDate: DateTime(2026, 1, 10),
    linkedCompositionId: 'comp02',
    location: '회사',
  ),
];
