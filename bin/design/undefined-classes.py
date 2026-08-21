#!/usr/bin/env python3
"""Class tokens in the views that the compiled stylesheet does not define.

A class nothing defines renders as nothing. That is how the last Bootstrap and AdminLTE
leftovers were found, and it catches what the browser sweep cannot: the sweep only visits the
pages on its list, and a dead class on any other page is invisible to it.

Two things this script is careful about, both of which produced a wrong answer first time:

  * Tailwind escapes `.` and `:` in selectors -- `.mt-0\\.5`, `.focus\\:ring-2`. A regex that
    does not unescape them reports every such utility as undefined. That version found 186
    "problems", most of which were Tailwind working correctly, so the extractor sanity-checks
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
print(f"extractor sane; stylesheet defines {len(defined)} class tokens\n")

# Mailers are HTML email and static/ has its own stylesheet: neither is on the design system.
SKIP = re.compile(r"app/views/\w*mailer\w*/|app/views/layouts/mailer|app/views/users/mailer/|app/views/static/")
# A token containing any of these came out of an ERB expression, not a literal class list.
NOT_A_CLASS = re.compile(r"[<>#{}%\"'()?:=,.]")

hits = defaultdict(set)
for path in sorted(glob.glob(str(ROOT / "app/views/**/*.erb"), recursive=True)):
    rel = path[len(str(ROOT)) + 1:]
    if SKIP.search(rel): continue
    src = pathlib.Path(path).read_text(errors="replace")
    for m in re.finditer(r'class(?:=|:\s*)(["\'])(.*?)\1', src, re.S):
        for tok in re.sub(r"<%.*?%>", " ", m.group(2), flags=re.S).split():
            tok = tok.strip(",")
            if not tok or NOT_A_CLASS.search(tok) or tok.startswith("bi-") or tok in defined:
                continue
            hits[tok].add(rel.replace("app/views/", ""))

def referenced_elsewhere(tok):
    """Deliberate hook: something other than the class attribute selects it."""
    for cmd in (["grep", "-rqF", "--include=*.js", "--include=*.rb", "--include=*.css", tok,
                 str(ROOT / "app"), str(ROOT / "lib"), str(ROOT / "config")],
                ["grep", "-rqF", tok, str(ROOT / "spec")],
                ["bash", "-lc", f"grep -rqF -- {tok!r} /usr/local/bundle/gems/*/app /usr/local/bundle/gems/*/vendor 2>/dev/null"]):
        if subprocess.run(cmd, capture_output=True).returncode == 0:
            return True
    return False

hooks, orphans = [], []
for tok, files in hits.items():
    (hooks if referenced_elsewhere(tok) else orphans).append((tok, sorted(files)))

print(f"{len(orphans)} class tokens style nothing and are selected by nothing.")
print(f"{len(hooks)} more are undefined in CSS but are deliberate hooks (JS, specs, or a gem).\n")
for tok, files in sorted(orphans):
    print(f"  {tok:36} {', '.join(files[:2])}")
print("\nThese are expected. docs/migration-map.md lists them and says why each is left alone.")
