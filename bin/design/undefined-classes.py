#!/usr/bin/env python3
"""Class tokens in the views that the compiled stylesheet does not define.

A class nothing defines renders as nothing. That is how the last Bootstrap and AdminLTE
leftovers were found, and it catches what the browser sweep cannot: the sweep only visits the
pages on its list, and a dead class on any other page is invisible to it.

Two things this script is careful about, both of which produced a wrong answer first time:

  * Tailwind escapes `.` and `:` in selectors -- `.mt-0\\.5`, `.focus\\:ring-2`. A regex that
    does not unescape them reports every such utility as undefined. That version found 186
    "problems", most of which were Tailwind working correctly, so the extractor proves itself
    itself against known-good and known-dead tokens before reporting anything.

  * A class can be deliberate without being styled: a Stimulus target, a spec selector, or a
    hook belonging to a gem. `filterrific-periodically-observed` and `form-inputs` are the
    filterrific and simple_form gems' own. Those are separated out rather than reported.
"""
import re, glob, subprocess, sys, pathlib
from collections import defaultdict

ROOT = pathlib.Path(__file__).resolve().parents[2]
css = (ROOT / "app/assets/builds/tailwind.css").read_text()
defined = {m.group(1).replace("\\", "")
           for m in re.finditer(r"\.((?:\\.|[A-Za-z0-9_-])+)", css)}

for probe, expect in [("mt-0.5", True), ("focus:ring-2", True), ("gap-1.5", True),
                      ("pagination-link", True), ("data-table", True), ("w-full", True),
                      ("card-body", False), ("form-group", False), ("col-md-6", False)]:
    if (probe in defined) != expect:
        sys.exit(f"extractor is wrong: {probe} defined={probe in defined}, expected {expect}. "
                 "Fix the selector regex before trusting any result below.")
# A view may define a class in an inline <style> block -- the filter bar does, so that its submit
# button is visible without JavaScript. Those are real definitions and must not be reported.
for path in glob.glob(str(ROOT / "app/views/**/*.erb"), recursive=True):
    for block in re.findall(r"<style[^>]*>(.*?)</style>", pathlib.Path(path).read_text(errors="replace"), re.S):
        defined |= {m.group(1).replace("\\", "") for m in re.finditer(r"\.((?:\\.|[A-Za-z0-9_-])+)", block)}

print(f"extractor sane; stylesheet and inline styles define {len(defined)} class tokens\n")

# Mailers are HTML email and static/ has its own stylesheet: neither is on the design system.
SKIP = re.compile(r"app/views/\w*mailer\w*/|app/views/layouts/mailer|app/views/users/mailer/|app/views/static/")
# A token containing any of these came out of an ERB expression, not a literal class list.
NOT_A_CLASS = re.compile(r"[<>#{}%\"'()?:=,.]")

hits = defaultdict(set)
markup_tokens = set()
for path in sorted(glob.glob(str(ROOT / "app/views/**/*.erb"), recursive=True)):
    rel = path[len(str(ROOT)) + 1:]
    if SKIP.search(rel): continue
    src = pathlib.Path(path).read_text(errors="replace")
    for m in re.finditer(r'class(?:=|:\s*)(["\'])(.*?)\1', src, re.S):
        for tok in re.sub(r"<%.*?%>", " ", m.group(2), flags=re.S).split():
            tok = tok.strip(",")
            if not tok or NOT_A_CLASS.search(tok):
                continue
            markup_tokens.add(tok)
            if tok.startswith("bi-") or tok in defined:
                continue
            hits[tok].add(rel.replace("app/views/", ""))

def referenced_elsewhere(tok):
    """Deliberate hook: something other than the class attribute selects it."""
    for cmd in (["grep", "-rqF", "--include=*.js", "--include=*.rb", "--include=*.css", tok,
                 str(ROOT / "app"), str(ROOT / "lib"), str(ROOT / "config")],
                ["grep", "-rqF", tok, str(ROOT / "spec")],
                ["bash", "-lc", f"grep -rqF -- {tok!r} /usr/local/bundle/gems/*/app /usr/local/bundle/gems/*/vendor /usr/local/bundle/gems/*/lib 2>/dev/null"]):
        if subprocess.run(cmd, capture_output=True).returncode == 0:
            return True
    return False

hooks, orphans = [], []
for tok, files in hits.items():
    (hooks if referenced_elsewhere(tok) else orphans).append((tok, sorted(files)))

# JavaScript refers to classes too, and a controller left on the old icon set is invisible to a
# scan of the templates. password_visibility_controller toggled fa-eye and fa-eye-slash against
# markup that had been migrated to Bootstrap Icons, so the icon never changed and nothing failed.
JS_CLASS = re.compile(r"""classList\.(?:add|remove|toggle|contains|replace)\(\s*["'`]([^"'`]+)["'`]"""
                      r"""|(?:querySelector(?:All)?|closest|matches)\(\s*["'`]\.([A-Za-z0-9_-]+)""")
js_hits = defaultdict(set)
for path in sorted(glob.glob(str(ROOT / "app/javascript/**/*.js"), recursive=True)):
    rel = path[len(str(ROOT)) + 1:]
    for m in JS_CLASS.finditer(pathlib.Path(path).read_text(errors="replace")):
        tok = (m.group(1) or m.group(2)).strip()
        if not tok or " " in tok or tok.startswith("bi-") or tok in defined:
            continue
        # Fine if the markup carries it: then it is a selector for something real, not styling.
        if tok in markup_tokens:
            continue
        # FullCalendar renders its own chrome; fc-* names belong to the library, not to us.
        if tok.startswith("fc-"):
            continue
        js_hits[tok].add(rel)

print(f"{len(orphans)} class tokens style nothing and are selected by nothing.")
print(f"{len(hooks)} more are undefined in CSS but are deliberate hooks (JS, specs, or a gem).\n")
for tok, files in sorted(orphans):
    print(f"  {tok:36} {', '.join(files[:2])}")
print("\nThese are expected. docs/migration-map.md lists them and says why each is left alone.")

if js_hits:
    print(f"\n{len(js_hits)} class name(s) used by JavaScript that the stylesheet does not define:")
    for tok, files in sorted(js_hits.items()):
        print(f"  {tok:36} {', '.join(sorted(files))}")
    print("A controller toggling a class nothing defines does nothing, silently.")
else:
    print("\nNo JavaScript refers to a class the stylesheet does not define.")
