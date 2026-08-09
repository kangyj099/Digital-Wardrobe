# 디자인 토큰 — Figma 슬라이드 제작용 레퍼런스

두 개의 HTML 하이파이 목업(`옷장_메인.html`, `스타일_일지_상세.html`)에서 실제 CSS 값을 추출했습니다.
아래 내용을 그대로 Figma 세션 프롬프트에 붙여넣으면 됩니다.

---

## 1. 컬러 팔레트

```
bg / surface       #F7F6F3   (기본 배경, 거의 흰색에 가까운 웜톤)
onbg                #2B2D30   (기본 텍스트, 잉크블랙)
surfaceSoft         rgba(43,45,48,0.06)   (카드 hover/구분선 등 아주 옅은 틴트)

primary             #394550   (버튼/포인트, 딥 슬레이트블루)
onPrimary           #F7F6F3
primaryLight        #7C93A6   (보조 텍스트/링크 톤)

accent               #C5D3C7   (세이지그린 포인트)
onAccent             #2B2D30

error                #A34B50   (테라코타 레드)
warning              #B98A3D   (머스타드/골드 — "미완성" 배지 등에 사용)

배경 그라디언트(페이지 전체):
  linear-gradient(180deg, #EEEAE1 0%, #E6E0D3 100%)

옷 카테고리 스와치(스트라이프용):
  #DDD4C8, #CBC0B0, #EDE9E1, #B3A99A
```

## 2. 헤더 / 프로스티드 글래스 토큰 (핵심)

```
headerBg      rgba(247,246,243,0.38)
headerBorder  rgba(247,246,243,0.20)
shadow        rgba(43,45,48,0.06)

backdrop-filter: blur(3px) saturate(180%);
-webkit-backdrop-filter: blur(3px) saturate(180%);
```
- 하단 고정 바(뒤로가기 버튼 등)는 `saturate` 없이 `blur(3px)`만 사용 — 헤더보다 살짝 더 무겁게.
- 그림자는 항상 두 겹: `0 2px 10px var(--shadow), inset 0 1px 0 rgba(255,255,255,0.16)` (안쪽 하이라이트로 유리 질감 강조)

## 3. Radius

```
알약형 버튼/헤더 pill      19px
드롭다운/모달 카드          16px
소형 아이콘 버튼(밀도전환)  8px
원형 버튼(뒤로가기/토글/+)  50% (46~56px 정사각형)
초소형 배지                5px
```

## 4. Shadow 스케일

```
기본(헤더/버튼)      0 2px 10px var(--shadow), inset 0 1px 0 rgba(255,255,255,0.16)
드롭다운/팝오버       0 10px 28px var(--shadow)
플로팅 + 버튼         0 6px 18px var(--shadow)
카드/기타 강조        0 8px 22px var(--shadow)
```

## 5. 타이포그래피

```
1순위: 'Pretendard'
2순위: 'Noto Sans KR'
폴백:  sans-serif
```
- 본문 대부분은 `Noto Sans KR` 단독 지정, 페이지 최상단 컨테이너에서만 `'Pretendard','Noto Sans KR',sans-serif`로 오버라이드하는 구조 — 즉 **Pretendard가 우선 브랜드 폰트, Noto Sans KR이 백업**.
- 라벨류 폰트 크기: 13~15.5px, weight 600~800 위주 (가는 폰트 거의 없음 — 전반적으로 살짝 굵게)

## 6. 간격 / 배치 원칙

```
페이지 세로 패딩: 48px 24px 80px
플로팅 버튼 위치: 좌우 16~18px, 하단 26px 고정
헤더 버튼 zIndex: 32~33 (컨텐츠보다 항상 위)
버튼 간 gap: 6~10px
```

## 7. 시그니처 요소 (텍스트로 반드시 전달할 것)

- **"웹을 감싼 앱"이 아니라 진짜 앱처럼 보이게 하는 것이 핵심 원칙.** 플랫한 문서형 디자인이 아니라 프로스티드 글래스 + 플로팅 버튼 조합으로 앱다운 입체감을 낸다.
- 헤더/툴바는 스크롤 시 콘텐츠 경계까지 따라 올라오는 고정형 프로스티드 글래스 (아래 첨부 스크린샷 참고).
- 원형 플로팅 버튼(뒤로가기, +, 토글)은 모두 지름 38~56px, 항상 그림자 2겹 + 반투명 배경.
- 색감은 전체적으로 웜그레이/뮤트 어스톤 — 채도 높은 원색은 warning(#B98A3D)과 error(#A34B50) 정도로 제한적으로만 사용.

---

## Figma 프롬프트에 붙여넣을 요약 (그대로 복사)

```
[디자인 시스템 레퍼런스 — 실제 앱 목업에서 추출한 정확한 토큰]

컬러: bg/surface #F7F6F3, onbg #2B2D30, primary #394550, accent #C5D3C7,
      warning #B98A3D, error #A34B50, 배경 그라디언트 #EEEAE1→#E6E0D3(180deg)

글래스: background rgba(247,246,243,0.38), border rgba(247,246,243,0.20),
        backdrop-filter: blur(3px) saturate(180%)

Radius: pill 19px / 카드 16px / 아이콘버튼 8px / 원형버튼 50%
Shadow: 0 2px 10px rgba(43,45,48,0.06), inset 0 1px 0 rgba(255,255,255,0.16)
폰트: 'Pretendard', 'Noto Sans KR', sans-serif (weight 600~800 위주)

적용 원칙: "웹을 감싼 앱"이 아닌 "진짜 앱"처럼 보이는 게 핵심.
프로스티드 글래스 + 플로팅 버튼 모티프를 슬라이드 하단 파트 인디케이터
(pill 형태, 반투명 배경)에도 그대로 가져와서 앱 자체 디자인 언어와
포트폴리오 슬라이드 디자인 언어를 일관되게 연결해줘.

```

## 참고 레퍼런스 앰 이미지

@"참고자료/목업/스타일 일지 상세/스타일 일지-상세.png"

@"참고자료/목업/옷장 메인/옷장-메인-상단 버튼 프로스티드 글래스, 스크롤중엔 갤러리 경계 영역 헤더위치까지 올라오기.png"

@"참고자료/목업/옷장 메인/옷장-메인.png"