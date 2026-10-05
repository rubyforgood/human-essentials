#!/usr/bin/env bash
# Check the user guide's images: report markdown references to files that do
# not exist, and image files that no markdown page references (orphans).
#
# Usage: docs/utils/check_guide_images.sh [docs/user_guide/bank]
# Exit status is non-zero if anything is missing (orphans are a warning only).
set -euo pipefail
GUIDE="${1:-docs/user_guide/bank}"
cd "$(git rev-parse --show-toplevel)"

refs() {
  # Matches both ![alt](images/x.png) and <img src="images/x.png">
  grep -rhoE '(\]\(|src=")images/[^)" ]+' "$GUIDE"/*.md | sed -E 's/^(\]\(|src=")//' | sort -u
}

echo "== Missing images (referenced in markdown, file not found)"
missing=0
while read -r ref; do
  if [ ! -f "$GUIDE/$ref" ]; then echo "  MISSING  $ref"; missing=$((missing+1)); fi
done < <(refs)

echo "== Orphan images (file exists, no markdown page references it)"
find "$GUIDE/images" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' \) | sort | while read -r f; do
  rel="${f#"$GUIDE"/}"
  if ! grep -rqF "$rel" "$GUIDE"/*.md; then echo "  ORPHAN   $rel"; fi
done

echo "== Case mismatches (reference exists only with different capitalisation)"
while read -r ref; do
  if [ ! -f "$GUIDE/$ref" ] && find "$GUIDE/$(dirname "$ref")" -maxdepth 1 -iname "$(basename "$ref")" 2>/dev/null | grep -q .; then
    echo "  CASE     $ref"
  fi
done < <(refs)
[ "$missing" -eq 0 ]
