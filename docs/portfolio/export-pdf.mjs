/**
 * portfolio-slides.html을 A4 가로 8페이지 PDF로 내보낸다.
 *
 *   node docs/portfolio/export-pdf.mjs
 *
 * Chrome의 `--print-to-pdf` CLI는 CSS `@page { size: A4 landscape }`를 무시하고
 * US Letter 세로로 찍어버린다. 그래서 DevTools Protocol의 Page.printToPDF에
 * 용지 크기를 직접 넘긴다. 외부 의존성 없음 (Node 22+ 내장 WebSocket 사용).
 */
import { spawn } from "node:child_process";
import { writeFileSync, existsSync } from "node:fs";
import { pathToFileURL } from "node:url";
import path from "node:path";

const HERE = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, "$1"));
const INPUT = path.join(HERE, "portfolio-slides.html");
const OUTPUT = path.join(HERE, "portfolio-slides.pdf");
const PORT = 9333;

const CHROME_CANDIDATES = [
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
  "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe",
];

const chrome = CHROME_CANDIDATES.find(existsSync);
if (!chrome) throw new Error("Chrome/Edge를 찾지 못했습니다.");
if (!existsSync(INPUT)) throw new Error(`${INPUT} 없음. 먼저 python docs/portfolio/build.py 실행.`);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const proc = spawn(chrome, [
  "--headless=new",
  "--disable-gpu",
  `--remote-debugging-port=${PORT}`,
  "--no-first-run",
  "--user-data-dir=" + path.join(HERE, ".chrome-profile"),
  "about:blank",
], { stdio: "ignore" });

let ws;
try {
  let target;
  for (let i = 0; i < 40; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${PORT}/json/new?${pathToFileURL(INPUT).href}`, { method: "PUT" });
      target = await res.json();
      break;
    } catch { await sleep(250); }
  }
  if (!target) throw new Error("Chrome 디버깅 포트에 연결하지 못했습니다.");

  ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });

  let id = 0;
  const pending = new Map();
  ws.onmessage = (e) => {
    const msg = JSON.parse(e.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
    }
  };
  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const n = ++id;
      pending.set(n, { resolve, reject });
      ws.send(JSON.stringify({ id: n, method, params }));
    });

  await send("Page.enable");
  await sleep(2500); // base64 이미지 디코딩 + 웹폰트 안착 대기

  const { data } = await send("Page.printToPDF", {
    landscape: true,
    printBackground: true,
    preferCSSPageSize: false,
    paperWidth: 11.693,   // A4 297mm
    paperHeight: 8.268,   // A4 210mm
    marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0,
    scale: 1,
  });

  writeFileSync(OUTPUT, Buffer.from(data, "base64"));
  console.log(`written ${OUTPUT} (${(Buffer.from(data, "base64").length / 1024).toFixed(1)} KB)`);
} finally {
  try { ws?.close(); } catch {}
  proc.kill();
}
