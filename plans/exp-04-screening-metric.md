# Plan — exp-20260913-04, screening metric

**Type:** split · **Fix budget:** 2 · **GPU budget for this type:** ≤ 0.5 h (AGENTS.md §8)

## Corrected cost

I earlier said "~0.1 GPU h". That was wrong: the model trains on all 3,406 weakly-labelled studies,
so predictions on them are in-sample and worthless as a metric. A screening metric needs
**out-of-fold** predictions, which means training folds.

| | |
|---|---|
| 3 folds × 2 arms (pretrained, random-init) | 6 trainings of ~2,270 studies × 4 epochs |
| measured cost basis | 0.12 GPU h per 4-epoch run on 3,406 studies |
| **estimated total** | **≈ 0.48 GPU h** — just inside the 0.5 h `split` budget |

If it overruns 1.5× (0.72 h) the run stops and escalates, per §8.

## What it produces

1. OOF predictions for ~3,406 studies from each arm.
2. `screen_auc` — macro AUC against the **weak** labels (masked), for each arm.
3. A **bootstrap noise floor** for that metric, resampling studies, directly comparable in spirit to
   our gold σ of 0.0555 (2σ = 0.1110).
4. The paired Δ between the two arms and its bootstrap σ.

## Success / failure

The two arms are a **known-answer test**: the public LB says pretrained (0.641) beats random-init
(0.595) by 0.046, and gold CV agrees in direction (+0.030) but calls it unprovable at 2σ.

| Verdict | Condition |
|---|---|
| **Success (+1)** | Screening metric ranks pretrained above random-init **and** its 2σ bar is below 0.03 — i.e. it can resolve an effect the gold set cannot. It then becomes the primary screening instrument. |
| **Partial** | Correct ranking but a 2σ bar between 0.03 and 0.11. Better than gold, still blunt; use it as a filter, not a decider. |
| **Failure (−1)** | Wrong ranking, or a bar no tighter than gold's. The weak labels are too corrupted to screen against, and we are stuck with n=58 plus the LB. |
| **Invalid** | Any fold's training set overlaps its evaluation set; gold studies leak into training; arms differ in anything but the backbone init. |

## Note on what this metric is and is not

It scores agreement with **weak labels**, which exp-03 showed are a mention detector with a pooled
false-positive rate of 0.66. So its absolute value is **not** comparable to a gold AUC and must never
be reported as "our score". It is an instrument for *ranking* pipeline variants, and it inherits the
labeller's blind spots — a change that improves true detection of something the reports never
mention will look like nothing here.
