"""portfolio-slides.html의 각 슬라이드를 개별 PNG로 렌더한다. 레이아웃 검증용.

사용법:  python docs/portfolio/preview.py [출력폴더]
         (기본 출력: docs/portfolio/.preview/)

슬라이드 하나만 남기고 나머지를 CSS로 숨긴 임시 HTML을 만들어 1123x794 뷰포트로 찍는다.
겹침 / 잘림 / 슬라이드 밖으로 삐져나간 요소를 눈으로 확인하는 용도다.
PDF로 뽑기 전에 한 번 돌려보면 된다.
"""
import io
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
INPUT = os.path.join(HERE, "portfolio-slides.html")
OUT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, ".preview")

SLIDE_COUNT = 8
VIEWPORT = "1123,794"  # A4 가로 @96dpi

CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "/usr/bin/google-chrome",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
]

chrome = next((p for p in CHROME_CANDIDATES if os.path.exists(p)), None)
if not chrome:
    raise SystemExit("Chrome/Edge를 찾지 못했습니다.")
if not os.path.exists(INPUT):
    raise SystemExit("%s 없음. 먼저 python docs/portfolio/build.py 실행." % INPUT)

os.makedirs(OUT, exist_ok=True)
tmp = os.path.join(OUT, "_tmp")
os.makedirs(tmp, exist_ok=True)

src = io.open(INPUT, encoding="utf-8").read()

for i in range(1, SLIDE_COUNT + 1):
    hide = ("<style>body{background:#fff}.deck{padding:0;gap:0}"
            ".slide{box-shadow:none}.slide:not(#s%d){display:none}</style>" % i)
    page = os.path.join(tmp, "s%d.html" % i)
    io.open(page, "w", encoding="utf-8").write(src + hide)

    shot = os.path.join(OUT, "s%d.png" % i)
    subprocess.run(
        [chrome, "--headless", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1", "--window-size=" + VIEWPORT,
         "--screenshot=" + shot, page],
        capture_output=True, timeout=120,
    )
    size = os.path.getsize(shot) if os.path.exists(shot) else 0
    print("  s%d  %s  %.0f KB" % (i, "ok" if size else "FAILED", size / 1024))

shutil.rmtree(tmp, ignore_errors=True)
print("rendered %d slides -> %s" % (SLIDE_COUNT, OUT))
