# Annotated screenshot helper

Tools for taking the user guide's screenshots in a repeatable way: a 1400px-wide
capture of the running dev app, cropped to the area the text is talking about,
with red boxes and red numbers/letters that match the numbered steps on the page.

Files:

| File | Purpose |
| --- | --- |
| `shot.tmpl.js` | Playwright snippet template. Logs in, sets up the page, grows the viewport, draws the boxes, crops, saves. |
| `mkshot.py` | Inlines a JSON spec into the template and writes `.playwright-mcp/run.js`. |
| `example_spec.json` | A spec showing the common shapes: sidebar navigation, a button on a list page, cropping to a dashboard card, a modal. |
| `../check_guide_images.sh` | Finds markdown image references with no file, and image files no page references. |

## Running

1. Start the app (`bin/start`) with a freshly seeded database so the sample data matches what other pages show.
2. Write a spec (see below), then generate the snippet:

   ```sh
   docs/utils/screenshots/mkshot.py my_spec.json
   ```

3. Run it. From Claude Code with the Playwright MCP plugin, call `browser_run_code_unsafe` with `filename` set to the generated `.playwright-mcp/run.js`. The tool only reads files under the repository, and `.playwright-mcp/` is where the plugin keeps its own logs, so it is a good untracked home for specs and generated snippets.

   Without the MCP tool, the same snippet body can be pasted into any Playwright script as `await (SNIPPET)(page)`.

4. Read the returned `boxes` list. Every mark should have `x/y/w/h`; a `missing` entry means the selector matched nothing, and a 4x4 box at `-2,-2` means it matched a hidden element (typically a sidebar dropdown header, see gotchas).
5. Open each image and look at it. The box list tells you a target was found, not that it was the right one.

## Spec format

```json
{
  "base": "http://localhost:3000",
  "password": "password!",
  "shots": [ { ...shot }, { ...shot } ]
}
```

Shots run in order in the same browser tab, so a shot without `url` or `pre` reuses the state left by the previous shot (handy for several crops of one page).

| Key | Meaning |
| --- | --- |
| `out` | Output path. Relative paths are resolved from the repo root, e.g. `docs/user_guide/bank/images/partners/partners_add.png`. |
| `url` | Page to open first (absolute URL). |
| `pre` | List of steps run before capturing (below). |
| `width`, `height` | Viewport size. Default 1400 wide; height is only meaningful with `viewport`. |
| `viewport` | `true` keeps a fixed-height viewport instead of growing to the document height. Use for modals and other `position: fixed` content. |
| `clip` | `{x, y, width, height}` crop in page pixels. The content area starts at `x: 250` (the sidebar is 250px). |
| `clipTo` | CSS selector of an element to crop to, padded by `clipPad` (default 12). |
| `full` | Capture the whole (grown) viewport with no crop. |
| `css` | Extra CSS injected before capture (hide something, force a state). |
| `marks` | List of things to box (below). |

Pre-steps (each step is an object with one of these keys):

| Step | Meaning |
| --- | --- |
| `{"login": "org_admin1@example.com"}` | Sign in via `/users/sign_in`. Optional `password`. |
| `{"goto": "/partners"}` | Navigate; relative paths use `base`. |
| `{"click": "selector", "wait": 400}` | Click, then wait ms. Playwright selectors, so `a.btn:has-text('Filter')` works here. |
| `{"fill": "selector", "value": "..."}`, `{"select": ...}`, `{"check": ...}`, `{"uncheck": ...}` | Form interaction. |
| `{"hover": "selector"}`, `{"mouse": [x, y]}` | Pointer moves, for tooltips and hover menus. |
| `{"scroll": "selector"}` | Scroll an element into view. |
| `{"sleep": 800}` | Wait for animations/turbo frames. |
| `{"eval": "js"}` | Run arbitrary JS in the page. Used to tag an element (`el.classList.add('__target')`) so `clipTo`/`marks` can reach something with no stable selector. |

Marks:

| Key | Meaning |
| --- | --- |
| `sel` | CSS selector (`document.querySelector`, so no `:has-text`). |
| `text` | Exact visible text; combined with `sel` as the candidate set. |
| `contains` | Substring of visible text; candidates default to `a,button`. |
| `nth` | Pick the nth match of `sel`. |
| `pad` | Pixels of padding around the element (default 4; 6 for buttons, 2 for menu items). |
| `label` | Text for the red label. Defaults to the 1-based index; `false` for a box with no label. |
| `side` | Where the label sits: `left` (default), `right`, `above`, `below`, `inside`. Use `right` for things at the left edge of the crop. |

## Conventions

- 1400px wide. Crop to the content (`x: 250`) unless the text is about the left-hand menu, in which case include the sidebar from `x: 0`.
- Boxes are 3px `#e01b24` with a 4px radius; labels are bold 26px red with a white glow. Numbers when the text has numbered steps, letters when it is naming things rather than sequencing them.
- Do not box something the app already highlights (red shortage numbers, warning banners). The box would be redundant and could be mistaken for part of the UI.
- Name files after the page and the thing being shown, and keep the name when re-shooting so the markdown does not change.
- Composite images (before/after, two tabs) are made with ImageMagick after capture:

  ```sh
  magick top.png bottom.png -background '#dddddd' -splice 0x6 -append out.png   # stack with a grey separator
  magick wide.png -crop 1145x225+72+0 +repage out.png                          # sub-crop an existing capture
  ```

## Gotchas

- **Draw after resizing.** The template grows the viewport to the document height and only then draws boxes. Doing it the other way round leaves right-aligned controls (buttons, tabs, action columns) with boxes that are visibly off.
- **No `fullPage`.** AdminLTE's `layout-fixed` body reflows under Playwright's full-page mode and the sidebar is painted over the content. Grow the viewport instead (the template does).
- **Sidebar dropdown headers** (Donations, Purchases, Inventory, Community...) are `a.nav-link[href="#"]`. Match them with `contains`, not by href.
- **Modals** are `position: fixed`. Use `viewport: true`, `clipTo: ".modal-content"` (not `.modal-dialog`, which is the full overlay), and rely on the template's fade-transition kill.
- **select2** hides the real `<select>`; mark `.select2-container` next to it.
- **Native confirm dialogs** cannot be captured. Quote the dialog text in the guide instead.
- **Forms as buttons.** Some actions (Invite User, Remove User) are `input[type=submit]` or `form button`, not links; `contains` with `sel: "a,button,input"` finds them.
- **Seed state matters.** The Getting Started prompt on the dashboard only shows while `organization.bank_is_set_up` is false; partner approval buttons only show for partners in `awaiting_review`. Toggle with `bin/rails runner` before shooting, and put it back afterwards.
- **Dev chrome.** rack-mini-profiler and bullet footers are hidden by the template; if something else appears in a corner, add it to `css`.
