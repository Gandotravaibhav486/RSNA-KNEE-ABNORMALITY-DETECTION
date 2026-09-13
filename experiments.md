# experiments.md — experiment ledger

Append-only. One row per experiment, proposed or run. Rejected proposals stay in the table with
`status: rejected` so no one re-proposes them. Details for each experiment live in
`experiments/<exp-id>.md`.

## Baseline (must be filled before any pipeline change — AGENTS.md §1)

| Field | Value |
|---|---|
| Metric | macro ROC AUC over 12 targets *(verify against competition page)* |
| CV protocol | 3 training seeds `[2026,2027,2028]`; evaluation = 5 folds × 5 repeats over the 58 gold studies; σ from the 900 (seed,repeat,fold) cells |
| Baseline CV score | **0.6339** macro AUC on the 58 gold studies (mean of 3 seeds; 3-seed ensemble 0.6442) |
| Baseline public LB | submitted 2026-09-13 19:39 UTC, **pending** (notebook `rsna-knee-baseline-v1-full` v4). The 0.936 in the history is the copied public ensemble, not our pipeline. |
| Baseline commit | `notebooks/baseline-v1.ipynb` @ this commit; Kaggle notebook version 4; cache `p1`; labeller `v1-keyword` |
| Baseline notebook | **`notebooks/baseline-v1.ipynb`** (built 2026-09-13, all in-notebook tests pass, not yet run on GPU) |
| Weak labeller `v1-keyword` | **macro AUC 0.6879 on the 58 gold studies** — measured 2026-09-13, CPU only. This is the floor the image model must beat. |
| Date measured | 2026-09-13 (Kaggle, Tesla T4, 0.36 GPU h) |

**Baseline is measured.** The significance bar for every later experiment is **Δ > 0.1110 (2σ)**
on gold CV, computed from the 900 evaluation cells of this run.

**The headline problem:** the image model scores **0.6339**, the weak labeller alone scores
**0.6879**. The model is *worse than the text rules it was trained on*. It cannot exceed its label
ceiling, and right now it does not even reach it. This sets the experiment priority: labels first.

## Baseline lineages

The baseline moves only through the §13.1 promotion gate: **(A)** ≥20% error-gap closure
(`(gap_base − gap_new)/gap_base`, `gap = 1 − AUC`), or **(B)** a fundamentally new approach family,
which gets its own lineage rather than replacing the old one. Significant `+1`s that clear neither
gate are *accepted improvements* — merged and used, but they do not move a baseline row.

| lineage | approach family | notebook / branch | CV | public LB | promoted via | date |
|---|---|---|---|---|---|---|
| L0 | weak-label CNN (resnet18 + per-target attention over 12 windows) | `notebooks/baseline-v1.ipynb` / `main` | **0.6339** ± σ 0.0555 | pending | initial | 2026-09-13 |

### Measured facts from the smoke run (2026-09-13, Kaggle, CPU fallback)

| quantity | value | note |
|---|---|---|
| smoke macro AUC (120 studies, 1 seed) | **0.5637** | below the labeller's 0.6879 — expected at 1/30th of the training data; **not** a baseline |
| fold σ | **0.0657** → **2σ = 0.1314** | see the finding below |
| undefined (fold,label) cells dropped | **0 / 300** | the greedy stratifier balanced even 9-positive targets; the degenerate-cell risk did not materialise at 5 folds |
| training, cold decode | 123 s for epoch 1 vs ~85 s after | ⇒ DICOM decode ≈ **0.32 s/study** with 2 workers |
| inference | **2.01 s/study** (cold cache, CPU) | 5,000 hidden studies → 2.79 h, inside the 6.75 h limit |
| offline weights | loaded, 122 tensors, 0 missing, internet OFF | submission environment validated |

**Finding — gold CV tracks the public LB closely.** The random-init run scored **0.6039 macro AUC
on the 58 gold studies** and **0.595 on the public leaderboard** — a gap of 0.009, well inside σ.
On this single point, gold CV looks like a roughly unbiased estimator of LB, which is better news
than a 58-study validation set deserves. It does **not** shrink σ: the bar for calling a change
real is still ±2σ, and one agreeing point is not a calibration curve. Re-check it at the next
submission.

**Finding — σ is the binding constraint, not the model.** At smoke scale the significance bar is
**Δ > 0.13 AUC**. More data and more seeds will shrink it, but fold noise on 58 studies is
irreducible: a large part of it is *which patients* are in the fold. Consequences:
1. Small gains are **unprovable on gold alone**. The mandatory second signal in rules.md is not
   bureaucracy — it is the only way most experiments can be judged.
2. Prefer experiments with large expected effects (labels, input geometry) over tuning.
3. Consider adding weak-label agreement on held-out reported studies (n≈3,400) as the primary
   screening metric, with gold as the confirmation. **Proposed as `exp-20260913-04`.**

### Accepted improvements (inside a lineage, baseline unchanged)

| exp-id | lineage | Δ CV | closure % | LB | why it did not promote |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

## Ledger

| exp-id | date | type | change | hypothesis | baseline CV | new CV | Δ CV | public LB | lead ±1 | status |
|---|---|---|---|---|---|---|---|---|---|---|
| `exp-20260913-01-baseline-v1` | 2026-09-13 | paper | Build the baseline notebook: fixed-epoch training, gold never fitted, stratified fold σ, dropped-cell accounting, offline-safe, runtime instrumented | Produces a defensible yardstick + the 2σ bar | — | pending | — | — | n/a | built; smoke passed, full run blocked on GPU |
| `exp-20260913-01r-randominit` | 2026-09-13 | training | **Invalid as a baseline, kept as an ablation.** Full run whose attachments did not mount: backbone trained from **random init**, no prebuilt cache. 3 seeds x 4 epochs, all 3,406 weak studies | — | — | 0.6039 (σ 0.0537) | — | **0.595** (submitted 2026-09-13, notebook version 2) | n/a — invalid | done |
| `exp-20260913-01s-smoke` | 2026-09-13 | training | **Smoke run on Kaggle** (120 studies, 1 seed, 4 epochs, CPU fallback — P100 unusable). **NOT a baseline.** | Prove the chain runs in the real environment | — | 0.5637 | — | — | n/a | done |
| [`exp-20260913-02-labeller-es`](experiments/exp-20260913-02-labeller-es.md) | 2026-09-13 | data-analysis | Weak labeller misses Spanish `condropatía` / `cartílago` / `rotuliana`; only English `chondropath`/`cartilage loss` match. Spanish is the dominant report language | PF-OA coverage is 22.9% and Lateral OA 11.9%; closing Spanish OA vocabulary should lift coverage and therefore every downstream model | 0.6879 (labeller v1) | — | — | — | — | proposed |
| [`exp-20260913-03-coverage-ceiling`](experiments/exp-20260913-03-coverage-ceiling.md) | 2026-09-14 | paper | Ceiling analysis. Found the ceiling question ill-posed (noise caps sample efficiency, not AUC) and measured what does matter: the labeller's **pooled false-positive rate is 0.66 (CI 0.568–0.738)** while its miss rate is 0.02 | The labeller is a mention detector, not a classifier; OA/Synovitis labels are ~95% positive and carry almost no gradient | 0.6879 | n/a | n/a | n/a | **+1** | done |
| `exp-20260914-05-pretrain-ablation` | 2026-09-14 | paper | Paired comparison of the two runs we already have: pretrained (0.6339) vs random init (0.6039), using the saved `gold_probs_seed*.npy` — no GPU | Δ=+0.030 is only 0.27σ, so ImageNet pretraining is **not** provably worth anything here by our own bar. Paired cells will say it far more tightly than the marginal σ does | 0.6339 | — | — | — | — | proposed |
| `exp-20260914-06-inference-timing` | 2026-09-14 | packaging | Re-measure inference seconds with the test studies **excluded from the cache** | The 0.08 s/study this run reported is an artefact — the cache build included test UIDs, so "inference" read prebuilt tensors. The hidden test set will never be cached | — | — | — | — | — | proposed |
| `exp-20260913-04-screening-metric` | 2026-09-13 | split | Use agreement with weak labels on ~3,400 held-out reported studies as the *screening* metric, gold as confirmation | 2σ on gold is ~0.13 AUC — most experiments are unprovable there; a 3,400-study signal has far tighter error bars even though its labels are noisier | 0.6879 | — | — | — | — | proposed |

`type` ∈ `data-analysis` \| `split` \| `loss` \| `architecture` \| `training` \| `paper`
(`paper` = inferred without GPU spend).
`status` ∈ `proposed` \| `approved` \| `running` \| `done` \| `rejected` \| `abandoned (budget)`.

## Per-experiment entry template

Copy into `experiments/<exp-id>.md`:

```markdown
# exp-YYYYMMDD-NN-<slug>

- **Type:** loss | architecture | ...
- **Worktree:** /Users/vaibhavgandotra/RSNA-wt/exp-YYYYMMDD-NN-<slug>  (branch: same name)
- **Proposed by:** <agents>, from <discussion / notebook links>
- **Hypothesis:** ...
- **Mechanism:** why this should move the metric
- **Kill criterion:** what result makes this -1
- **Fix budget:** N attempts (per AGENTS.md §8) — used: 0
- **GPU estimate / actual:** Xh / Yh
- **Plan approved by Vaibhav:** yes/no, date

## Result
- CV (same folds/seeds as baseline): mean ± std
- Δ vs baseline, and 2×std(Δ) threshold
- Public LB (if submitted): score, submission date
- **Verdict:** +1 / -1

## Reviews
- Reviewer agent: ...
- Adjudicator sub-agent (differences in reasoning, required changes, likely failure mode): ...

## Inference
What we now believe that we did not believe yesterday. What this rules out.
What the next experiment should be.
```

## Daily rollup

| date | proposed | run | submitted | +1 leads | -1 leads | GPU h |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |
