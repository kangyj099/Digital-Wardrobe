#!/usr/bin/env node
/**
 * Port the deck into a native .pptx — real PowerPoint shapes and editable text,
 * not screenshots.
 *
 *   node docs/portfolio/export-pptx.mjs [html] [out.pptx]
 *
 * How it works: the deck is opened in a headless browser, and every element of
 * every slide is read back with its *computed* geometry and style. Those are
 * translated into PowerPoint primitives — filled rectangles / rounded
 * rectangles / ellipses for panels, chips and rules, text frames (with per-run
 * bold and colour) for copy, pictures for the app mockups, and embedded SVG for
 * the two diagram slides so they stay vector and can be converted to shapes
 * inside PowerPoint.
 *
 * The stage is 1920x1080 px and the slide is 13.333x7.5 in, so 1px = 1/144 in
 * and 1px = 0.5pt exactly; every measurement is a straight scale.
 */
import { chromium } from 'playwright';
import PptxGenJS from 'pptxgenjs';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const html = resolve(process.argv[2] ?? 'docs/portfolio/portfolio-slides.html');
const out = resolve(process.argv[3] ?? html.replace(/\.html$/, '.pptx'));

if (!existsSync(html)) {
  console.error(`missing deck: ${html}`);
  process.exit(1);
}

const W = 1920, H = 1080;
const PX2IN = 13.333 / W;
const PX2PT = 0.5;
const inch = (px) => +(px * PX2IN).toFixed(4);
const pt = (px) => +(px * PX2PT).toFixed(2);

/* ============================================================
   1. READ THE RENDERED DECK
   ============================================================ */
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
await page.goto(pathToFileURL(html).href, { waitUntil: 'networkidle' });
await page.addStyleTag({
  content: `.slide *,.slide *::before,.slide *::after{animation:none !important;transition:none !important;opacity:1 !important;transform:none !important}
            .ind{transform:translateX(-50%) !important}
            .deck-stage{transform:none !important}
            .deck-controls,#editHint{display:none !important}`,
});

const slideCount = await page.locator('.slide').count();
const deck = [];

for (let i = 0; i < slideCount; i++) {
  const slide = await page.evaluate((index) => {
    const slides = document.querySelectorAll('.slide');
    slides.forEach((el, j) => el.classList.toggle('active', j === index));
    const stage = document.querySelector('.deck-stage');
    if (stage) stage.style.transform = 'none';
    const root = slides[index];

    /* ---- helpers ---- */
    const rgba = (v) => {
      const m = /rgba?\(([^)]+)\)/.exec(v || '');
      if (!m) return null;
      const [r, g, b, a = '1'] = m[1].split(',').map((s) => s.trim());
      return { hex: [r, g, b].map((n) => (+n).toString(16).padStart(2, '0')).join('').toUpperCase(), a: +a };
    };
    const px = (v) => parseFloat(v) || 0;
    const firstGradientColor = (bg) => {
      const m = /rgba?\([^)]+\)|#[0-9a-f]{3,8}/gi.exec(bg);
      return m ? m[0] : null;
    };

    const out = [];
    let order = 0;

    const pushShape = (s) => out.push({ kind: 'shape', z: s.z ?? 0, order: order++, ...s });
    const pushText = (t) => out.push({ kind: 'text', z: t.z ?? 0, order: order++, ...t });

    /* ---- text runs: keeps bold / colour changes inside one paragraph ---- */
    const runsOf = (el, directOnly = false) => {
      const runs = [];
      const visit = (node, style) => {
        if (directOnly && node.nodeType === Node.ELEMENT_NODE && node.tagName !== 'BR') return;
        if (node.nodeType === Node.TEXT_NODE) {
          const t = node.textContent.replace(/\s+/g, ' ');
          if (t.trim()) runs.push({ text: t, ...style });
          return;
        }
        if (node.nodeType !== Node.ELEMENT_NODE) return;
        if (node.tagName === 'BR') { runs.push({ text: '', br: true }); return; }
        const cs = getComputedStyle(node);
        const c = rgba(cs.color);
        [...node.childNodes].forEach((n) =>
          visit(n, { bold: +cs.fontWeight >= 700, color: c ? c.hex : style.color, size: parseFloat(cs.fontSize) }),
        );
      };
      const cs = getComputedStyle(el);
      const c = rgba(cs.color);
      [...el.childNodes].forEach((n) =>
        visit(n, { bold: +cs.fontWeight >= 700, color: c ? c.hex : '2B2D30', size: parseFloat(cs.fontSize) }),
      );
      return runs;
    };

    const MERGEABLE = ['B', 'EM', 'I', 'SPAN', 'SMALL', 'BR', 'S', 'CODE', 'STRONG'];
    const hasDirectText = (el) =>
      [...el.childNodes].some((n) => n.nodeType === Node.TEXT_NODE && n.textContent.trim());

    /* A paragraph may absorb its inline children (<b>, highlight <span>) into one
       text frame. Anything laid out as its own box — a flex item, an
       inline-block chip, a block child — must stay a separate object instead. */
    const absorbsChildren = (el) => {
      const cs = getComputedStyle(el);
      if (cs.display.includes('flex') || cs.display.includes('grid')) return false;
      return [...el.children].every(
        (c) => MERGEABLE.includes(c.tagName) && getComputedStyle(c).display === 'inline',
      );
    };

    /* ---- pseudo elements carry rules, dashes and bullets ---- */
    const pseudo = (el, which) => {
      const cs = getComputedStyle(el, which);
      const content = cs.content;
      if (content === 'none' || cs.display === 'none') return null;
      const w = px(cs.width), h = px(cs.height);
      const bg = rgba(cs.backgroundColor);
      const bt = px(cs.borderTopWidth);
      const text = /^"(.*)"$/.exec(content);
      return { text: text ? text[1] : null, w, h, bg, bt, borderColor: rgba(cs.borderTopColor), cs };
    };

    /* the line boxes of an element's own text, ignoring its block children —
       this is where the text actually sits once a ::before dash or a block
       sibling has pushed it along */
    const directTextRect = (el) => {
      const range = document.createRange();
      let box = null;
      for (const n of el.childNodes) {
        if (n.nodeType !== Node.TEXT_NODE || !n.textContent.trim()) continue;
        range.selectNodeContents(n);
        for (const r of range.getClientRects()) {
          if (r.width <= 0 || r.height <= 0) continue;
          box = box
            ? { l: Math.min(box.l, r.left), t: Math.min(box.t, r.top), r: Math.max(box.r, r.right), b: Math.max(box.b, r.bottom) }
            : { l: r.left, t: r.top, r: r.right, b: r.bottom };
        }
      }
      return box;
    };

    const walk = (el, parentZ = 0) => {
      const cs = getComputedStyle(el);
      if (cs.display === 'none' || cs.visibility === 'hidden') return;
      const r = el.getBoundingClientRect();
      // A wrapper whose children are all absolutely positioned collapses to zero
      // height — it paints nothing, but its children still have to be walked.
      if (r.width <= 0 || r.height <= 0) {
        [...el.children].forEach((c) => walk(c, parentZ));
        return;
      }
      // `z-index: auto` must inherit, or a picture sorts below the panel it sits on
      const z = cs.zIndex === 'auto' ? parentZ : +cs.zIndex || parentZ;

      /* background: solid, translucent, or the closest solid to a gradient */
      const bg = rgba(cs.backgroundColor);
      const grad = cs.backgroundImage && cs.backgroundImage.includes('gradient')
        ? rgba(firstGradientColor(cs.backgroundImage))
        : null;
      const radius = px(cs.borderTopLeftRadius);
      const isCircle = cs.borderTopLeftRadius.includes('%') || radius >= Math.min(r.width, r.height) / 2;

      if ((bg && bg.a > 0.03) || (grad && grad.a > 0.03)) {
        const fill = bg && bg.a > 0.03 ? bg : grad;
        pushShape({
          type: isCircle ? 'ellipse' : radius > 0.5 ? 'roundRect' : 'rect',
          x: r.left, y: r.top, w: r.width, h: r.height,
          fill: fill.hex, alpha: fill.a, radius, z,
        });
      }

      /* borders: each side may exist on its own (rails, hairlines, dashed chips) */
      const sides = ['Top', 'Right', 'Bottom', 'Left'].map((s) => ({
        s,
        w: px(cs[`border${s}Width`]),
        c: rgba(cs[`border${s}Color`]),
        style: cs[`border${s}Style`],
      })).filter((b) => b.w > 0 && b.c && b.c.a > 0.03 && b.style !== 'none');

      if (sides.length === 4 && sides.every((b) => b.w === sides[0].w && b.c.hex === sides[0].c.hex)) {
        pushShape({
          type: isCircle ? 'ellipse' : radius > 0.5 ? 'roundRect' : 'rect',
          x: r.left, y: r.top, w: r.width, h: r.height,
          line: sides[0].c.hex, lineAlpha: sides[0].c.a, lineW: sides[0].w,
          dash: sides[0].style === 'dashed' ? 'dash' : sides[0].style === 'dotted' ? 'sysDot' : 'solid',
          radius, z,
        });
      } else {
        for (const b of sides) {
          const box = { x: r.left, y: r.top, w: r.width, h: r.height };
          if (b.s === 'Top') box.h = b.w;
          if (b.s === 'Bottom') { box.y = r.bottom - b.w; box.h = b.w; }
          if (b.s === 'Left') box.w = b.w;
          if (b.s === 'Right') { box.x = r.right - b.w; box.w = b.w; }
          pushShape({ type: 'rect', ...box, fill: b.c.hex, alpha: b.c.a, z });
        }
      }

      /* pseudo elements */
      for (const which of ['::before', '::after']) {
        const p = pseudo(el, which);
        if (!p) continue;
        const inner = { x: r.left + px(cs.paddingLeft), y: r.top + r.height / 2 };
        if (p.bg && p.bg.a > 0.03 && p.w > 0 && p.h > 0) {
          pushShape({
            type: getComputedStyle(el, which).borderRadius.includes('%') ? 'ellipse' : 'rect',
            x: which === '::before' ? inner.x : r.right - p.w,
            y: inner.y - p.h / 2, w: p.w, h: p.h,
            fill: p.bg.hex, alpha: p.bg.a, z,
          });
        } else if (p.bt > 0 && p.borderColor && p.borderColor.a > 0.03 && p.w > 0) {
          pushShape({
            type: 'rect',
            x: which === '::before' ? inner.x : r.right - p.w,
            y: inner.y - p.bt / 2, w: p.w, h: Math.max(p.bt, 1),
            fill: p.borderColor.hex, alpha: p.borderColor.a,
            dash: p.cs.borderTopStyle === 'dashed' ? 'dash' : 'solid', z,
          });
        }
      }

      /* media */
      if (el.tagName === 'IMG') {
        pushShape({ type: 'image', x: r.left, y: r.top, w: r.width, h: r.height, src: el.src, z });
        return;
      }
      if (el.tagName === 'svg') {
        const clone = el.cloneNode(true);
        clone.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
        clone.removeAttribute('class');
        pushShape({
          type: 'svg', x: r.left, y: r.top, w: r.width, h: r.height, z,
          svg: new XMLSerializer().serializeToString(clone),
        });
        return;
      }

      /* text */
      const merges = absorbsChildren(el);
      if ((merges && el.textContent.trim()) || hasDirectText(el)) {
        /* inline highlights (the sage marker behind a phrase) are painted as
           rects taken from the child's own line boxes, then the text is kept
           in one frame so the wording stays editable as a sentence */
        if (merges) {
          for (const c of el.children) {
            const ccs = getComputedStyle(c);
            const cbg = rgba(ccs.backgroundColor);
            const cgrad = ccs.backgroundImage.includes('gradient') ? rgba(firstGradientColor(ccs.backgroundImage)) : null;
            const paint = cbg && cbg.a > 0.03 ? cbg : cgrad && cgrad.a > 0.03 ? cgrad : null;
            if (!paint) continue;
            for (const cr of c.getClientRects()) {
              pushShape({
                type: 'rect', x: cr.left, y: cr.top + cr.height * 0.62,
                w: cr.width, h: cr.height * 0.3, fill: paint.hex, alpha: paint.a, z: z - 1,
              });
            }
          }
        }
        const runs = merges ? runsOf(el) : runsOf(el, true);
        if (runs.length) {
          const pad = {
            l: px(cs.paddingLeft), r: px(cs.paddingRight),
            t: px(cs.paddingTop), b: px(cs.paddingBottom),
          };
          const line = parseFloat(cs.lineHeight) || parseFloat(cs.fontSize) * 1.35;
          const own = merges ? null : directTextRect(el);
          const frame = own
            ? { x: own.l, y: own.t, w: own.r - own.l, h: Math.max(own.b - own.t, line) }
            : {
                x: r.left + pad.l, y: r.top + pad.t,
                w: Math.max(r.width - pad.l - pad.r, 8),
                h: Math.max(r.height - pad.t - pad.b, 8),
              };
          pushText({
            ...frame,
            // PowerPoint sets Korean slightly wider than the browser; a little
            // slack plus autofit keeps one-line labels on one line
            // slack for font substitution — short chips need an absolute floor,
            // 6% of a 33px pill is 2px and PowerPoint wraps it onto two lines
            w: frame.w + Math.min(Math.max(frame.w * 0.06, 12), 26),
            runs,
            size: parseFloat(cs.fontSize),
            bold: +cs.fontWeight >= 700,
            color: (rgba(cs.color) || { hex: '2B2D30' }).hex,
            align: cs.textAlign === 'right' ? 'right' : cs.textAlign === 'center' ? 'center' : 'left',
            valign: cs.display.includes('flex') && cs.alignItems === 'center' ? 'middle' : 'top',
            lineHeight: parseFloat(cs.lineHeight) || parseFloat(cs.fontSize) * 1.3,
            spacing: parseFloat(cs.letterSpacing) || 0,
            z,
          });
          if (merges) return; // the inline children are already inside the runs
        }
      }

      [...el.children].forEach((c) => walk(c, z));
    };

    [...root.children].forEach((c) => walk(c, 0));

    const cs = getComputedStyle(root);
    const grad = /rgba?\([^)]+\)|#[0-9a-f]{3,8}/gi;
    const stops = (cs.backgroundImage.match(grad) || []).map((c) => rgba(c)).filter(Boolean);
    return {
      background: stops.length >= 2
        ? { from: stops[0].hex, to: stops[stops.length - 1].hex }
        : { from: (rgba(cs.backgroundColor) || { hex: 'F7F6F3' }).hex, to: (rgba(cs.backgroundColor) || { hex: 'F7F6F3' }).hex },
      items: out.sort((a, b) => a.z - b.z || a.order - b.order),
    };
  }, i);

  deck.push(slide);
  const tally = slide.items.reduce((m, o) => {
    const k = o.kind === 'text' ? 'text' : o.type;
    m[k] = (m[k] || 0) + 1;
    return m;
  }, {});
  console.log(`slide ${i + 1}/${slideCount}: ${slide.items.length} objects`, tally);
}

/* ------------------------------------------------------------
   1b. Raster fallbacks for the diagram SVGs.
   PowerPoint stores an SVG picture as <svgBlip> plus a raster blip; without a
   real raster the file is corrupt in every version that cannot read SVG.
   Each diagram is shot on its own, at 3x, with everything else hidden.
   ------------------------------------------------------------ */
const rasters = new Map(); // svg source -> base64 png
const hiRes = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 3 });
await hiRes.goto(pathToFileURL(html).href, { waitUntil: 'networkidle' });
await hiRes.addStyleTag({
  content: `.slide *,.slide *::before,.slide *::after{animation:none !important;transition:none !important;opacity:1 !important;transform:none !important}
            .deck-stage{transform:none !important}
            .deck-controls,#editHint{display:none !important}`,
});

for (let i = 0; i < deck.length; i++) {
  const svgs = deck[i].items.filter((o) => o.type === 'svg');
  if (!svgs.length) continue;
  for (let k = 0; k < svgs.length; k++) {
    const rect = await hiRes.evaluate(
      ({ index, nth }) => {
        const slides = document.querySelectorAll('.slide');
        slides.forEach((el, j) => el.classList.toggle('active', j === index));
        const stage = document.querySelector('.deck-stage');
        if (stage) stage.style.transform = 'none';
        const active = slides[index];
        const target = active.querySelectorAll('svg')[nth];
        active.querySelectorAll('*').forEach((el) => {
          // keep the target, its ancestors AND its own children visible
          if (el !== target && !el.contains(target) && !target.contains(el)) el.style.visibility = 'hidden';
        });
        // the viewport and the stage carry their own opaque fills — clear them
        // all, otherwise the "transparent" capture comes back solid white
        active.style.background = 'none';
        document.querySelector('.deck-viewport').style.background = 'transparent';
        document.querySelector('.deck-stage').style.background = 'transparent';
        document.documentElement.style.background = 'transparent';
        document.body.style.background = 'transparent';
        const r = target.getBoundingClientRect();
        return { x: r.left, y: r.top, width: r.width, height: r.height };
      },
      { index: i, nth: k },
    );
    const buf = await hiRes.screenshot({ clip: rect, omitBackground: true });
    rasters.set(svgs[k].svg, buf.toString('base64'));
    await hiRes.evaluate(() => {
      document.querySelectorAll('.slide *').forEach((el) => (el.style.visibility = ''));
      document.querySelectorAll('.slide').forEach((el) => (el.style.background = ''));
    });
  }
}

await browser.close();

/* ============================================================
   2. BUILD THE DECK
   ============================================================ */
const pptx = new PptxGenJS();
pptx.defineLayout({ name: 'DECK16x9', width: 13.333, height: 7.5 });
pptx.layout = 'DECK16x9';
pptx.title = 'Digital Wardrobe — Portfolio';

const SHAPE = { rect: pptx.ShapeType.rect, roundRect: pptx.ShapeType.roundRect, ellipse: pptx.ShapeType.ellipse };

deck.forEach((s, idx) => {
  const slide = pptx.addSlide();
  slide.background = { color: s.background.from };
  slide._bgGradient = s.background; // consumed by the XML patch below

  for (const it of s.items) {
    const pos = { x: inch(it.x), y: inch(it.y), w: inch(it.w), h: inch(it.h) };

    if (it.kind === 'shape' && it.type === 'image') {
      slide.addImage({ data: it.src, ...pos });
      continue;
    }
    if (it.kind === 'shape' && it.type === 'svg') {
      slide.addImage({ data: `image/svg+xml;base64,${Buffer.from(it.svg).toString('base64')}`, ...pos });
      continue;
    }
    if (it.kind === 'shape') {
      const opts = { ...pos };
      if (it.fill) opts.fill = { color: it.fill, transparency: Math.round((1 - it.alpha) * 100) };
      else opts.fill = { color: 'FFFFFF', transparency: 100 };
      if (it.line) {
        opts.line = {
          color: it.line, width: pt(it.lineW),
          transparency: Math.round((1 - (it.lineAlpha ?? 1)) * 100),
          dashType: it.dash || 'solid',
        };
      }
      if (it.type === 'roundRect') opts.rectRadius = inch(Math.min(it.radius, Math.min(it.w, it.h) / 2));
      slide.addShape(SHAPE[it.type] || SHAPE.rect, opts);
      continue;
    }

    /* text */
    const runs = [];
    it.runs.forEach((r) => {
      if (r.br) { if (runs.length) runs[runs.length - 1].options.breakLine = true; return; }
      runs.push({
        text: r.text,
        options: { bold: !!r.bold, color: r.color || it.color, fontSize: pt(r.size || it.size) },
      });
    });
    if (!runs.length) continue;

    slide.addText(runs, {
      ...pos,
      fontFace: 'Pretendard',
      fontSize: pt(it.size),
      color: it.color,
      align: it.align,
      valign: it.valign,
      margin: 0,
      wrap: true,
      lineSpacing: pt(it.lineHeight),
      charSpacing: it.spacing ? pt(it.spacing) : undefined,
      shrinkText: true,
      isTextBox: true,
    });
  }

  console.log(`built slide ${idx + 1}`);
});

await pptx.writeFile({ fileName: out });

/* ============================================================
   3. PATCH: the warm paper gradient PowerPoint needs as a real gradFill
   ============================================================ */
const AdmZip = (await import('adm-zip')).default;
const zip = new AdmZip(out);

/* the SVG pictures ship with a bogus .png twin — swap in the real raster */
const svgOrder = deck.flatMap((s, i) => s.items.filter((o) => o.type === 'svg').map((o) => ({ slide: i + 1, svg: o.svg })));
let swapped = 0;
for (const entry of zip.getEntries()) {
  if (!entry.entryName.endsWith('.png')) continue;
  const data = entry.getData();
  if (data.subarray(0, 4).toString() !== '<svg') continue;
  const match = svgOrder.find((s) => s.svg === data.toString('utf-8'));
  const png = match && rasters.get(match.svg);
  if (png) {
    zip.updateFile(entry.entryName, Buffer.from(png, 'base64'));
    swapped++;
  }
}

deck.forEach((s, i) => {
  const entry = `ppt/slides/slide${i + 1}.xml`;
  let xml = zip.readAsText(entry);
  if (s.background.from === s.background.to) return;
  const grad =
    `<p:bg><p:bgPr><a:gradFill rotWithShape="1"><a:gsLst>` +
    `<a:gs pos="0"><a:srgbClr val="${s.background.from}"/></a:gs>` +
    `<a:gs pos="100000"><a:srgbClr val="${s.background.to}"/></a:gs>` +
    `</a:gsLst><a:lin ang="5400000" scaled="0"/></a:gradFill><a:effectLst/></p:bgPr></p:bg>`;
  xml = xml.replace(/<p:bg>[\s\S]*?<\/p:bg>/, grad);
  zip.updateFile(entry, Buffer.from(xml, 'utf-8'));
});
zip.writeZip(out);

const objects = deck.reduce((n, s) => n + s.items.length, 0);
console.log(`exported ${out} — ${deck.length} slides, ${objects} native objects, ${swapped} SVG raster fallbacks`);
