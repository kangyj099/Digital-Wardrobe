// TODO: 향후 이 폐쇄형 어휘를 JSON 리소스로 외부화할 예정
/// [ClothingItem.category]에 허용되는 값. 머리부터 발끝 착용 순서를 따른다.
enum ClothingCategory {
  hat,
  top,
  outer,
  bottom,
  dress,
  socks,
  shoes,
  bagAccessory;

  String get label => switch (this) {
        ClothingCategory.hat => '모자',
        ClothingCategory.top => '상의',
        ClothingCategory.outer => '아우터',
        ClothingCategory.bottom => '하의',
        ClothingCategory.dress => '원피스',
        ClothingCategory.socks => '양말',
        ClothingCategory.shoes => '신발',
        ClothingCategory.bagAccessory => '가방·액세서리',
      };
}

// TODO: 향후 이 폐쇄형 어휘를 JSON 리소스로 외부화할 예정
/// [ClothingItem.season], [Composition.season]에 허용되는 값.
enum Season {
  springFall,
  summer,
  winter;

  String get label => switch (this) {
        Season.springFall => '봄가을',
        Season.summer => '여름',
        Season.winter => '겨울',
      };
}

// TODO: 향후 이 폐쇄형 어휘를 JSON 리소스로 외부화할 예정
/// [ClothingItem.material]에 허용되는 값 — 지각 기반(perception-based) 폐쇄
/// 어휘(원단을 얼핏 보고 사람이 표현하는 방식)이며, 섬유 조성 분류가 아니다.
/// 분류 결정 근거는 Decision.md 참고.
enum ClothingMaterial {
  cotton,
  spandex,
  denim,
  knit,
  fleece,
  linen,
  modalRayon,
  silkSatin,
  seersucker,
  corduroy,
  velvet,
  padding,
  nylon,
  leather,
  furMoustang,
  canvasFabric,
  suede,
  rubber;

  String get label => switch (this) {
        ClothingMaterial.cotton => '면',
        ClothingMaterial.spandex => '스판',
        ClothingMaterial.denim => '데님',
        ClothingMaterial.knit => '니트',
        ClothingMaterial.fleece => '플리스',
        ClothingMaterial.linen => '리넨',
        ClothingMaterial.modalRayon => '모달·레이온',
        ClothingMaterial.silkSatin => '실크·새틴',
        ClothingMaterial.seersucker => '시어서커',
        ClothingMaterial.corduroy => '코듀로이',
        ClothingMaterial.velvet => '벨벳',
        ClothingMaterial.padding => '패딩',
        ClothingMaterial.nylon => '나일론(바스락)',
        ClothingMaterial.leather => '가죽',
        ClothingMaterial.furMoustang => '퍼·무스탕',
        ClothingMaterial.canvasFabric => '캔버스·패브릭',
        ClothingMaterial.suede => '스웨이드',
        ClothingMaterial.rubber => '고무·러버',
      };
}
