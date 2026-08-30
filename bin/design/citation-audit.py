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

Run: python3 bin/design/citation-audit.py            the summary and the risky claims
     python3 bin/design/citation-audit.py --list     every claim, with its kind
     python3 bin/design/citation-audit.py --check    fail if the unevidenced count has grown
     python3 bin/design/citation-audit.py --bless    record the current count as the baseline
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
ABSOLUTE_WORD = r"(?:all|none|nobody|not one|every|identically|alike|universal|unanimous|never)"
NUMERIC = re.compile(r"\b\d+\s*(px|dp|rem|%)\b")


def attributes_number(blk, named):
    """Is a measurement being credited to *their* product rather than measured in ours?

    The first version flagged any block holding both a number and two system names, which caught
    almost every entry in the log -- because the numbers in this project are overwhelmingly
    measurements of this app, sitting in the same paragraph as the systems the decision was compared
    against. "`/purchases` rows were 145-245px" is not a claim about Stripe.

    What matters is a number standing next to a system's name with nothing between them to say the
    measurement is ours.
    """
    flat = " ".join(blk.split())
    flat = re.sub(r"\"[^\"]{0,120}\"", " ", flat)
    ours = re.compile(r"measured|our own|ours\b|this app|/[a-z_]+\b|derived", re.I)
    for system in named:
        for m in re.finditer(r"\b" + re.escape(system) + r"\b", flat):
            window = flat[m.end():m.end() + 70]
            if NUMERIC.search(window) and not ours.search(window):
                return True
            back = flat[max(0, m.start() - 70):m.start()]
            if NUMERIC.search(back) and not ours.search(back):
                return True
    return False

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

def overreaches(blk, named):
    """Is an absolute attached to the *systems*, rather than to something measured here?

    The first version flagged any absolute anywhere in the block, which caught "no third person at
    all" and "all four at the same indent" -- statements about this app, measured, and exactly the
    kind of claim that should be absolute. What matters is an absolute standing next to the list of
    systems: "Carbon, Material, Stripe and Linear **all** ...".
    """
    # Quoted text is a claim being *reported* -- usually one this document has just retracted -- and
    # a measurement of this app ("all four at the same indent") is exactly the kind of absolute that
    # should be absolute. Neither is an overreach about someone else's product.
    flat = " ".join(blk.split())
    flat = re.sub(r"\"[^\"]{0,120}\"", " ", flat)
    for system in named:
        for m in re.finditer(r"\b" + re.escape(system) + r"\b", flat):
            window = flat[max(0, m.start() - 90):m.end() + 90]
            if re.search(r"\b" + ABSOLUTE_WORD + r"\b", window, re.I):
                return True
    return False


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
    parts = blocks(text)
    for i, blk in enumerate(parts):
        # The decision log is a record of what was reasoned at the time, so a claim there is
        # corrected by *annotation* rather than by rewriting it -- rewriting would make the record
        # claim better reasoning than actually happened, which is the same fault one level up.
        annotated = i + 1 < len(parts) and parts[i + 1].lstrip().startswith("> *Corrected")
        named = normalise({s for s in SYSTEMS if re.search(r"\b" + re.escape(s) + r"\b", blk)})
        if len(named) < 2:
            continue
        # The decision-log entry that *records* this mistake quotes the bad claim deliberately.
        if "I generalised from Carbon" in blk:
            continue
        rows.append({
            "where": f"{doc}:{text[:text.index(blk)].count(chr(10)) + 1}",
            "n": len(named),
            "artefact": bool(ARTEFACT.search(blk)),
            "absolute": overreaches(blk, named),
            "numeric": attributes_number(blk, named),
            "first": blk.strip().split("\n")[0][:76],
            "annotated": annotated,
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
annotated = [r for r in risky if r["annotated"]]
outstanding = [r for r in risky if not r["annotated"]]
print(f"\n{len(risky)} assert unanimity across four or more systems without naming anything checkable")
print(f"  {len(annotated)} corrected in place by annotation (the decision log, which is a record)")
print(f"  {len(outstanding)} outstanding:")
risky = outstanding
for r in risky:
    print(f"  {r['where']:<32} {r['n']} systems   {r['first']}")

# A baseline, so the count can go down but not up.
#
# There is no way to check a citation's *truth* from here -- nothing in this repo can open Carbon or
# Linear. What can be held is the *form*: the number of claims that assert agreement across four or
# more systems while naming nothing a reader could look up. `--check` fails when that grows, which
# is the regression this audit exists to prevent. Lower it when you evidence one.
BASELINE = os.path.join(ROOT, "bin/design/citation-baseline.json")

if "--check" in sys.argv:
    import json
    current = len(outstanding)
    try:
        allowed = json.load(open(BASELINE))["outstanding"]
    except (OSError, KeyError, ValueError):
        print(f"No baseline at {BASELINE}. Write one with --bless.")
        sys.exit(1)
    if current > allowed:
        print(f"\nFAIL {current} unevidenced claims, baseline {allowed}.")
        print("Name the component, or say what you observed -- see \"Citing another system\" in design.md.")
        sys.exit(1)
    if current < allowed:
        print(f"\n{current} unevidenced claims, below the baseline of {allowed}. Run --bless to lower it.")
    else:
        print(f"\nok  {current} unevidenced claims, at the baseline.")
    sys.exit(0)

if "--bless" in sys.argv:
    import json
    with open(BASELINE, "w") as f:
        json.dump({"outstanding": len(outstanding),
                   "note": "Claims asserting agreement across 4+ systems with no artefact named. "
                           "The two that remain are the proximity test's known limit -- absolutes "
                           "about this app sitting next to a system's name. See design.md, "
                           "\"Citing another system\"."}, f, indent=2)
        f.write("\n")
    print(f"\nbaseline written: {len(outstanding)}")
    sys.exit(0)

if "--list" in sys.argv:
    print("\n--- every claim ---")
    for r in sorted(rows, key=lambda r: -r["n"]):
        print(f"  {r['where']:<32} {r['n']:>2}  {kind(r):<18} {r['first']}")

# Advisory: this is a prompt to check, not a build failure.
print("\nAdvisory. A claim in the riskiest form is not wrong -- it is unevidenced in a way that")
print("would take one counter-example to falsify. Name the component, or say what you observed.")
print("\nThe proximity test has a known limit: an absolute about *this app* that happens to sit")
print("within 90 characters of a system name reads as an overreach. Two in design.md do -- \"every")
print("tab\'s controller goes in active_on\" and \"every message is repeated at its own field\" --")
print("and both are measured claims about our own code, which is exactly where an absolute belongs.")
