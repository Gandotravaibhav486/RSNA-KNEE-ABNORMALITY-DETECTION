# exp-20260913-03-coverage-ceiling

- **Type:** paper (0 GPU) · **Fix budget:** 3 · **Plan gate:** not required
- **Run before exp-02** — it decides whether exp-02 is worth doing.

## Question

For each target, if the image model learned the weak labels *perfectly*, what macro AUC would it
reach? That is the ceiling imposed by the labels, and it separates two very different diagnoses for
a weak target: the labels are too thin (fix labels) vs. the labels are fine and the model is not
using them (fix the model).

## Method

On the 58 gold studies we know both the truth and what the labeller said, so per target we can
measure the weak label's precision, recall and coverage. Then, for each target, simulate a learner
that reproduces the weak labels exactly on the 4,349 reported studies and score that simulation
against gold. Report the ceiling next to the measured model AUC and the gap between them.

## Success / failure

| Verdict | Condition |
|---|---|
| **Success (+1)** | Produces a per-target ceiling **with stated uncertainty**, and the ceiling-vs-actual gap **reorders the experiment queue** — i.e. at least one target moves between "label-limited" and "model-limited", changing what we build next. |
| **Success, null result** | Ceilings come back uniformly close to the measured AUCs. That is a real answer: labels are not the binding constraint, and priority shifts to the model. Still `+1` — it redirects the budget. |
| **Failure (−1)** | The estimate's uncertainty is wider than the gaps it is meant to resolve, so no target can be classified either way. Record why (almost certainly n=58 per target), and stop. |
| **Invalid** | Ceiling computed on studies the labeller had already been tuned on, or precision/recall estimated without accounting for the "unknown" cells. |

**This experiment produces no CV number, so the ±2σ rule in AGENTS.md §13 does not apply to it.**
Its output is a decision, and it is judged on whether the decision is well-supported.

## Kill criterion

If per-target positive counts (9–35) make every ceiling estimate span more than ±0.15 AUC,
abandon the per-target framing and report only the macro-level conclusion.


---

# RESULT — run 2026-09-14, CPU only, 0 GPU

Notebook: [`notebooks/exp-03-coverage-ceiling.ipynb`](../notebooks/exp-03-coverage-ceiling.ipynb)
(config, loader and the frozen `v1-keyword` labeller cells copied verbatim from `baseline-v1.ipynb`).

## Verdict: **+1** — the queue changes, and the experiment I was about to run next was wrong.

### 1. The ceiling question was ill-posed, and that is itself the result

"What AUC would a model reach if it learned the weak labels perfectly?" is **1.0 for every target**.
AUC scores *ranking*, and a perfect learner of `P(weak=1 | image)` ranks by a monotone transform of
`P(true=1 | image)` whenever label noise is independent of the image. Independent label noise does
not cap AUC — it costs sample efficiency. The answerable question is how much *effective* signal
each target carries, and how the noise is **structured**.

### 2. The labeller is not a classifier — it is a mention detector

Pooled over all 12 targets, counting only cells the labeller claimed to decide (n is large enough
here to quote, unlike any single target):

| | rate | 95% CI |
|---|---|---|
| says **positive** when the truth is negative | **0.66** | (0.568, 0.738) |
| says **negative** when the truth is positive | **0.02** | (0.004, 0.054) |

Near-perfect recall, terrible precision. Two thirds of its positive calls on truly-negative studies
are wrong, while it essentially never misses a true positive. Share of decided cells it calls
negative, per target: **Medial OA 5.0%, Lateral OA 5.3%, PF OA 6.6%, Synovitis 7.8%** — versus
Fracture 66.6%, Lateral Meniscus 56.8%.

For the OA and Synovitis targets the training label is ~95% positive. **A near-constant label
carries almost no gradient signal**, and those four targets include three of the four worst model
AUCs (PF OA 0.537, Synovitis 0.533, Lateral OA 0.598).

### 3. Effective positives per target (`weak_pos × (1 − e10 − e01)²`)

Effusion 230, Baker's 242, Fracture 123, Lateral Meniscus 99, Medial Meniscus 81, ACL 74,
PF OA 59, MCL 44, Contusion 27, and **Medial OA / Lateral OA / Synovitis ≈ 0**.

Correlations with model AUC across the 12 targets: coverage ρ=+0.62 (p=0.033),
weak positives ρ=+0.61 (p=0.036), n_eff ρ=+0.56 (p=0.056). With n=12 these are **suggestive, not
established** — reported as measured, not as a story. `pos_rate` alone shows nothing
(ρ=−0.06, p=0.85); the mechanism is not a simple monotone function of positive share.

## What this changes

**`exp-20260913-02` as written would have made things worse.** Adding Spanish OA vocabulary raises
*coverage* — it adds more **positive** calls to three targets whose labels are already 95% positive
and whose false-positive rate is the highest we measured. More of a broken signal is not better.

**Rewrite it as a precision experiment.** The lever is teaching the labeller to emit **0**: detect
normality and negation for OA and Synovitis ("cartílago conservado", "sin signos de artrosis",
"no synovitis", "espacio articular preservado"), so decided-negative share rises from ~5% toward the
30–60% the meniscus and fracture targets already show. Coverage is the *secondary* metric now;
**decided-negative share and pooled precision are primary**.

## Caveats that this analysis cannot settle

1. **Image-correlated bias.** Radiologists report findings when severe, so "mentioned" ≈ "severe".
   That is a genuine ceiling and needs gold-vs-weak disagreement cases, not arithmetic.
2. **Gold n.** Per-target error rates rest on 1–19 covered negatives; only the pooled rates are
   quotable. `Medial OA e01 = 1.00` is one study.
3. The e10 ≈ 0.02 figure is flattering by construction: a labeller that rarely says 0 rarely says 0
   wrongly.
