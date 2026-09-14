#!/usr/bin/env python3
"""Undefined-name lint for a notebook, as one module.

Why this exists: our local harness runs notebooks with no DICOM present, so every
`if HAVE_IMAGES:` branch is skipped and a missing function inside one is invisible until it costs
a Kaggle run. exp-10 died that way on `preflight`. pyflakes reads the code, not the execution path.
"""
import json, sys
from pyflakes.api import check
from pyflakes.reporter import Reporter

IGNORE = ("imported but unused", "unable to detect undefined names", "redefinition of unused",
          "assigned to but never used", "is assigned to but never used", "f-string is missing placeholders")

class Collect(Reporter):
    def __init__(self):
        self.msgs = []
    def unexpectedError(self, filename, msg): self.msgs.append(f"{filename}: {msg}")
    def syntaxError(self, filename, msg, lineno, offset, text): self.msgs.append(f"line {lineno}: {msg}")
    def flake(self, message): self.msgs.append(str(message))

def lint(path):
    nb = json.load(open(path))
    src = "\n".join("".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code")
    rep = Collect()
    check(src, path, rep)
    bad = [m for m in rep.msgs if not any(i in m for i in IGNORE)]
    for m in bad:
        print("  " + m)
    return bad

if __name__ == "__main__":
    fails = 0
    for p in sys.argv[1:]:
        bad = lint(p)
        print(f"{'FAIL' if bad else 'ok  '}  {p}")
        fails += bool(bad)
    sys.exit(1 if fails else 0)
