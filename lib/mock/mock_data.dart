import '../models/clothing_item.dart';
import '../models/composition.dart';
import '../models/enums.dart';
import '../models/style_log.dart';

final List<ClothingItem> mockClothingItems = [
  ClothingItem(id: 'c01', name: '플로럴 원피스', category: ClothingCategory.onePiece, color: 'pink', season: Season.springFall, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4259_preview_rev_1.png', createdAt: DateTime(2024, 3, 12), location: '옷장 2단', wearCount: 3),
  ClothingItem(id: 'c02', name: '데님 팬츠', category: ClothingCategory.bottom, color: 'black', season: Season.springFall, material: ClothingMaterial.denim, imagePath: 'assets/images/mock/IMG_4260_preview_rev_1.png', createdAt: DateTime(2025, 6, 1), wearCount: 9),
  ClothingItem(id: 'c03', name: '그래픽 와이드팬츠', category: ClothingCategory.bottom, color: 'khaki', season: Season.springFall, material: ClothingMaterial.denim, imagePath: 'assets/images/mock/IMG_4261_preview_rev_1.png', createdAt: DateTime(2023, 11, 20), wearCount: 4),
  ClothingItem(id: 'c04', name: '트렌치코트', category: ClothingCategory.outer, color: 'brown', season: Season.springFall, material: ClothingMaterial.leather, imagePath: 'assets/images/mock/IMG_4264_preview_rev_1.png', createdAt: DateTime(2024, 9, 5), location: '옷장 1단', wearCount: 2),
  ClothingItem(id: 'c05', name: '스트라이프 블라우스', category: ClothingCategory.top, color: 'burgundy', season: Season.springFall, material: ClothingMaterial.silkSatin, imagePath: 'assets/images/mock/IMG_4267_preview_rev_1.png', createdAt: DateTime(2025, 2, 14), wearCount: 5),
  ClothingItem(id: 'c06', name: '코튼 반바지', category: ClothingCategory.bottom, color: 'sage', season: Season.summer, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4273.PNG', createdAt: DateTime(2026, 1, 8), isIncomplete: true),
  ClothingItem(id: 'c07', name: '리넨 반바지', category: ClothingCategory.bottom, color: 'blue', season: Season.summer, material: ClothingMaterial.linen, imagePath: 'assets/images/mock/IMG_4275.PNG', createdAt: DateTime(2025, 7, 22), wearCount: 6, isDeleted: true, deletedAt: DateTime.now().subtract(const Duration(days: 3))),
  ClothingItem(id: 'c08', name: '슬립 드레스', category: ClothingCategory.onePiece, color: 'black', season: Season.springFall, material: ClothingMaterial.cotton, imagePath: 'assets/images/mock/IMG_4276.PNG', createdAt: DateTime(2024, 12, 30), wearCount: 1, isDeleted: true, deletedAt: DateTime.now().subtract(const Duration(days: 20))),
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
    // x/y는 캔버스 대비 정규화된(0.0~1.0) 아이템 중심 좌표(`CompositionItemPlacement` doc
    // 참고) — 4개를 겹치지 않는 2x2 산포로 배치한 순수 데모값(실사용자 데이터 아님).
    items: const [
      CompositionItemPlacement(clothingItemId: 'c01', x: 0.3, y: 0.25, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c11', x: 0.7, y: 0.25, zIndex: 1),
      CompositionItemPlacement(clothingItemId: 'c07', x: 0.3, y: 0.65, zIndex: 2),
      CompositionItemPlacement(clothingItemId: 'c03', x: 0.7, y: 0.65, zIndex: 3),
    ],
  ),
  Composition(
    id: 'comp02',
    name: '포멀 코디',
    createdAt: DateTime(2026, 1, 20),
    // season 미지정 — 코디 "계절" 분류의 미분류 카드 데모용.
    weather: Weather.rain,
    items: const [
      CompositionItemPlacement(clothingItemId: 'c04', x: 0.3, y: 0.35, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c05', x: 0.65, y: 0.6, zIndex: 1),
    ],
    isDeleted: true,
    deletedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  // comp02가 isDeleted:true가 되며 잃어버린 "season 미지정 + weather:rain" 비삭제
  // 데모 역할을 이어받는다(Review P1, Task 3 addendum). c04/c05는 comp02와 동일 재사용 —
  // 별도 asset 없이 가장 저위험.
  Composition(
    id: 'comp03',
    name: '레인 코디',
    createdAt: DateTime(2026, 2, 2),
    // season 미지정 — 코디 "계절" 분류의 미분류 카드 데모용.
    weather: Weather.rain,
    items: const [
      CompositionItemPlacement(clothingItemId: 'c04', x: 0.3, y: 0.35, zIndex: 0),
      CompositionItemPlacement(clothingItemId: 'c05', x: 0.65, y: 0.6, zIndex: 1),
    ],
  ),
];

final List<StyleLog> mockStyleLogs = [
  StyleLog(
    id: 'log01',
    coverImagePath: 'assets/images/mock/IMG_4259_preview_rev_1.png',
    wornDate: DateTime(2026, 1, 5),
    linkedCompositionId: 'comp01',
    // c11(그래픽 맨투맨)/c07(리넨 반바지) — 각각 이전 additionalImagePaths 경로와
    // imagePath가 정확히 일치하던 옷의 ID로 그대로 치환(데이터 동일성 유지).
    wornItemIds: const ['c11', 'c07'],
    // 연결된 comp01과 동일한 season/weather로 맞춰 일관성 유지.
    season: Season.springFall,
    weather: Weather.clear,
    location: '집',
  ),
  StyleLog(
    id: 'log02',
    coverImagePath: 'assets/images/mock/IMG_4264_preview_rev_1.png',
    wornDate: DateTime(2026, 1, 10),
    linkedCompositionId: 'comp02',
    // log01과 다른 season/weather 조합 — 필터 기능 테스트용 다양성 확보.
    season: Season.winter,
    weather: Weather.snow,
    location: '회사',
  ),
];
