// TODO: 향후 이 폐쇄형 어휘를 JSON 리소스로 외부화할 예정
/// [ClothingItem.category]에 허용되는 값. 머리부터 발끝 착용 순서를 따른다.
enum ClothingCategory {
  hat,
  onePiece,
  top,
  outer,
  bottom,
  socks,
  shoes,
  bagAccessory;

  String get label => switch (this) {
        ClothingCategory.hat => '모자',
        ClothingCategory.onePiece => '한벌옷',
        ClothingCategory.top => '상의',
        ClothingCategory.outer => '아우터',
        ClothingCategory.bottom => '하의',
        ClothingCategory.socks => '양말',
        ClothingCategory.shoes => '신발',
        ClothingCategory.bagAccessory => '가방·액세서리',
      };
}

// TODO: 향후 이 폐쇄형 어휘를 JSON 리소스로 외부화할 예정
/// 최상단 카테고리 드롭다운(옷장/코디/스타일일지)에서 고를 수 있는 영역. 폐쇄형 어휘라
/// 다른 enum들과 동일하게 raw String 비교 대신 이 타입으로 분기한다.
enum AppCategory {
  closet,
  composition,
  styleLog;

  String get label => switch (this) {
        AppCategory.closet => '옷장',
        AppCategory.composition => '코디',
        AppCategory.styleLog => '스타일일지',
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
/// [ClothingItem.color]에 허용되는 값 — `category`/`season`/`material`과 같은 폐쇄
/// 어휘이며 자유 텍스트가 아니다. 무채색 → 유채색 → 포괄값 순으로 나열한다.
///
/// [multi]는 지배적인 색이 없는 진짜 다색 아이템용이다 — 표면 디자인을 서술하는
/// `hasPattern`/`hasGraphic`과는 다른 축이다(색의 개수 vs. 무늬의 유무).
///
/// 값 집합 확정 근거는 `docs/reference/data/00_DataSchema.md` Open Question #11.
enum ClothingColor {
  white,
  ivory,
  beige,
  gray,
  black,
  brown,
  red,
  orange,
  yellow,
  green,
  blue,
  navy,
  purple,
  pink,
  khaki,
  multi;

  String get label => switch (this) {
        ClothingColor.white => '화이트',
        ClothingColor.ivory => '아이보리',
        ClothingColor.beige => '베이지',
        ClothingColor.gray => '그레이',
        ClothingColor.black => '블랙',
        ClothingColor.brown => '브라운',
        ClothingColor.red => '레드',
        ClothingColor.orange => '오렌지',
        ClothingColor.yellow => '옐로우',
        ClothingColor.green => '그린',
        ClothingColor.blue => '블루',
        ClothingColor.navy => '네이비',
        ClothingColor.purple => '퍼플',
        ClothingColor.pink => '핑크',
        ClothingColor.khaki => '카키',
        ClothingColor.multi => '멀티컬러',
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

// TODO: 향후 이 폐쇄형 어휘를 JSON 리소스로 외부화할 예정
/// [User.authProvider]에 허용되는 값 — 계정 연동에 쓴 소셜 제공자.
///
/// **값 집합이 잠정이다**: 후보 4개로 시작하되 최종 확정 전에 줄어들 수 있다
/// (`docs/reference/data/00_DataSchema.md` Open Question #15). 이메일·비밀번호 방식은
/// 후보에 없다. 폐쇄 어휘라 raw String 대신 이 타입으로 다룬다.
enum AuthProvider {
  google,
  naver,
  kakao,
  github;

  String get label => switch (this) {
        AuthProvider.google => '구글',
        AuthProvider.naver => '네이버',
        AuthProvider.kakao => '카카오',
        AuthProvider.github => '깃허브',
      };
}

// TODO: 향후 이 폐쇄형 어휘를 JSON 리소스로 외부화할 예정
/// [Composition.weather]에 허용되는 값.
enum Weather {
  clear,
  rain,
  snow;

  String get label => switch (this) {
        Weather.clear => '맑음',
        Weather.rain => '비',
        Weather.snow => '눈',
      };
}

// TODO: 향후 이 폐쇄형 어휘를 JSON 리소스로 외부화할 예정
/// [Composition.backgroundColor]에 허용되는 값 — 코디 편집기 아트보드 배경색 스와치의
/// 닫힌 값 집합(MVP는 흰색/밝은회색/어두운회색/검정 4단, `02_코디 (가상 조합).md` §11.1).
/// `Color` 매핑(`.value` getter)은 `package:flutter/material.dart` 의존이라 여기(순수
/// Dart 모델 레이어)에 두지 않고 `lib/widgets/interactive_artboard/
/// artboard_background_color.dart`의 extension으로 분리돼 있다 — `lib/models/`가 Flutter
/// UI 레이어에 의존하지 않게 하기 위함(Audit 지적, 2026-08-07 레이어 위반 해소).
enum ArtboardBackgroundColor {
  white,
  lightGray,
  darkGray,
  black;

  String get label => switch (this) {
        ArtboardBackgroundColor.white => '흰색',
        ArtboardBackgroundColor.lightGray => '밝은 회색',
        ArtboardBackgroundColor.darkGray => '어두운 회색',
        ArtboardBackgroundColor.black => '검정',
      };
}
