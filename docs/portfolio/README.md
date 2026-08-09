# 포트폴리오 덱 (HTML)

IT 기업 지원용 포트폴리오 8슬라이드. 스펙은 [`../figma-slide-prompt-final.md`](../figma-slide-prompt-final.md),
디자인 토큰은 [`../design-tokens-for-figma-handoff.md`](../design-tokens-for-figma-handoff.md)를 따른다.

## 파일

| 파일 | 역할 |
|---|---|
| `_slides.template.html` | **소스.** 여기만 수정한다. 이미지는 `__IMG_*__` 토큰으로 들어있다 |
| `build.py` | 토큰을 base64로 치환해 `portfolio-slides.html` 생성 |
| `portfolio-slides.html` | **배포용 산출물.** 자체 완결형(이미지 인라인), 브라우저로 바로 열림 |
| `preview.py` | 슬라이드 8장을 개별 PNG로 렌더 — 레이아웃 검증용 |
| `export-pdf.mjs` | A4 가로 8페이지 PDF 생성 |
| `assets/` | 실제 앱 스크린샷을 넣는 곳 (지금은 비어 있고 목업을 쓴다) |

원본 스크린샷은 `.gitignore`된 `참고자료/` 아래에 있어서, 배포용 HTML은 이미지를
base64로 인라인해 자체 완결형으로 만든다. 그래서 산출물 HTML도 함께 커밋한다.

## 빌드

```bash
python docs/portfolio/build.py          # 소스 → portfolio-slides.html
python docs/portfolio/preview.py        # → .preview/s1~s8.png (레이아웃 확인)
node   docs/portfolio/export-pdf.mjs    # → portfolio-slides.pdf (A4 가로 8p)
```

## 스크린샷 교체 (앱 출시 후)

지금 쓰는 이미지는 **목업**이다. 실제 앱 스크린샷이 나오면 `assets/`에 아래 이름으로
넣기만 하면 된다 — `build.py`가 `assets/`를 먼저 보고, 없을 때만 목업으로 폴백한다.
템플릿은 건드릴 필요 없다.

| 파일명 | 쓰이는 곳 |
|---|---|
| `assets/wardrobe-home.png` | S1 표지 왼쪽 기기, S2 우측 목업 |
| `assets/style-log-detail.png` | S1 표지 오른쪽 기기 |
| `assets/frosted-glass-header.png` | S3 타일 1의 근거 캡처 (글래스 헤더가 보여야 함) |

세로로 긴 기기 화면 비율(9:19.5 안팎)로 찍으면 지금 레이아웃에 그대로 맞는다.
교체 후 `build.py` → `preview.py` 순으로 돌려 잘림이 없는지 확인한다.

## 규격

- 슬라이드: A4 가로 297×210mm, 덱 전체 가로 통일
- 본문 영역: `--content-h: 552px` = inner(706) − 헤더(102) − 인디케이터 여유(52)
  - 슬라이드 본문 블록 높이는 이 변수를 쓴다. 안 지키면 하단 인디케이터와 겹친다
- 좌표계: `.inner` 1035×706px를 슬라이드 중앙에 배치. mm 반올림과 분리하려는 의도

## 브라우저에서 직접 인쇄할 때

`export-pdf.mjs` 대신 Ctrl+P를 쓴다면 **용지 A4 / 방향 가로 / 여백 없음 / 배경 그래픽 켜기**를
직접 골라야 한다. Chrome의 `--print-to-pdf` CLI는 CSS `@page { size: A4 landscape }`를
무시하고 US Letter 세로로 찍어 내용을 잘라먹는다 — `export-pdf.mjs`가 DevTools Protocol로
용지 크기를 직접 넘기는 이유다.

## 플레이스홀더

확정되지 않은 값은 `[PLACEHOLDER: 항목명]` 형태로, 점선 테두리 + 회색 텍스트 + `TBD` 뱃지로
표시했다. `.ph`(인라인) / `.ph-box`(박스) 두 가지 클래스를 쓴다.
실제 값을 넣을 때는 `_slides.template.html`에서 `PLACEHOLDER:`로 검색하면 전부 찾을 수 있다.
