# exp-20260913-02-labeller-es

- **Type:** data-analysis → labeller version bump · **Fix budget:** 3 · **Plan gate:** required only
  for the final model re-run (0.36 GPU h)

## Question

The labeller's osteoarthritis vocabulary is English-first (`chondropath`, `cartilage loss`,
`osteophyt`). Spanish dominates this corpus and writes **`condropatía`**, **`cartílago`**,
**`rotuliana`**, which do not match. The three OA targets have the lowest coverage of all twelve
(PF OA 13.8%, Lateral OA 12.1%, Medial OA 15.5%). Does closing the Spanish vocabulary raise
coverage, the labeller's own AUC, and then the model?

## Success / failure — three gates, in order, each with its own error bars

**Gate 1 — coverage (n ≈ 4,349 reports, tight).**
- **Pass:** PF OA / Lateral OA / Medial OA coverage rises by **≥ 5 percentage points** with no other
  target's coverage falling. At n≈4,349 the standard error on a proportion is <1pp, so 5pp is
  unambiguous — this gate is *not* subject to the gold-set σ.
- **Fail:** < 5pp. The vocabulary was not the binding problem; stop before spending GPU.

**Gate 2 — labeller AUC on gold (n = 58, noisy).**
- **Pass:** macro AUC rises above **0.6879** *and* no target regresses by more than 0.05.
- **Careful:** this is measured on 58 studies and carries its own σ. Treat a small rise as
  *consistent with* improvement, not proof of it. Gate 1 is the evidence; this is the sanity check.
- **Fail:** macro AUC drops, or any target regresses badly — the new patterns are matching the
  wrong things. Inspect the newly-labelled reports by hand before iterating.

**Gate 3 — model CV (the expensive one, 0.36 GPU h).**
- **+1 lead:** gold CV moves by **> 0.1110 (2σ)** — the full AGENTS.md §13 bar.
- **Honest expectation:** this is unlikely on three of twelve targets alone. A +0.03 macro gain from
  fixing 3/12 targets would be real and still unprovable at 2σ. So Gate 3 is **not** the decision
  point: gates 1 and 2 decide whether the labeller version ships; gate 3 is recorded either way and
  contributes to the case for exp-04 (a screening metric with tighter error bars).
- **−1:** CV *drops* by more than 2σ. Then the extra labels are actively harmful — likely false
  positives from over-broad patterns — and `v2` is reverted.

**Invalid:** the known-gap assertions in the notebook were deleted rather than updated; or the
labeller changed without bumping `LABELLER_VERSION`, making the run incomparable to the baseline.

## Ships as

`labels/v2-es.md` + `LABELLER_VERSION = "v2-es"`, with new negation unit tests for every added
pattern (`sin condropatía`, `cartílago conservado`).
