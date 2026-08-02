#!/usr/bin/env bash
set -euo pipefail
# Triggered by the fork-only focused patch runner.

python3 - <<'PY'
from pathlib import Path

path = Path("src/Lean/ReducibilityAttrs.lean")
text = path.read_text()
old = '''        else
          throwError "failed to set `[semireducible]` for `{.ofConstName declName}`{suffix}"
'''
new = '''        else
          throwError "failed to set `[semireducible]`, `{.ofConstName declName}` is not currently `[semireducible]`, but `{statusOld.toAttrString}`{suffix}"
'''
if text.count(old) != 1:
    raise SystemExit(f"expected one semireducible diagnostic match, found {text.count(old)}")
path.write_text(text.replace(old, new))

test = Path("tests/elab/reducibilityAttrValidation.lean")
text = test.read_text()
addition = '''
/--
error: failed to set `[semireducible]`, `f` is not currently `[semireducible]`, but `[irreducible]`

Note: Use `set_option allowUnsafeReducibility true` to override reducibility status validation
-/
#guard_msgs in
attribute [semireducible] f
'''
if addition.strip() in text:
    raise SystemExit("regression block already present")
test.write_text(text.rstrip() + "\n" + addition)
PY

rm -f .agent-patch.sh .github/workflows/agent-apply-patch.yml

git config user.name "Sankalp Thakur"
git config user.email "sankalphimself@gmail.com"
git add -A
git commit -m "fix: report current reducibility status"
git push origin HEAD:"${GITHUB_REF_NAME}"
