#!/usr/bin/env node
/**
 * Export the built deck to a 16:9 PDF, one slide per page.
 *
 *   node docs/portfolio/export-pdf.mjs [html] [out.pdf]
 *
 * The deck's @media print rules already lay every slide out as a 1920x1080
 * block with a page break after it, so the page size is passed explicitly in
 * pixels — Chrome's own paper presets would letter-crop the slides.
 */
import { chromium } from 'playwright';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const html = resolve(process.argv[2] ?? 'docs/portfolio/portfolio-slides.html');
const out = resolve(process.argv[3] ?? html.replace(/\.html$/, '.pdf'));

if (!existsSync(html)) {
  console.error(`missing deck: ${html}`);
  process.exit(1);
}

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
await page.goto(pathToFileURL(html).href, { waitUntil: 'networkidle' });
await page.emulateMedia({ media: 'print' });
await page.pdf({
  path: out,
  width: '1920px',
  height: '1080px',
  printBackground: true,
  margin: { top: '0', right: '0', bottom: '0', left: '0' },
});
await browser.close();
console.log(`exported ${out}`);
