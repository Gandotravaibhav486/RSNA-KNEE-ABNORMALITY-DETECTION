# Plan — `baseline-v1` (AGENTS.md §0 plan gate)

**Status:** awaiting Vaibhav's approval. Nothing here has consumed GPU time yet.
**Notebook:** [notebooks/baseline-v1.ipynb](../notebooks/baseline-v1.ipynb)

## Goal

Not to score well — to produce the **yardstick**: a defensible CV number, its σ, and the resulting
`2σ` significance bar that every later experiment is judged against, plus our own public-LB number.
Today both baseline cells in experiments.md read `UNKNOWN — blocking`, which blocks all other work.

## Hypothesis

A `resnet18` over 12 attention-pooled windows per study, trained on keyword weak labels, scores
meaningfully above the weak labeller alone (**measured: 0.6879 macro AUC on gold**) and well below
the public ensemble's reported 0.936. Expected landing zone **0.70–0.80**. If it lands at or below
0.69 the image model is adding nothing over the text rules, which is itself a finding worth having.

## Mechanism

Weak labels carry real signal (0.6879). The image model can only inherit and partially denoise them —
it cannot exceed the label ceiling except where image evidence disagrees with the report in a
systematic direction. This run measures where that ceiling sits.

## Staging — cost is CPU-dominated, so GPU is spent last

| Stage | `RUN_MODE` | Hardware | Est. cost | Output |
|---|---|---|---|---|
| 1. Smoke | `smoke` | CPU or GPU | ~15–25 min | proves the chain runs; 120 studies; no number to trust |
| 2. Cache build | `smoke` with `MAX_TRAIN_STUDIES` raised, **CPU-only notebook** | CPU | 2–5 h CPU, **0 GPU quota** | `cache_p1/` (~3 GB) saved as a Kaggle dataset |
| 3. Baseline | `full` (3 seeds × 4 epochs × 1200 studies) | GPU | **≈1.5 GPU h** | `baseline_v1_results.json`, the CV number and σ |
| 4. Submit | commit + submit once | GPU | ≈0.2 GPU h | our own public LB number |

**Total GPU: ≈1.7 h** of the ~24 h weekly budget (AGENTS.md §8). Stage 2 deliberately runs on a
CPU notebook so DICOM decoding does not bill GPU quota — it is the single biggest cost saving
available and it makes every later experiment cheaper, since the cache is reused.

## Expected delta

No delta — this *is* the reference. What it must produce: `baseline_cv`, `sigma`,
`significance_threshold_2sigma`, `dropped_cells`, `infer_seconds_per_study`.

## Kill criteria

- Stage 1 fails or any in-notebook test fails → fix before spending anything further (fix budget: 3).
- Backbone falls back to **random init** (no timm weights dataset attached) → **stop**; a
  random-init score is not a baseline. Attach weights and re-run.
- Stage 3 exceeds 1.5× its GPU estimate → stop and escalate (AGENTS.md §8 budget discipline).
- Inference extrapolates to >6.75 h at a plausible hidden-test size → the configuration is not
  submittable; reduce `N_TRIPLET` or `IMG` before submitting.

## Data touched

`train.csv` (reports + 58 gold labels), `train_series`/`test_series` metadata, DICOM under
`train_series/`. Gold studies are **prediction targets only** — never in a training batch,
never used to pick an epoch.

## Risks

1. **Cache size / session limits** — 4,407 studies of `[12,3,192,192]` uint8 is ~3 GB compressed.
   Mitigated by staging and the `CACHE_INPUT_DIRS` attach path.
2. **Pretrained weights offline** — the notebook falls back loudly rather than crashing, but the
   fallback invalidates the number. This is the most likely way to waste the run.
3. **σ may be large** — with 58 studies and 9 positives in the rarest target, the `2σ` bar could land
   near 0.05 AUC, which would make most small experiments unprovable. If so, that is a finding:
   it tells us to prioritise changes big enough to clear it, and to lean harder on the LB rank signal.

## Approval

- [ ] Vaibhav approves stages 1–2 (0 GPU)
- [ ] Vaibhav approves stage 3–4 (≈1.7 GPU h)
