#!/usr/bin/env node
/**
 * Render every slide of a built deck to a 1920x1080 PNG.
 *
 *   node docs/portfolio/preview.mjs [html] [outDir]
 *
 * Defaults to docs/portfolio/portfolio-slides.html -> docs/portfolio/preview/.
 * Layout must always be judged from these PNGs — reading the CSS hides
 * overlaps, clipping and overflow.
 */
import { chromium } from 'playwright';
import { mkdirSync, rmSync, existsSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { pathToFileURL } from 'node:url';

const html = resolve(process.argv[2] ?? 'docs/portfolio/portfolio-slides.html');
const outDir = resolve(process.argv[3] ?? 'docs/portfolio/preview');

if (!existsSync(html)) {
  console.error(`missing deck: ${html}`);
  process.exit(1);
}
// `--keep` renders several decks into one folder without wiping earlier output.
if (!process.argv.includes('--keep')) rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
await page.goto(pathToFileURL(html).href, { waitUntil: 'networkidle' });

// Freeze entrance animations so screenshots capture the settled layout.
await page.addStyleTag({
  content: `.slide *,.slide *::before,.slide *::after{animation-duration:0s !important;animation-delay:0s !important;transition:none !important;opacity:1 !important;transform:none !important}
            .ind{transform:translateX(-50%) !important}
            .deck-stage{transform:none !important}
            .deck-controls,#editHint{display:none !important}`,
});

const count = await page.locator('.slide').count();
const stem = basename(html).replace(/\.html$/, '');

for (let i = 0; i < count; i++) {
  await page.evaluate((index) => {
    document.querySelectorAll('.slide').forEach((el, j) => el.classList.toggle('active', j === index));
    // Keep the stage unscaled and top-left aligned for a pixel-exact capture.
    const stage = document.querySelector('.deck-stage');
    if (stage) stage.style.transform = 'none';
  }, i);
  await page.waitForTimeout(120);
  const file = `${outDir}/${count > 1 ? `${stem}-${String(i + 1).padStart(2, '0')}` : stem}.png`;
  await page.screenshot({ path: file, clip: { x: 0, y: 0, width: 1920, height: 1080 } });
  console.log(`rendered ${file}`);
}

await browser.close();
