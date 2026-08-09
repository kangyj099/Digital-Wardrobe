"""_slides.template.html의 이미지 토큰을 base64로 치환해 portfolio-slides.html을 만든다.

사용법:  python docs/portfolio/build.py

이미지는 아래 순서로 찾는다. 앞쪽이 있으면 그걸 쓴다.
  1) docs/portfolio/assets/<이름>.png   ← 실제 앱 스크린샷 (출시 후 여기에 넣는다)
  2) 참고자료/... 아래의 목업 PNG        ← 지금 쓰는 것. .gitignore 대상

즉 assets/에 같은 이름으로 파일을 넣기만 하면 목업이 실제 스크린샷으로 교체된다.
템플릿은 건드릴 필요 없다.
"""
import base64
import io
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
ASSETS = os.path.join(HERE, "assets")

# 토큰 -> (assets/ 안에서 찾을 이름, 목업 폴백 경로)
IMAGES = {
    "__IMG_WARDROBE__": (
        "wardrobe-home.png",
        "참고자료/목업/옷장 메인/옷장-메인.png",
    ),
    "__IMG_STYLELOG__": (
        "style-log-detail.png",
        "참고자료/목업/스타일 일지 상세/스타일 일지-상세.png",
    ),
    "__IMG_GLASS__": (
        "frosted-glass-header.png",
        "참고자료/목업/옷장 메인/"
        "옷장-메인-상단 버튼 프로스티드 글래스, 스크롤중엔 갤러리 경계 영역 헤더위치까지 올라오기.png",
    ),
}


def resolve(name, fallback_rel):
    real = os.path.join(ASSETS, name)
    if os.path.exists(real):
        return real, "assets"
    mock = os.path.join(ROOT, fallback_rel)
    if os.path.exists(mock):
        return mock, "목업"
    raise SystemExit("이미지 없음: %s / %s" % (real, mock))


src = io.open(os.path.join(HERE, "_slides.template.html"), encoding="utf-8").read()

for token, (name, fallback) in IMAGES.items():
    path, kind = resolve(name, fallback)
    data = base64.b64encode(open(path, "rb").read()).decode()
    src = src.replace(token, "data:image/png;base64," + data)
    print("  %-18s <- %s (%s)" % (token, os.path.basename(path), kind))

out = os.path.join(HERE, "portfolio-slides.html")
io.open(out, "w", encoding="utf-8").write(src)
print("built %s (%.1f KB)" % (out, len(src.encode("utf-8")) / 1024))
