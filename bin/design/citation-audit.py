#!/usr/bin/env python3
"""Audits the industry citations in design.md and docs/design-decisions.md.

Written after a real error: design.md justified the selection bar covering the filter row with
"three of the four keep it in the toolbar", citing Carbon, Material, GitHub and Gmail -- when only
Carbon takes the filters away. The other three were counted as agreeing by describing them all as
"keeping it in the toolbar", which is true of the *category* and false of the specific behaviour.

This cannot check whether a claim is true; nothing here can browse. What it can do is find the
claims whose *form* outruns the checking behind them, so they can be softened or evidenced:

  names an artefact   cites a component, class or documented page -- `OverflowMenu`, `slds-truncate`,
                      `<Table sticky />`, "Conditionally revealing a question". Strongest: a reader
                      can look it up and disagree.
  attributes numbers  gives a system a measurement. Checkable in principle, recalled in practice.
  asserts unanimity   "all", "none", "nobody", "not one", "identically". The riskiest form, because
                      one counter-example falsifies it and the more systems named the likelier that is.
  observational       "X, Y and Z do this", no artefact and no absolute. Honest about being a
                      description.

Run: python3 bin/design/citation-audit.py [--list]
"""
import re, sys, os
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DOCS = ["design.md", "docs/design-decisions.md"]

SYSTEMS = ["Carbon", "Material", "GitHub", "GitLab", "Gmail", "Linear", "Notion", "Airtable",
           "Google Drive", "Drive", "Ant Design", "Polaris", "Shopify", "Stripe", "Jira",
           "Atlassian", "Salesforce", "GOV.UK", "NHS", "USWDS", "Primer", "MUI", "AG Grid",
           "Handsontable", "Excel", "Google Sheets", "Confluence", "Bootstrap", "Fluent",
           "Metabase", "Slack", "Vercel", "Xero", "QuickBooks", "Mailchimp", "Apple"]

ARTEFACT = re.compile(r"`[A-Z][A-Za-z]+`|`slds-[\w-]+`|`govuk-[\w-]+`|`<[A-Z][^>]*/>`|"
                      r"`[a-z]+Field`|`\.form-check`|`ellipsis`|\"[A-Z][^\"]{6,60}\"")
ABSOLUTE = re.compile(r"\ball\b|\bnone\b|\bnobody\b|not one\b|\bevery\b|identically|\balike\b|"
                      r"universal|\bunanimous|\bnever\b")
NUMERIC = re.compile(r"\b\d+\s*(px|dp|rem|%)\b")

def blocks(text):
    out, cur = [], []
    for line in text.split("\n"):
        if not line.strip():
            if cur: out.append("\n".join(cur)); cur = []
        elif line.startswith(("- ", "* ", "| ")) and cur and not cur[-1].startswith(("  ", "|")):
            out.append("\n".join(cur)); cur = [line]
        else:
            cur.append(line)
    if cur: out.append("\n".join(cur))
    return out

def normalise(found):
    out = set()
    for f in found:
        out.add("Drive" if "Drive" in f else "Polaris" if "Polaris" in f
                else "Material" if f.startswith("Material") else f)
    return out

rows = []
for doc in DOCS:
    path = os.path.join(ROOT, doc)
    text = open(path).read()
    for blk in blocks(text):
        named = normalise({s for s in SYSTEMS if re.search(r"\b" + re.escape(s) + r"\b", blk)})
        if len(named) < 2:
            continue
        rows.append({
            "where": f"{doc}:{text[:text.index(blk)].count(chr(10)) + 1}",
            "n": len(named),
            "artefact": bool(ARTEFACT.search(blk)),
            "absolute": bool(ABSOLUTE.search(blk)),
            "numeric": bool(NUMERIC.search(blk)),
            "first": blk.strip().split("\n")[0][:76],
        })

def kind(r):
    if r["artefact"]: return "names an artefact"
    if r["numeric"]: return "attributes numbers"
    if r["absolute"]: return "asserts unanimity"
    return "observational"

print(f"{len(rows)} claims cite two or more systems\n")
for k, v in Counter(kind(r) for r in rows).most_common():
    print(f"  {v:3d}  {k}")

risky = sorted((r for r in rows if not r["artefact"] and r["absolute"] and r["n"] >= 4),
               key=lambda r: -r["n"])
print(f"\n{len(risky)} assert unanimity across four or more systems without naming anything checkable:")
for r in risky:
    print(f"  {r['where']:<32} {r['n']} systems   {r['first']}")

if "--list" in sys.argv:
    print("\n--- every claim ---")
    for r in sorted(rows, key=lambda r: -r["n"]):
        print(f"  {r['where']:<32} {r['n']:>2}  {kind(r):<18} {r['first']}")

# Advisory: this is a prompt to check, not a build failure.
print("\nAdvisory. A claim in the riskiest form is not wrong -- it is unevidenced in a way that")
print("would take one counter-example to falsify. Name the component, or say what you observed.")
