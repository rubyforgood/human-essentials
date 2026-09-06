#!/usr/bin/env python3
"""Turn a screenshot spec (JSON) into a runnable Playwright snippet.

Usage:
    docs/utils/screenshots/mkshot.py SPEC.json [--out .playwright-mcp/run.js]

Then run the snippet with the Playwright MCP tool `browser_run_code_unsafe`,
passing the output path as its `filename` argument.

Relative `out` paths inside the spec are resolved against the repository root,
so specs can say "docs/user_guide/bank/images/..." regardless of where they
are stored. See README.md for the spec format.
"""
import argparse
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def repo_root():
    try:
        return subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()
    except Exception:
        return os.getcwd()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("spec", help="JSON spec file with a top-level 'shots' list")
    ap.add_argument("--out", default=".playwright-mcp/run.js", help="where to write the runnable snippet (default: .playwright-mcp/run.js)")
    ap.add_argument("--template", default=os.path.join(HERE, "shot.tmpl.js"))
    args = ap.parse_args()

    root = repo_root()
    with open(args.spec) as f:
        spec = json.load(f)
    if "shots" not in spec:
        sys.exit("spec must have a top-level 'shots' list")

    for shot in spec["shots"]:
        if "out" not in shot:
            sys.exit(f"shot is missing 'out': {json.dumps(shot)[:120]}")
        if not os.path.isabs(shot["out"]):
            shot["out"] = os.path.join(root, shot["out"])
        os.makedirs(os.path.dirname(shot["out"]), exist_ok=True)

    with open(args.template) as f:
        template = f.read()
    out_path = args.out if os.path.isabs(args.out) else os.path.join(root, args.out)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write(template.replace("__PARAMS__", json.dumps(spec)))

    names = [os.path.basename(s["out"]) for s in spec["shots"]]
    print(f"{out_path} ready ({len(names)} shots): {', '.join(names)}")


if __name__ == "__main__":
    main()
