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
| Baseline public LB | **0.641** (submission 56213958, notebook `rsna-knee-baseline-v1-full` v4). The 0.936 in the history is the copied public ensemble, not our pipeline. |
| Baseline commit | `notebooks/baseline-v1.ipynb` @ this commit; Kaggle notebook version 4; cache `p1`; labeller `v1-keyword` |
| Baseline notebook | **`notebooks/baseline-v1.ipynb`** (built 2026-09-13, all in-notebook tests pass, not yet run on GPU) |
| Weak labeller `v1-keyword` | **macro AUC 0.6879 on the 58 gold studies** — measured 2026-09-13, CPU only. This is the floor the image model must beat. |
| Date measured | 2026-09-13 (Kaggle, Tesla T4, 0.36 GPU h) |

**Baseline is measured.** Gold CV bar: **Δ > 0.1110 (2σ)** from the 900 evaluation cells of this run.

**The primary instrument is now the screening metric (exp-04, adopted 2026-09-14):** 3-fold OOF over
the 3,406 weakly-labelled studies, **2σ bar = 0.0182** — 6× tighter than gold. Gold remains the
confirmation set and the only thing measured against real annotations; the screening metric measures
agreement with weak labels and is for **ranking variants**, never for quoting a score.

| instrument | n | 2σ bar | cost |
|---|---|---|---|
| 58 gold studies | 58 | 0.1110 | free (rides along) |
| screening metric, regex key (v1) | 3,406 | 0.0182 | 0.22 GPU h per arm |
| **screening metric, L1 key (v2)** | 3,406 | **0.0068** | 0.22 GPU h per arm |
| public LB | hidden | ~unknown | 1 submission/day |

The v2 instrument is **16× tighter than gold**. The L1 key decides 40,850 cells against the regex
key's ~14,000, and decides them better — a sharper ruler as well as a longer one. Same known-answer
test passes: pretrained 0.7419 vs random init 0.6642, Δ +0.0777, CI [+0.0708, +0.0834].

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
| L0 | weak-label CNN, **regex labels** (resnet18 + per-target attention, 12 windows) | `notebooks/baseline-v1.ipynb` / `main` | 0.6339 ± σ 0.0555 | 0.641 | initial | 2026-09-13 |
| **L1** | same model, **public LLM label key** `llm_labels_v4_blend` | `notebooks/exp-08-llm-labels.ipynb` | **0.7642** ± σ 0.0459 (ensemble 0.7760) | **0.803** | **gate A: 35.6% CV closure, 45.1% on LB; confirmed on LB** | 2026-09-14 |

### Measured facts from the smoke run (2026-09-13, Kaggle, CPU fallback)

| quantity | value | note |
|---|---|---|
| smoke macro AUC (120 studies, 1 seed) | **0.5637** | below the labeller's 0.6879 — expected at 1/30th of the training data; **not** a baseline |
| fold σ | **0.0657** → **2σ = 0.1314** | see the finding below |
| undefined (fold,label) cells dropped | **0 / 300** | the greedy stratifier balanced even 9-positive targets; the degenerate-cell risk did not materialise at 5 folds |
| training, cold decode | 123 s for epoch 1 vs ~85 s after | ⇒ DICOM decode ≈ **0.32 s/study** with 2 workers |
| inference | **2.01 s/study** (cold cache, CPU) | 5,000 hidden studies → 2.79 h, inside the 6.75 h limit |
| offline weights | loaded, 122 tensors, 0 missing, internet OFF | submission environment validated |

**Finding — gold CV tracks the public LB, on both points we have.**

| run | gold CV | public LB | gap |
|---|---|---|---|
| random-init ablation | 0.6039 | 0.595 | −0.009 |
| baseline L0 (pretrained + cache) | 0.6339 | 0.641 | +0.007 |
| **L1 (LLM labels)** | 0.7642 | **0.803** | **+0.039** |

The ordering holds — three for three — but **the offset is not constant**, and the third point breaks
the ±0.01 band the first two suggested. Do not use "LB ≈ CV" as a predictor. A plausible reason: the
58 gold studies are the annotator's sampling, not the disease distribution (every gold study has at
least one positive, mean 4.14 findings per study), so gold is a harder and differently-balanced set
than the hidden test. Under that reading, CV *understates* LB and understates it more as the model
gets better — which would mean our 2σ gold bar is even more conservative than it looks.

Treat CV as a direction indicator, not a level predictor. Levels come from the LB, one per day.

Note what the pair also says about pretraining: **+0.030 on CV, +0.046 on the LB**, and the LB is
scored on far more studies than 58. By our own 2σ rule the CV gain is "unprovable", yet the larger
test set agrees with it. That is an argument about the instrument, not about pretraining — and it is
the case for `exp-20260913-04`.

**Finding — pairing is worth 4× the sample size, and costs nothing.** exp-11 vs the L1 baseline on
the same 58 gold studies: the *marginal* gold bar is 0.1110, but a **paired** bootstrap over the same
studies with both runs' saved `gold_probs_*.npy` gives σ(Δ)=0.0127, i.e. a bar of **0.0254** — 4.4×
tighter, for zero GPU. Every future comparison should be paired from saved predictions before anyone
argues about a marginal number. (It still was not enough here: Δ=+0.0154, CI [−0.0081, +0.0410],
P(Δ>0)=0.89.)

**Finding — the epoch decline was a label-noise artefact, and it vanished with clean labels.**

| epochs | L0 regex labels | L1 LLM labels |
|---|---|---|
| 2 | — | 0.7264 |
| 4 | **0.6333** | **0.7699** |
| 8 | 0.6127 | 0.7492 |
| 12 | 0.5998 | 0.7792 |

Under L0 the curve falls monotonically — textbook memorisation of label noise. Under L1 the decline
is **gone**, but what replaces it is not a rising curve, it is a **jagged one**: 4 and 12 epochs are
within 0.009 of each other with an 8-epoch dip between them. Single seed per arm, gold σ ≈ 0.046 →
gold cannot resolve this, and the honest verdict is "no reason to pay 3× GPU for 12 epochs".
The mechanism claim survives; the schedule question moves to the screening metric (exp-15).

**Finding — the model was never undertrained; it was overfitting noisy labels.** exp-10 swept
4/8/12 epochs on the L0 regex labels and gold CV fell *monotonically*: 0.6333 → 0.6127 → 0.5998.
Training loss kept dropping the whole time. With a labeller whose pooled false-positive rate is 0.66
(exp-03), extra epochs buy a better fit to the *noise*. This kills the "train longer" family of
experiments under L0 and reframes them under L1 (exp-13), where the labels are much cleaner and the
optimum may genuinely sit past 4 epochs.

**Finding — σ is the binding constraint, not the model.** At smoke scale the significance bar is
**Δ > 0.13 AUC**. More data and more seeds will shrink it, but fold noise on 58 studies is
irreducible: a large part of it is *which patients* are in the fold. Consequences:
1. Small gains are **unprovable on gold alone**. The mandatory second signal in rules.md is not
   bureaucracy — it is the only way most experiments can be judged.
2. Prefer experiments with large expected effects (labels, input geometry) over tuning.
3. Consider adding weak-label agreement on held-out reported studies (n≈3,400) as the primary
   screening metric, with gold as the confirmation. **Proposed as `exp-20260913-04`.**

**Community benchmark (from [discussion findings](experiments/discussion-findings-20260914.md), 2026-09-14).**
Measured by other competitors against the same 58 gold studies: their regex labeller scores
**0.8136**, their LLM labeller **0.8780**, ours **0.6879**. Our label stage is ~0.13 behind the
field's *non-LLM* baseline. Public LLM label sets exist and external public data is allowed.
Separately, they measure encoder scaling (DINOv2-S→B) at +0.0011 against a 0.0020 noise floor —
capacity is not the constraint; a crop-geometry fix paid +0.0059 and moved 10/12 labels.

**exp-08 gate 1 — public LLM label keys scored against our 58 gold studies (CPU, 2026-09-14):**

| key | macro AUC | cells left at 0.5 |
|---|---|---|
| our `v1-keyword` regex | 0.6879 | 65.2% undecided |
| `llm_labels_full` | 0.8780 | 26.6% |
| `llm_labels_v2` | 0.8873 | 21.0% |
| **`llm_labels_v4_blend`** | **0.8927** | 0.0% |

Per-target gain of v4_blend over our regex — **every target improves**, smallest +0.019:
PF OA +0.336, Medial Meniscus +0.315, MCL +0.274, ACL +0.263, Effusion +0.237, Contusion +0.195,
Lateral OA +0.183, Lateral Meniscus +0.180, Medial OA +0.177, Baker's +0.147, Synovitis +0.132,
Fracture +0.019.

MCL — the target our model scores 0.365 on and which exp-03 could not diagnose — goes 0.694 → 0.968
in the label key alone.

### Accepted improvements (inside a lineage, baseline unchanged)

| exp-id | lineage | Δ CV | closure % | LB | why it did not promote |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

## Dependency tree — what can run at once, and what must wait

An edge means **"the result cannot be interpreted without the parent"**, not merely that one runs
before the other. Independent roots can be pushed simultaneously (`scripts/exp.sh push`, AGENTS.md §9).

```
exp-08  LLM labels ............ root, independent    [CPU label build + 0.4 GPU h]
  └── exp-09  silence policy ... also needs exp-04
  └╌╌ exp-07  regex precision .. ONLY if exp-08 fails or is disallowed

exp-04  screening metric ...... root, running        [0.48 GPU h]
  ├── exp-09  silence policy ... effect ≈0.01, invisible on gold
  ├── exp-10  epoch sweep ...... effect likely <2σ gold
  └── exp-11  geometry ......... also needs exp-06

exp-06  runtime truth ......... root, independent    [~0 GPU]
  └── exp-11  geometry ......... more windows costs runtime; Efficiency Prize scores it
```

**Why exp-08 is a root and everything else is not.** A label change from 0.6879 → 0.8780 is a
+0.19 effect on label quality. That is the one queued experiment plausibly large enough to clear the
gold set's 2σ bar of 0.1110 on its own, so it does not need the new instrument to be readable.
Everything else is expected to move the metric by 0.005–0.05 — invisible on gold, hence the edge
from exp-04.

**Why exp-09 has two parents.** It modifies *whichever* label set is in use, so its content depends
on exp-08's outcome (our regex's unknowns, or the LLM key's "not addressed" cells), and its effect
(~+0.009 measured by a competitor) is far too small to read on gold, so it also needs exp-04.

**Why exp-10 is not a parent of exp-08/09.** Epochs and labels are orthogonal changes. But there is
a weaker coupling worth stating: if the model is undertrained at 4 epochs, a label improvement
evaluated at 4 epochs under-reads. Run exp-10 early for that reason, but it does not gate.

**Resolved nodes:** exp-03 done (+1). exp-02 rejected on exp-03's evidence. exp-05 **absorbed** —
exp-04 *is* the paired pretrained-vs-random comparison, run properly out-of-fold.

**Parallel batch that can start today:** exp-08's label build (CPU), exp-06 (CPU), and exp-10 (GPU)
are mutually independent. exp-04 is already running and gates the reading of exp-10.

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
| [`exp-20260913-04-screening-metric`](experiments/exp-20260913-04-screening-metric.md) | 2026-09-14 | split | 3-fold OOF over 3,406 weak studies as the screening metric. **Adopted.** | Gold's 2σ bar of 0.1110 cannot see effects the LB proves real | — | see below | — | — | **+1** | done |

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
