# handoff.md — session handoff

Updated before the end of every long session (AGENTS.md §10). Overwrite "Current state";
append to "Log".

## Current state — 2026-09-14

**Lineage L1 is the baseline: gold CV 0.7642, public LB 0.803.** One label change did it.

| | value |
|---|---|
| **Lineage L1 gold CV** | **0.7642** (3 seeds; ensemble 0.7760) — public LLM label key |
| **L1 public LB** | **0.803** (submission 56235067) |
| Lineage L0 (regex labels) | CV 0.6339, LB 0.641 |
| Primary instrument | **screening metric v2: 2σ = 0.0068** (exp-04), 16× tighter than gold |
| Gold σ / bar | 0.0555 → Δ > 0.1110 (2σ) — confirmation set only now |
| Random-init ablation | CV 0.6039 → LB 0.595 |
| Weak labeller `v1-keyword` alone | 0.6879 on gold |
| GPU spent | 0.36 h valid run + 1.26 h on the invalid one |
| Deadline | **final submission 2026-10-22** — 38 days |

**CV tracks the LB, twice now:** 0.6039→0.595 and 0.6339→0.641. Gaps of 0.009 and 0.007, both well
inside σ. Two points is not a calibration curve, but gold CV is not lying to us about direction.

**The two results that should drive everything next:**
1. **Our label stage is the weak link, by a wide margin.** Our regex scores 0.6879 on gold; a
   competitor's regex scores 0.8136 and their LLM labels 0.8780 on the *same* 58 studies. The image
   model (0.6339) scores below the labeller it trains on.
2. **Our measuring instrument is 50× blunter than the field's.** Our 2σ bar is 0.1110 on 58 gold
   studies; a competitor reports a 0.0020 paired noise floor on 2,652 derived-OOF studies. Almost
   nothing we try is measurable until this is fixed.

## What the next session does, in order

1. **`exp-20260913-04` — screening metric.** Score against the ~3,400 held-out reported studies,
   with gold as confirmation only. Nothing below Δ=0.11 is measurable until this exists. Needs a
   plan (it is a `split`-type change) but little or no GPU.
2. **`exp-20260914-08` — attach a public LLM label set as lineage `L1`**, keeping our regex as the
   control. Public external data is allowed; candidates are listed in the findings doc.
3. **`exp-20260914-09` — per-finding treatment of silence.** Silence ⇒ negative for Baker's and
   Medial OA (gold-positive 0.03 / 0.00 when the report is silent); stays unknown for Synovitis
   (0.34). Blanket imputation is known to *lose* — do not generalise it.
4. **`exp-20260914-05`** — free paired pretrained-vs-random comparison from saved `gold_probs_*.npy`.
5. **`exp-20260914-06`** — re-measure inference seconds with test studies excluded from the cache.

Not next: architecture. A competitor measured DINOv2-S→B at +0.0011 against a 0.0020 floor, while a
crop-geometry fix paid +0.0059 across 10/12 labels.

## Assets on Kaggle (all attach via the CLI, no UI needed)

| what | ref |
|---|---|
| baseline notebook | `vaibhav486/rsna-knee-baseline-v1-full` (v4 = the valid run) |
| smoke notebook | `vaibhav486/rsna-knee-baseline-v1-smoke` |
| tensor cache `p1` | `vaibhav486/rsna-knee-cache-build-p1` — 4,410/4,410 studies, 4.84 GB, 0 errors |
| offline backbones | `vaibhav486/timm-backbones-offline` — resnet18/34, effnet_b0, convnext_tiny, Apache-2.0 |

## Hard-won environment facts (do not re-learn these)

- **Accelerator:** `kaggle kernels push --accelerator NvidiaTeslaT4`. Valid values are exactly
  `NvidiaTeslaT4` / `NvidiaTeslaP100` / `Tpu1VmV38`. Anything else is silently ignored and you get a
  **P100 (sm_60), which this PyTorch cannot use at all**. A CLI push overwrites the UI's choice.
- **Mount layout is nested:** `/kaggle/input/{datasets,notebooks,competitions}/<owner>/<slug>/…`,
  not flat. The notebook now discovers its inputs rather than assuming either layout.
- **`preflight()` is load-bearing.** A `full` run raises before epoch 1 if weights or cache are
  missing. Without it, a run trains from random init for an hour and logs a plausible score — that
  cost 1.26 GPU h once. A competitor reports hitting the identical bug.
- Kaggle exposes kernel logs only after a run completes; `kaggle kernels logs <ref>` prints JSON.
- Training is **decode-bound**: with a warm cache an epoch is ~50 s for 3,406 studies.
- Rules are already accepted (`userHasEntered: True`), so the 2026-10-15 entry deadline is safe.

## Open items

- `.claude/`, `.agents/`, `skills-lock.json` are untracked — track them or leave them?
- Still `[verify]` in rules.md: exact Efficiency-Prize formula, hidden test size, daily submission cap.
- We hardcode ImageNet `mean`/`std`. Fine for resnet18; a silent handicap the moment we swap
  encoders. Read `preprocessor_config.json` from the checkpoint instead.
- `exp-20260913-02` (Spanish OA vocabulary) is **rejected, not pending** — exp-03 showed it would add
  positives to targets that already have too many.

## Log

- **2026-09-14** — exp-03 run (0 GPU): the labeller is a mention detector — pooled false-positive
  rate 0.66 (CI 0.568–0.738) vs miss rate 0.02; OA/Synovitis decided cells are 5–8% negative. Killed
  exp-02 before running it. Read the competition discussions: our labeller is ~0.13 behind the
  field's regex; encoder scaling is a measured null; exp-04 independently validated. Queue reordered.
- **2026-09-14** — valid baseline on T4 (0.36 GPU h): CV 0.6339, σ 0.0555, 0/900 cells dropped.
  Submitted → **LB 0.641**. Earlier invalid run (random init, no cache) → CV 0.6039, LB 0.595.
- **2026-09-13** — built `notebooks/baseline-v1.ipynb` (fixed epochs, gold never fitted, stratified
  fold σ, dropped-cell accounting, offline weights, preflight, in-notebook tests) and
  `notebooks/cache-build-p1.ipynb`. Cache built: 4,410 studies, 0 errors, 0.56 h CPU.
- **2026-09-13** — created AGENTS.md, rules.md, experiments.md, agent-log.md, handoff.md; folded the
  official competition facts into rules.md; re-sized the fix budgets against the real GPU quota.
