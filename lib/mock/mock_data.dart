import '../models/clothing_item.dart';
import '../models/composition.dart';
import '../models/enums.dart';
import '../models/style_log.dart';
import '../models/trash_entry.dart';

final List<ClothingItem> mockClothingItems = [
  ClothingItem(id: 'c01', name: '플로럴 원피스', category: ClothingCategory.onePiece, color: 'pink', season: Season.springFall, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4259_preview_rev_1.png', createdAt: DateTime(2024, 3, 12), location: '옷장 2단', wearCount: 3),
  ClothingItem(id: 'c02', name: '데님 팬츠', category: ClothingCategory.bottom, color: 'black', season: Season.springFall, material: ClothingMaterial.denim, imagePath: 'assets/images/mock/IMG_4260_preview_rev_1.png', createdAt: DateTime(2025, 6, 1), wearCount: 9),
  ClothingItem(id: 'c03', name: '그래픽 와이드팬츠', category: ClothingCategory.bottom, color: 'khaki', season: Season.springFall, material: ClothingMaterial.denim, imagePath: 'assets/images/mock/IMG_4261_preview_rev_1.png', createdAt: DateTime(2023, 11, 20), wearCount: 4),
  ClothingItem(id: 'c04', name: '트렌치코트', category: ClothingCategory.outer, color: 'brown', season: Season.springFall, material: ClothingMaterial.leather, imagePath: 'assets/images/mock/IMG_4264_preview_rev_1.png', createdAt: DateTime(2024, 9, 5), location: '옷장 1단', wearCount: 2),
  ClothingItem(id: 'c05', name: '스트라이프 블라우스', category: ClothingCategory.top, color: 'burgundy', season: Season.springFall, material: ClothingMaterial.silkSatin, imagePath: 'assets/images/mock/IMG_4267_preview_rev_1.png', createdAt: DateTime(2025, 2, 14), wearCount: 5),
  ClothingItem(id: 'c06', name: '코튼 반바지', category: ClothingCategory.bottom, color: 'sage', season: Season.summer, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4273.PNG', createdAt: DateTime(2026, 1, 8), isIncomplete: true),
  ClothingItem(id: 'c07', name: '리넨 반바지', category: ClothingCategory.bottom, color: 'blue', season: Season.summer, material: ClothingMaterial.linen, imagePath: 'assets/images/mock/IMG_4275.PNG', createdAt: DateTime(2025, 7, 22), wearCount: 6),
  ClothingItem(id: 'c08', name: '슬립 드레스', category: ClothingCategory.onePiece, color: 'black', season: Season.springFall, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4276.PNG', createdAt: DateTime(2024, 12, 30), wearCount: 1),
  ClothingItem(id: 'c09', name: '레더 재킷', category: ClothingCategory.outer, color: 'black', season: Season.springFall, material: ClothingMaterial.leather, imagePath: 'assets/images/mock/IMG_4277.PNG', createdAt: DateTime(2023, 5, 17), location: '옷장 1단', wearCount: 7),
  ClothingItem(id: 'c10', name: '그래픽 반팔티', category: ClothingCategory.top, color: 'white', season: Season.summer, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4257_preview_rev_1.png', createdAt: DateTime(2025, 4, 3), wearCount: 12),
  ClothingItem(id: 'c11', name: '그래픽 맨투맨', category: ClothingCategory.top, color: 'pink', season: Season.springFall, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4262_preview_rev_1.png', createdAt: DateTime(2024, 8, 19), wearCount: 8),
  // category/season 둘 다 null — 옷장 "옷 종류"/"계절" 분류의 미분류 카드 데모용
  // (`docs/history/Decision.md`의 nullable화 결정, 2026-07-19).
  ClothingItem(id: 'c12', name: '플로럴 스커트', color: 'multi', material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4268-removebg-preview.png', createdAt: DateTime(2026, 2, 25), wearCount: 2),
];

final List<Composition> mockCompositions = [
  Composition(
    id: 'comp01',
    name: '데일리 룩',
    createdAt: DateTime(2025, 3, 10),
    season: Season.springFall,
    weather: Weather.clear,
    items: const [
      CompositionItemPlacement(clothingItemId: 'c01', x: 40, y: 40, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c11', x: 60, y: 120, zIndex: 1),
      CompositionItemPlacement(clothingItemId: 'c07', x: 60, y: 260, zIndex: 2),
      CompositionItemPlacement(clothingItemId: 'c03', x: 80, y: 380, zIndex: 3),
    ],
  ),
  Composition(
    id: 'comp02',
    name: '포멀 코디',
    createdAt: DateTime(2026, 1, 20),
    // season 미지정 — 코디 "계절" 분류의 미분류 카드 데모용.
    weather: Weather.rain,
    items: const [
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

// 휴지통 mock — 실제로는 위 세 리스트를 `isDeleted`로 필터링한 집계 뷰가 되어야 하지만
// (Step⑦ 몫), 지금은 이 화면 전용 고정 목록만 채운다.
final List<TrashEntry> mockTrashEntries = [
  const TrashEntry(id: 't1', category: AppCategory.closet, imagePath: '', remainingDays: 12),
  const TrashEntry(id: 't2', category: AppCategory.composition, imagePath: '', remainingDays: 5),
  const TrashEntry(id: 't3', category: AppCategory.styleLog, imagePath: '', remainingDays: 27),
  const TrashEntry(id: 't4', category: AppCategory.closet, imagePath: '', remainingDays: 1),
];
