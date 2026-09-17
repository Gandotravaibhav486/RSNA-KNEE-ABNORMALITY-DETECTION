# Plan — exp-28, resolution at a constant pixel budget (384 px)

**Type:** architecture · **Fix budget:** 2 fixes / ≤3 GPU h + screening (AGENTS.md §8)
**Status:** awaiting approval (AGENTS.md §0 — no GPU spend without it)

## Why this is the next experiment

Three lines are now closed. Schedule is flat by 12 epochs (exp-27, Δ −0.0003). Window count and
distribution do not survive 12 epochs (exp-26, +0.0179 at 4 epochs → −0.0158 at 12). Ensembling is
not the lever (exp-21: their *single* CoAtNet 0.9205 > their 5-model ensemble 0.9118 > our 3-seed
ensemble 0.7914).

What is left, and what we have never tested, is **resolution**. The public 0.936's strongest single
branch runs at **384 px**; their DINOv2 branch at 336. We run at **224**. Our remaining headroom is
0.065 of macro AUC concentrated in MCL, Lateral Meniscus and ACL — focal structures a few millimetres
across, which is exactly what resolution should buy and what more windows did not.

## The constraint that shapes the design

Resolution cannot simply be added. Compute and inference seconds scale with `K × IMG²`:

| config | K × IMG² | GPU vs b1 | inference at 5,000 studies |
|---|---|---|---|
| **b1** — 18 windows @224 | 903,168 | 1.0× | 3.69 s/study → **5.1 h** (cap 9 h, working limit 6.75) |
| 18 windows @384 (naive) | 2,654,208 | 2.94× | ≈10.8 s/study → **15 h** — **over the cap, unsubmittable** |
| **p5** — 6 windows @384 | 884,736 | **0.98×** | ≈3.6 s/study → **5.0 h** |

So the question is not "is 384 better than 224" — it is **"at the pixel budget the rules force on us,
is detail worth more than coverage?"** That is the decision we actually have to make, and it is what
this experiment measures.

## Arms

Three points on the screening metric (3-fold OOF over 3,406 weak studies, paired bar **0.0044**),
all at **12 epochs** — the length b1 trains at, per exp-26's procedural lesson that a screening
result at one training length does not transfer to another.

| arm | config | cache | cost |
|---|---|---|---|
| **b1 reference** | 18 windows @224 | p2 | already measured |
| **A — resolution** | `{"PREPROC_VERSION":"p5","IMG":384,"N_TRIPLET":1}` → 6 windows @384 | **p5, to build** | ≈0.7 GPU h |
| **B — control** | `{"WINDOW_KEEP":[1,4,7,10,13,16]}` → 6 windows @224 | p2, **no rebuild** | ≈0.25 GPU h |

Arm B is the point that makes the experiment readable. A vs b1 alone confounds two changes
(resolution up, coverage down); B isolates the coverage half by taking the middle window of each p2
slot straight out of the existing cache. Then:

- **B − b1** = what dropping 18 → 6 windows costs, at 224.
- **A − B** = what 224 → 384 buys, at a fixed 6 windows. **This is the resolution effect.**
- **A − b1** = the decision at equal cost, which is what a submission would actually be.

`WINDOW_KEEP` is a new baseline setting defaulting to `None`; with it unset b1 is bit-identical
(verified: K=18, K_RAW=18, same `build_study`, same `__getitem__` path).

## Prerequisite — cache p5 (CPU, no GPU quota)

[`notebooks/cache-build-p5.ipynb`](../notebooks/cache-build-p5.ipynb): the same six slots and slice
band as p2, `N_TRIPLET` 3 → 1, `IMG` 224 → 384. Expected ≈8 GB, the same as p2, and *fewer* slices
decoded per study, so the build is faster than p2's. Accelerator **None** — this must not bill GPU.

## Expected effect

+0.005 to +0.02 on the screening metric if resolution is the constraint; a clear negative if
coverage matters more than detail at this budget. Either is legible against a 0.0044 bar.

## Kill criteria — written before the numbers

- **OOM at 384.** Halve `BATCH` to 4 once; if it still OOMs, stop and report. (Fix 1 of 2.)
- **Per-epoch time > 1.5× b1** — the pixel budget was supposed to hold cost constant; if it does not,
  the arm is not the experiment it claims to be. Stop, report the measured seconds.
- **A − B ≤ 0.0044** → resolution is *not* the lever at fixed cost. Verdict −1, and the architecture
  line closes with the other three. Do not re-open it by spending more pixels; that route is barred
  by the 9 h cap, not by the measurement.
- **A − b1 ≥ 0.0044** → +1, and only then spend ≈2 GPU h on a full 3-seed run with test inference,
  for one leaderboard point against b1's 0.824.

## Success

A cleanly measured statement about resolution at a fixed inference budget, with the coverage half
controlled — whichever direction it points. Promotion to `b2` requires the §13.1 gate
(≥20% error-gap closure), which at b1's 0.8319 means gold ≥ **0.866**. Nothing here is expected to
clear that; a +1 here is an accepted improvement, not a new baseline.
