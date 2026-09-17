# handoff.md — session handoff

Updated before the end of every long session (AGENTS.md §10). Overwrite "Current state";
append to "Log".

## Current state — 2026-09-17

**Baseline `b1` — gold CV 0.8319 · public LB 0.824.** One notebook,
[`notebooks/baseline.ipynb`](notebooks/baseline.ipynb): L1 labels, p2 geometry, t2 flips,
12 epochs x 3 seeds, resnet18 @224. Every experiment since is a set of config overrides on it
(AGENTS.md §14) — never a copy.

| | value |
|---|---|
| **b1** (p2 · t2 · 12 ep · 3 seeds) | gold **0.8319** · **LB 0.824** |
| previous LB points | L0 0.641 → L1 0.803 → +p2 geometry 0.808 → +12 epochs **0.824** |
| Bars: gold marginal / gold paired / screening paired | 0.1110 / 0.0254 / **0.0044** |
| Inference at p2 | 3.69 s/study → 5.13 h at 5,000 hidden studies (cap 9 h, working limit 6.75 h) |
| GPU used | ≈19 h cumulative (≈24 h/week budget) |
| Deadline | **2026-10-22** — 35 days. Final submissions chosen: **0 of 2** |

## In flight

- `exp-25-p4-uniform22` — running. Read it **only as a 4-epoch finding** (count vs distribution);
  its premise died when p3's gain failed to survive 12 epochs, so it does not inform b1.
- Nothing else running. Nothing queued without approval (AGENTS.md §0).

## The three lines that are now closed

1. **Schedule.** 4 → 0.7914, **12 → 0.8319**, 20 → 0.8316 (exp-27, paired CI [−0.0270, +0.0245]).
   Flat by 12. 12 epochs stays; do not re-open without a different reason than "more".
2. **Geometry/window count.** p3 (22 windows, sagittal-weighted) screened **+0.0179 at 4 epochs**
   and **−0.0158 at 12** (exp-26) with a ±0.0218 seed spread. Not adopted. The lesson is procedural:
   **a screening result at one training length does not transfer to another** — screen at the length
   you will train at.
3. **Ensembling.** exp-21: their single CoAtNet v5 scores **0.9205** on our 58 gold studies, their
   5-model ensemble 0.9118, our 3-seed ensemble 0.7914. More models is not the lever.

## What the open gap actually is

The public 0.936 is **a stronger single model at 384 px**, not an ensemble and not a schedule.
Our shortfall is 0.098 gold against one of their branches. Per-label headroom against our own
label ceiling is **0.065 of macro AUC**, concentrated in MCL 0.199, Lateral Meniscus 0.119,
ACL 0.114 — focal structures. Effusion and Medial OA already exceed the key: for those the **label
key**, not the model, binds.

**The untested direction is resolution.** → `exp-28` (below), the first 384 px experiment.
The constraint that shapes it: at 384 with b1's 18 windows, inference is ≈10.8 s/study ≈ **15 h**
at 5,000 studies — over the 9 h cap. Resolution has to be bought at a fixed pixel budget, not added.

## Version axes — read this before comparing any two numbers

- `PREPROC_VERSION` — `p1` (3 slots × 4 @192, K=12) · **`p2` (6 × 3 @224, K=18 — b1)** ·
  `p3` (asymmetric, K=22) · `p4` (uniform, K=22) · **`p5` (6 × 1 @384, K=6 — new, for exp-28)**.
  Keys the tensor cache.
- `TRAIN_VERSION` — `t1` / **`t2`** (independent flip RNG, correctness fix). Cached tensors are
  identical, so `p2/t2` is **not** comparable to `p2/t1`.
- `BASELINE_VERSION` — **`b1`**. Bumps only on the §13.1 promotion gate: ≥20% error-gap closure, or
  an approach so different it needs its own baseline.
- Lineage `L0` regex labels / **`L1`** public LLM key.

## Queue

1. **`exp-28-res384`** — resolution at constant pixel budget, plan written, **awaiting approval**.
   See [plans/exp-28-res384.md](plans/exp-28-res384.md). Needs one CPU cache build (p5) first.
2. **exp-19 split train/infer** — publish weights as a dataset so the submission notebook only
   infers. ~0.7 h of rerun saved, the submitted artefact becomes exactly the measured one, and it
   matters for the Efficiency Prize.
3. **exp-14, our own label key** — only with prompt v2 (a cost on "not addressed") *and* batched
   generation; must beat 0.80 on gold-test in a pilot. 1 of 3 fix attempts used. Relevant to the
   winners' open-source obligation, since the L1 key's prompt is unpublished.
4. **Final submission selection** — 0 of 2 chosen. b1 at 0.824 is the floor; nothing has beaten it.

## Traps already paid for — do not rediscover these

- **`kaggle kernels output` skips files that already exist locally.** A re-fetch after a new version
  silently keeps the old artefacts; this produced a paired estimate 12× too large, caught only
  because the number was implausible. `exp.sh fetch` now clears first.
- **Copy-patching notebooks is what broke us**, not modelling: a regex that deleted half a config
  cell, a variant missing the `preflight` it called, a screening notebook missing two imports that
  died after six folds. Hence §14 and `exp.sh run '<json>'`.
- **Submitting a screening notebook wastes a slot** — no inference cell means `submission.csv` is the
  0.5 fallback. Check it is not constant before submitting. (Cost two slots.)
- **Never arm an automatic submit on file validity alone** — it would have submitted exp-26, which
  is below baseline. Gate on the score, or submit by hand.
- `--accelerator NvidiaTeslaT4` is the only usable GPU enum; anything else silently gives a P100
  (sm_60) this PyTorch cannot run on, and a CLI push overwrites the UI's choice.
- **2 concurrent batch GPU sessions, account-wide** — other projects' kernels count. `exp.sh queue`
  retries on push refusal rather than counting our own kernels.
- Mounts are nested: `/kaggle/input/{datasets,notebooks,competitions,models}/<owner>/<slug>/…`.
  Kernel logs appear only after a run completes.
- Determinism holds *within* an accelerator, end to end through a full retrain (exp-11 submitted
  twice, 0.808 both times), but not across devices. `cudnn.deterministic` is **not** set.

## Assets on Kaggle

| what | ref |
|---|---|
| **b1** | `vaibhav486/rsna-knee-exp-23-p2-t2-ep12` |
| earlier LB points | `…exp-08-llm-labels` (0.803) · `…exp-11-geometry-p2` (0.808) |
| screening metric (p1 / p2) | `…exp-04-screening-metric` / `…exp-16-screen-p2` |
| tensor caches | `…cache-build-p1` (4.84 GB) · **`…cache-build-p2` (4,407 train-only, 8.0 GB)** · `…cache-build-p3` (11.58 GB) · `…cache-build-p4` |
| offline backbones | `vaibhav486/timm-backbones-offline` (Apache-2.0) |
| public label key | `stevenleehans/rsna-knee-llm-report-labels` (CC0) |

## Open items

- The L1 key's prompt and model are unpublished — we cannot reproduce or extend what the baseline
  depends on.
- We hardcode ImageNet `mean`/`std`; read `preprocessor_config.json` before swapping encoders.
- Still `[verify]`: Efficiency-Prize formula, hidden test size, daily submission cap.
- `.claude/`, `.agents/`, `skills-lock.json` untracked.

## Log

- **2026-09-17** — exp-27 **null** (20 epochs 0.8316 vs 12 epochs 0.8319; the schedule line closes).
  exp-26 **−1** (p3's +0.0179 at 4 epochs became −0.0158 at 12 — screening must match training
  length). AGENTS.md §14 adopted: one versioned baseline, experiments as config overrides.
  `exp-28-res384` written and submitted for approval; cache builder p5 added.

- **2026-09-16** — exp-16 **+1** (geometry confirmed, +0.0082 paired on the screening metric);
  exp-11 promoted to +1; p2 submitted (pending). exp-17 `t2-independent-flips` launched and the
  `TRAIN_VERSION` axis introduced. Fixed the stale-fetch trap in `exp.sh`.
- **2026-09-15** — exp-13 −1 (epoch decline was label noise; vanishes under L1, no schedule wins).
  exp-12 −1 (own LLM key: 0.7125, 11.7 h corpus, 74.9% "not addressed"). cache p2 built. exp-11 run.
- **2026-09-14** — **exp-08 +1 → L1** (CV 0.7642, LB 0.803). exp-04 +1, screening metric adopted.
  exp-10 −1. exp-03 +1 (killed exp-02 unrun). Discussions read; `exp.sh` and the notebook lint built.
- **2026-09-13** — baseline L0 measured (CV 0.6339, LB 0.641); cache p1 built; governance docs written.
