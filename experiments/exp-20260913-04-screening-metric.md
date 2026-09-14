# exp-20260913-04 — screening metric

**Verdict: +1.** Run 2026-09-14, 0.44 GPU h. The instrument works and is adopted.

## Result

3-fold out-of-fold predictions over the 3,406 weakly-labelled studies, two arms differing only in
backbone initialisation, scored against the weak labels.

| | screening metric | on the 58 gold studies |
|---|---|---|
| pretrained | **0.7773** | 0.6524 |
| random init | **0.6970** | 0.6379 |
| **Δ** | **+0.0803** | +0.0145 |

- **Paired bootstrap σ(Δ) = 0.0091 → 2σ bar = 0.0182.**
- Δ 95% CI **[+0.0630, +0.0970]** — excludes zero decisively.
- Ranking agrees with the public LB (pretrained 0.641 vs random-init 0.595).

## Why this passes

The plan's success condition was: rank the arms correctly **and** carry a 2σ bar below 0.03.

| instrument | 2σ bar | can it see the LB's +0.046 effect? |
|---|---|---|
| 58 gold studies | 0.1110 | **no** |
| screening metric | **0.0182** | **yes, 2.5× over the bar** |

**6× tighter.** The effect that the leaderboard proved real, and that our gold set called
"unprovable", is now measurable in-house without spending a submission.

## Honest limits

1. **It measures agreement with weak labels, not with truth.** Δ here (+0.080) is larger than the
   LB's (+0.046) because a pretrained encoder fits the *weak labels* better, which is not the same
   quantity as fitting reality. Use it to **rank** variants, never to quote a score.
2. It inherits the labeller's blind spots (exp-03: pooled false-positive rate 0.66). An improvement
   in detecting something the reports never mention will read as nothing here.
3. It costs 0.44 GPU h per comparison — not free. For single-arm experiments, one 3-fold OOF run is
   0.22 h, which is the price of a readable answer.
4. The gold numbers above (0.65 / 0.64) are lower than the baseline's 0.6339-on-3-seeds because each
   fold model trains on two thirds of the data. They are not comparable to lineage L0's CV.

## Process note

The run trained all six folds, then died in the scoring cell on a missing `roc_auc_score` import —
the cell that normally imports it is not part of this notebook. The OOF predictions were already
saved, so scoring was done locally at zero GPU cost, and the notebook has been patched.
`scripts/lint_nb.py` (added after this push) catches exactly this class and is now a pre-push gate.
