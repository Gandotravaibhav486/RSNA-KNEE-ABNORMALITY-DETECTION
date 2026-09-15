# handoff.md — session handoff

Updated before the end of every long session (AGENTS.md §10). Overwrite "Current state";
append to "Log".

## Current state — 2026-09-16

**Best measured config: L1 labels + p2 geometry — gold CV 0.7794 (ensemble 0.7914).**
Best *confirmed on the leaderboard*: L1 at **0.803**. The p2 submission is pending.

| | value |
|---|---|
| **Lineage L1** (public LLM label key) | gold CV 0.7642 · screening 0.7419 · **LB 0.803** |
| **+ p2 geometry** (accepted improvement, not a promotion) | gold CV **0.7794** (ens 0.7914) · screening **0.7501** · LB pending |
| L0 (regex labels) | CV 0.6339 · LB 0.641 |
| Bars: gold marginal / gold paired / screening paired | 0.1110 / 0.0254 / **0.0044** |
| Honest inference cost at p2 | **3.69 s/study** → 5.13 h at 5,000 hidden studies (cap 9 h, working limit 6.75 h) |
| GPU used | ≈6.4 h of ~24 h/week |
| Deadline | **2026-10-22** — 36 days |

## In flight

- `exp-17-t2-independent-flips` — running. Screened at p2, paired against exp-16's OOF.
- Submission **56261446** — p2 geometry, real predictions, pending. The fourth CV/LB point.
- Submissions 56261421 / 56261500 — screening notebooks with no inference cell; these score 0.500
  and carry no information.

## Version axes — read this before comparing any two numbers

- `PREPROC_VERSION` `p1` (3 slots × 4 windows @192, K=12) / `p2` (6 slots × 3 @224, K=18). Keys the
  tensor cache.
- `TRAIN_VERSION` `t1` / `t2` — new 2026-09-16. Keys the *training stream*. t2 fixes the flip RNG;
  cached tensors are identical, so `p2/t2` is **not** comparable to `p2/t1`.
- Lineage `L0` regex labels / `L1` public LLM key.

## What we know, in the order it should drive decisions

1. **Labels were the binding constraint.** Regex 0.6879 → LLM key 0.8927 on gold moved CV +0.1303
   and LB +0.162. Nothing else changed. 35.6% CV / 45.1% LB error-gap closure → L1 promoted.
2. **Measure paired, always.** On the same 58 gold studies the marginal bar is 0.1110 and the
   **paired** bar is 0.0254 — 4.4× tighter, for zero GPU, just from keeping `gold_probs_*.npy`.
   On the screening pool, paired gives **0.0044**.
3. **Geometry is real but small.** 18 windows @224 vs 12 @192: +0.0154 on gold (unresolvable) and
   **+0.0082 paired on the screening metric, CI [+0.0041, +0.0125], P=1.00** → +1. It costs 2.4× the
   training GPU and ~1.5 h more inference headroom.
4. **The model overfits noisy labels rather than underfitting.** Epochs 4→12 on L0: 0.6333 → 0.5998,
   monotone down. On L1 the decline vanishes but no schedule wins — jagged, single seed, unresolved.
5. **An LLM label prompt needs a cost on "not addressed".** Our own key (exp-12) answered "not
   addressed" for 74.9% of cells (public key 25.4%) and scored 0.7125 — killed on two criteria.
6. **CV predicts direction, not level.** CV/LB gaps: −0.009, +0.007, +0.039 and widening.

## Queue

1. **Read exp-17.** If Δ < 0.0044, adopt t2 anyway — it is a correctness fix; just don't claim a gain.
2. **exp-09 per-finding silence** — silence ⇒ negative for Baker's / Medial OA (gold-positive 0.03 /
   0.00 when silent), unknown for Synovitis (0.34). Never blanket: the community measured blanket
   imputation *losing* 0.0068.
3. **Confidence-weighted loss** — the L1 key is soft; `2·|p−0.5|` sends "not addressed" cells to zero
   weight automatically. Cheap, untested, inside L1.
4. **exp-15 epochs on the screening metric** — 4 vs 12 at p2/t2, since gold could not resolve it.
5. **Split training out of the submission notebook** — publish weights as a dataset so the rerun only
   infers. Saves ~0.7 h of rerun time, makes the submitted artefact exactly the measured one, and
   matters for the Efficiency Prize.
6. **exp-14, our own label key, reopened** — only with prompt v2 (a cost on "not addressed") *and*
   batched generation. Must beat 0.80 on gold-test in a pilot. 1 of 3 fix attempts used.

## Traps already paid for — do not rediscover these

- **`kaggle kernels output` skips files that already exist locally.** A re-fetch after a new version
  silently keeps the old artefacts; this produced a paired estimate 12× too large, caught only
  because the number was implausible. `exp.sh fetch` now clears first.
- **Submitting a screening notebook wastes a slot** — no inference cell means `submission.csv` is the
  0.5 fallback. Check it is not constant before submitting. (Cost two slots so far.)
- `--accelerator NvidiaTeslaT4` is the only usable GPU enum; anything else silently gives a P100
  (sm_60) this PyTorch cannot run on, and a CLI push overwrites the UI's choice.
- **2 concurrent batch GPU sessions.** CPU pushes are exempt; `exp.sh queue` waits for a slot.
- Mounts are nested: `/kaggle/input/{datasets,notebooks,competitions,models}/<owner>/<slug>/…`.
- Kernel logs appear only after a run completes.
- `preflight()` and `scripts/lint_nb.py` exist because **every failure so far died after the
  expensive part**, never before it.
- Determinism holds *within* an accelerator (exp-08 and exp-13 both produced 0.7699 for seed 2026)
  but not across devices (CPU 0.5637 vs T4 0.5728). `cudnn.deterministic` is **not** set.

## Assets on Kaggle

| what | ref |
|---|---|
| L1 baseline | `vaibhav486/rsna-knee-exp-08-llm-labels` |
| L1 + p2 geometry | `vaibhav486/rsna-knee-exp-11-geometry-p2` |
| screening metric (p1 / p2) | `…exp-04-screening-metric` / `…exp-16-screen-p2` |
| tensor caches | `…cache-build-p1` (4,410 studies, 4.84 GB) · `…cache-build-p2` (4,407 train-only, 8.0 GB) |
| offline backbones | `vaibhav486/timm-backbones-offline` (Apache-2.0) |
| public label key | `stevenleehans/rsna-knee-llm-report-labels` (CC0) |

## Open items

- The L1 key's prompt and model are unpublished — we cannot reproduce or extend what the baseline
  now depends on. Relevant to the winners' open-source obligation.
- We hardcode ImageNet `mean`/`std`; read `preprocessor_config.json` before swapping encoders.
- Still `[verify]`: Efficiency-Prize formula, hidden test size, daily submission cap.
- `.claude/`, `.agents/`, `skills-lock.json` untracked.

## Log

- **2026-09-16** — exp-16 **+1** (geometry confirmed, +0.0082 paired on the screening metric);
  exp-11 promoted to +1; p2 submitted (pending). exp-17 `t2-independent-flips` launched and the
  `TRAIN_VERSION` axis introduced. Fixed the stale-fetch trap in `exp.sh`.
- **2026-09-15** — exp-13 −1 (epoch decline was label noise; vanishes under L1, no schedule wins).
  exp-12 −1 (own LLM key: 0.7125, 11.7 h corpus, 74.9% "not addressed"). cache p2 built. exp-11 run.
- **2026-09-14** — **exp-08 +1 → L1** (CV 0.7642, LB 0.803). exp-04 +1, screening metric adopted.
  exp-10 −1. exp-03 +1 (killed exp-02 unrun). Discussions read; `exp.sh` and the notebook lint built.
- **2026-09-13** — baseline L0 measured (CV 0.6339, LB 0.641); cache p1 built; governance docs written.
