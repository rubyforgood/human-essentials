// Playwright snippet for capturing annotated user-guide screenshots.
//
// This file is a TEMPLATE: `mkshot.py` replaces the PARAMS placeholder below with the JSON
// contents of a spec file and writes the result to .playwright-mcp/run.js,
// which is then executed with the Playwright MCP tool
// `browser_run_code_unsafe` (pass the file via its `filename` argument).
//
// See README.md in this directory for the spec format, and
// docs/agentic_update.md for the overall workflow.
async (page) => {
const p = __PARAMS__;
const BASE = p.base || 'http://localhost:3000';
const PASSWORD = p.password || 'password!';
const results = [];
for (const s of p.shots) {
  // 1. Viewport. 1400px wide is the guide's standard; `viewport: true` keeps a
  //    fixed-height viewport (needed for position:fixed things like modals).
  if (s.width || s.viewport) await page.setViewportSize({width: s.width || 1400, height: s.height || (s.viewport ? 1300 : 900)});
  if (s.url) { await page.goto(s.url); await page.waitForLoadState('networkidle'); }
  // Kill Bootstrap fade transitions so modals are fully visible immediately.
  await page.addStyleTag({content: '.modal.fade .modal-dialog{transition:none!important;transform:none!important} .modal.fade{transition:none!important} .fade{transition:none!important}'});

  // 2. Pre-steps: get the page into the state you want to photograph.
  if (s.pre) { for (const step of s.pre) {
    if (step.login) { await page.goto(BASE + '/users/sign_in'); await page.fill('input[name="user[email]"]', step.login); await page.fill('input[name="user[password]"]', step.password || PASSWORD); await page.click('input[type=submit],button[type=submit]'); await page.waitForLoadState('networkidle'); }
    if (step.goto) { await page.goto(step.goto.startsWith('http') ? step.goto : BASE + step.goto); await page.waitForLoadState('networkidle'); }
    if (step.click) { await page.click(step.click); await page.waitForTimeout(step.wait || 400); }
    if (step.mouse) { await page.mouse.move(step.mouse[0], step.mouse[1]); await page.waitForTimeout(step.wait || 600); }
    if (step.hover) { await page.hover(step.hover); await page.waitForTimeout(step.wait || 600); }
    if (step.fill) await page.fill(step.fill, step.value);
    if (step.select) await page.selectOption(step.select, step.value);
    if (step.check) await page.check(step.check);
    if (step.uncheck) await page.uncheck(step.uncheck);
    if (step.scroll) await page.evaluate(sel => document.querySelector(sel).scrollIntoView({block:'center'}), step.scroll);
    if (step.sleep) await page.waitForTimeout(step.sleep);
    if (step.eval) await page.evaluate(step.eval);
  } }

  // 3. Hide dev-only chrome (rack-mini-profiler, bullet) plus any per-shot CSS.
  await page.addStyleTag({content: '.profiler-results,#bullet-footer,#bullet-footer-div{display:none!important} ' + (s.css || '')});

  // 4. Grow the viewport to the full document height. Do NOT use Playwright's
  //    fullPage option: the AdminLTE "layout-fixed" body reflows and the
  //    sidebar ends up drawn over the content.
  const docH = await page.evaluate(() => Math.min(12000, Math.max(document.documentElement.scrollHeight, document.body.scrollHeight)));
  const vw = s.width || 1400;
  if (!s.viewport && (s.full || s.clip || s.clipTo)) { await page.setViewportSize({width: vw, height: Math.max(900, docH)}); await page.evaluate(() => { window.scrollTo(0,0); document.querySelectorAll('*').forEach(e => { if (e.scrollTop) e.scrollTop = 0; }); }); await page.waitForTimeout(400); }

  // 5. Draw the red boxes and labels. This MUST happen after the resize above:
  //    the reflow moves right-aligned controls, and boxes drawn earlier end up
  //    offset from their targets.
  const marks = s.marks || [];
  const boxes = await page.evaluate(([marks]) => {
    document.querySelectorAll('.__anno').forEach(e => e.remove());
    const out = [];
    marks.forEach((m, i) => {
      let el = null;
      if (m.text) {
        const all = Array.from(document.querySelectorAll(m.sel || 'a,button,input,label,th,td,h1,h2,h3,h4,h5,li,span,p,div'));
        el = all.find(e => e.innerText && e.innerText.trim() === m.text && e.getClientRects().length) || all.find(e => e.innerText && e.innerText.trim().includes(m.text) && e.children.length === 0);
      } else if (m.contains) {
        el = Array.from(document.querySelectorAll(m.sel || 'a,button')).find(e => e.innerText && e.innerText.includes(m.contains) && e.getClientRects().length);
      } else if (m.nth != null) { el = document.querySelectorAll(m.sel)[m.nth]; }
      else el = document.querySelector(m.sel);
      if (!el) { out.push({i, missing: m}); return; }
      const r = el.getBoundingClientRect();
      const pad = m.pad == null ? 4 : m.pad;
      const x = r.left - pad, y = r.top - pad, w = r.width + 2*pad, h = r.height + 2*pad;
      const d = document.createElement('div'); d.className = '__anno';
      d.style.cssText = `position:fixed;left:${x}px;top:${y}px;width:${w}px;height:${h}px;border:3px solid #e01b24;border-radius:4px;box-sizing:border-box;z-index:99999;pointer-events:none;`;
      document.body.appendChild(d);
      if (m.label !== false) {
        const l = document.createElement('div'); l.className = '__anno';
        const lbl = m.label || String(i+1);
        const side = m.side || 'left';
        let lx = x - 34, ly = y - 6;
        if (side === 'right') lx = x + w + 6;
        if (side === 'above') { lx = x; ly = y - 36; }
        if (side === 'below') { lx = x; ly = y + h + 4; }
        if (side === 'inside') { lx = x + 4; ly = y + 4; }
        if (lx < 0) lx = x + w + 6;
        l.style.cssText = `position:fixed;left:${lx}px;top:${ly}px;font:bold 26px/1 Arial,Helvetica,sans-serif;color:#e01b24;z-index:99999;pointer-events:none;text-shadow:0 0 3px #fff,0 0 3px #fff;`;
        l.textContent = lbl;
        document.body.appendChild(l);
      }
      out.push({i, x, y, w, h});
    });
    return out;
  }, [marks]);

  // 6. Work out the crop. `clip` is explicit; `clipTo` crops to an element
  //    (plus clipPad); neither means the whole viewport.
  let clip = s.clip;
  if (s.clipTo) {
    clip = await page.evaluate((sel) => { const r = document.querySelector(sel).getBoundingClientRect(); return {x: r.left, y: r.top, width: r.width, height: r.height}; }, s.clipTo);
    const m = s.clipPad == null ? 12 : s.clipPad;
    clip = {x: Math.max(0, clip.x - m), y: Math.max(0, clip.y - m), width: clip.width + 2*m, height: clip.height + 2*m};
  }
  await page.waitForTimeout(150);
  const opts = {path: s.out};
  if (clip) opts.clip = clip;
  await page.screenshot(opts);

  // 7. Reset for the next shot.
  await page.setViewportSize({width: vw, height: s.height || 900});
  await page.evaluate(() => document.querySelectorAll('.__anno').forEach(e => e.remove()));
  results.push({out: s.out, boxes});
}
// The returned boxes are your first sanity check: a `missing` entry means a
// selector matched nothing; a 4x4 box at -2,-2 means it matched a hidden element.
return results;
}
