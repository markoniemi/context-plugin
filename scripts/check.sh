#!/usr/bin/env bash
# Free checks for the context plugin. No credential, no model calls, no cost.
# Run from the repository root: scripts/check.sh
set -uo pipefail

cd "$(dirname "$0")/.."
fail=0

echo "== claude plugin validate --strict =="
if ! claude plugin validate . --strict; then
  fail=1
fi

echo
echo "== plugin directory profile (informational, not blocking) =="
# --profile directory --strict currently fails on ICON_MISSING, which needs a
# human-made square PNG and is locked in at first submission. See
# docs/token-budget.md for what is and is not enforced here.
claude plugin validate . --profile directory || true

echo
echo "== always-loaded budget =="
# Only each skill's name and description are loaded on every request; the SKILL.md
# bodies and everything under references/ load on demand. The ceiling is a
# regression guard, not a hard limit from the runtime.
ceiling=1200
total=0
for f in skills/*/SKILL.md; do
  # UTF-8 bytes, CR stripped, newline counted — matches check.ps1 exactly.
  chars=$(awk 'NR<=10 && /^(name|description):/ { sub(/\r$/, ""); n += length($0) + 1 } END { print n+0 }' "$f")
  printf '  %-24s %5d chars\n' "$f" "$chars"
  total=$((total + chars))
done
printf '  %-24s %5d chars (~%d tokens), ceiling %d\n' 'total' "$total" "$((total / 4))" "$ceiling"
if [ "$total" -gt "$ceiling" ]; then
  echo "  FAIL: always-loaded frontmatter is over the ceiling; shorten a description or raise the ceiling deliberately."
  fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "All checks passed."
else
  echo "Checks failed."
fi
exit "$fail"
