# handoff.md — session handoff

Updated before the end of every long session (AGENTS.md §10). Overwrite "Current state";
append to "Log".

## Current state — 2026-09-18

**Baseline is still `b1` — gold 0.8319 / LB 0.824** — but it is about to be challenged. The
programme's binding constraint turned out to be **the encoder**, and the replacement is measured but
not yet promoted.

| | value |
|---|---|
| **b1** (p2 · t2 · 12 ep · 3 seeds · resnet18 @224) | gold **0.8319** · **LB 0.824** |
| **exp-29 convnext_tiny**, same everything else | screening **0.8105** vs b1's 0.7550 = **+0.0556 paired**, CI [+0.0502, +0.0616], P=1.000, **12/12 targets up** |
| Bars: gold marginal / gold paired / screening paired | 0.1110 / 0.0254 / **0.0044** |
| GPU | **weekly quota (30 h, account-wide) exhausted 2026-09-18**; resets ~06:30 local on the 19th |
| Deadline | **2026-10-22** — 34 days. Final submissions chosen: **0 of 2** |

## In flight / armed

- **`scripts/await_quota.sh` is running in the background.** It retries exp-32 **stage 0**
  (`{"LR_BACKBONE": 5e-05}`, screened — the LR control) and then **stage 1**
  (`{"BACKBONE": "convnext_tiny", "LR_BACKBONE": 5e-05}`, the full gold run) every 15 minutes until
  the quota resets. Both were approved by Vaibhav on 2026-09-18. Log: `results/await_quota.log`.
  **If the machine slept through the reset, the loop died with it — check that log first and push
  by hand.**
- **Cache p5 is built** (4,407 studies, 6.87 GB, 0 errors, 0.58 h CPU) — exp-28 is unblocked but
  still held.
- **PR #1 is open** against `main` with everything through 2026-09-18, awaiting a title and body
  (prepared text was handed over separately). `gh` is not installed on this machine, so the PR
  cannot be edited from here.

## The one finding that reorganises everything else

**Capacity was the binding constraint, and every architecture result before exp-29 was measured at
the wrong learning rate.** convnext_tiny at `LR_BACKBONE = 5e-05`, with b1's geometry, windows and
schedule unchanged, gains **+0.0556** on the screening metric — 12.6× the paired bar and the largest
effect since the label swap. Gains land where the headroom was: Baker's +0.107, Medial Meniscus
+0.103, ACL +0.099, Lateral Meniscus +0.080. **MCL is the exception at +0.014** and remains the
hardest target in the competition for us.

This reframes three earlier verdicts:

- **exp-22 (DINOv2, −0.1128) was a recipe failure, not a capacity result.** Same class of swap,
  resnet18's LR of 1e-04, opposite outcome. → hence stage 0, which decomposes encoder from LR.
- **exp-21 was right**: the gap is a stronger single model, and it costs one config line.
- **Geometry (exp-24/25/26) and schedule (exp-13/15/27) saturated** because the encoder was the
  constraint the whole time. Those lines are closed, but they were closed *against a weak encoder* —
  if convnext becomes b2, **the schedule and geometry questions are open again at the new capacity**
  and must be re-screened rather than assumed.

## What is NOT true, corrected on 2026-09-18

- **Rank averaging is not a free gain.** +0.0021 on exp-11's seeds, **−0.0016** on b1's (exp-31).
  It was n=58 noise and should never have been carried as a finding.
- **Flip TTA does nothing**: −0.0007, CI [−0.0118, +0.0091], at double the inference cost. Dropped.
- The seed ensemble itself **is** real: +0.031 over a single checkpoint.

## Runtime, now that the leaderboard tab has been read

**30% public / 70% private of the same test data.** The notebook runs **once** over the whole hidden
test set and both scores come from that one predictions file — so there is **no larger private rerun
at the deadline**, and a submission that completes today carries no extra runtime risk later.

- **9 h is Kaggle's hard cap**: over it the rerun is killed and the submission **scores nothing** on
  either board. No partial credit.
- **6.75 h is ours** and unenforced. A run between the two scores normally. The headroom covers the
  unpublished hidden test size, hardware variance, and cold-cache cost — and the fact that a timeout
  consumes one of two final-selection slots and returns nothing.
- **b1's completed rerun already bounds the hidden test size.** Reading its execution time off the
  Submissions tab would turn the last `[verify]` into a number. Not yet done.

## The blocker on promoting convnext

**b1's submission notebook trains from scratch during the rerun.** That was affordable at 2.25 h.
convnext is **2.8× per epoch** (191 s vs 69 s), so training (~6.3 h) plus inference exceeds 9 h.
**exp-19, the train/infer split, stops being optional** — it is stage 2 of
[plans/exp-32-b2-convnext.md](plans/exp-32-b2-convnext.md). Levers to buy the runtime back, in order,
each measurable: 1 model instead of 3 (÷3, costs −0.031), `WINDOW_KEEP` at 12 of 18 windows (×0.67).

## Version axes — read this before comparing any two numbers

- `PREPROC_VERSION` — `p1` (3×4 @192, K=12) · **`p2` (6×3 @224, K=18 — b1)** · `p3` (asymmetric,
  K=22) · `p4` (uniform, K=22) · **`p5` (6×1 @384, K=6 — built, unused)**.
- `TRAIN_VERSION` — `t1` / **`t2`** (independent flip RNG). Cached tensors are identical, so `p2/t2`
  is **not** comparable to `p2/t1`.
- `BASELINE_VERSION` — **`b1`**. `b2` requires the §13.1 gate: ≥20% error-gap closure. exp-29 clears
  it on screening (22.7%); gold and a LB point are still owed.
- `WINDOW_KEEP` — new, default `None`. Trains on a subset of a cache without rebuilding it.
- Lineage `L0` regex / **`L1`** public LLM key.

## Queue, in priority order

1. **exp-32 stages 0 and 1** — armed, see above.
2. **exp-32 stage 2 / exp-19** — the train/infer split. Blocked on stage 1's checkpoints.
3. **Re-screen the closed lines at the new capacity** if convnext becomes b2 — schedule and geometry
   were decided against resnet18.
4. **exp-28 (384 px)** — written, cache built, held by Vaibhav.
5. **exp-14, our own label key v2** — the only route to Effusion and Medial OA, where the *key*
   now binds rather than the model. 1 of 3 fixes used. Also relevant to the winners' obligation,
   since the L1 key's prompt is unpublished.
6. **Final submission selection** — 0 of 2. b1 at 0.824 is the floor.

## Tooling added 2026-09-18 — use these, do not rebuild them

- **`notebooks/screen.ipynb`** — the screening instrument, driven by the *same* `OVERRIDES` dict as
  the baseline. `./scripts/exp.sh screen <id> '<json>'`. Ends the copy-a-notebook-per-experiment
  pattern that caused most of this programme's failures.
- **`scripts/pair_screen.py`** — reconstructs the screening pool's study order and pairs any two
  stored OOF arrays offline. Every screening comparison is now paired and free.
- **`exp.sh`**: `screen` / `qscreen`, `EXTRA_KERNELS` (attach another run's checkpoints), the L1
  label key as a **default** dataset source, and the override injector now emits Python literals.

## Traps already paid for — do not rediscover these

- **The override injector used to emit JSON**, so any boolean became `true` — a NameError. Fixed.
  Every experiment before exp-31 passed only numbers and strings, which is why it never fired.
- **The L1 label key must be attached** or every run dies at the lineage assertion. It is now a
  default in `exp.sh`; it killed exp-29 and exp-31 once.
- **Read the cache manifest, not `kaggle kernels files`** — that listing's size column is not bytes,
  and it briefly looked like p5 had built 4,407 empty arrays. The manifest answers in one call.
- **Never run `kaggle kernels output` on a cache kernel** — it pulls all 6.87 GB. Caches stay on
  Kaggle as attachments.
- **`kaggle kernels output` skips files that already exist locally**, silently keeping stale
  artefacts. `exp.sh fetch` clears first. This once produced an estimate 12× too large.
- **Submitting a screening notebook wastes a slot** — no inference cell means a constant-0.5
  `submission.csv`. Never arm an automatic submit on file validity alone; gate on the score.
- `--accelerator NvidiaTeslaT4` is the only usable GPU enum; a CLI push overwrites the UI's choice.
- **2 concurrent GPU sessions and a 30 h weekly quota, both account-wide** — other projects count.
- Mounts are nested; kernel logs appear only after a run completes.
- Determinism holds within an accelerator, end to end through a full retrain (exp-11 submitted
  twice, 0.808 both times), but not across devices.

## Assets on Kaggle

| what | ref |
|---|---|
| **b1** | `vaibhav486/rsna-knee-exp-23-p2-t2-ep12` |
| exp-29 (screening OOF, no checkpoints saved) | `vaibhav486/rsna-knee-exp-29-convnext-tiny` |
| earlier LB points | `…exp-08-llm-labels` (0.803) · `…exp-11-geometry-p2` (0.808) |
| screening references (p1 / p2 / 12-epoch) | `…exp-04-screening-metric` · `…exp-16-screen-p2` · `…exp-15-epochs-screened` |
| tensor caches | `…cache-build-p2` (8.0 GB, b1) · `…cache-build-p3` · `…cache-build-p4` · **`…cache-build-p5` (6.87 GB, 384 px)** |
| offline backbones | `vaibhav486/timm-backbones-offline` — resnet18/34, effnet-b0, **convnext_tiny** (Apache-2.0) |
| public label key | `stevenleehans/rsna-knee-llm-report-labels` (CC0) |

## Open items

- The L1 key's prompt and model are unpublished — we cannot reproduce or extend what the baseline
  depends on. Relevant to the winners' open-source obligation.
- We hardcode ImageNet `mean`/`std`; read `preprocessor_config.json` before swapping encoders again.
  convnext_tiny's in12k weights happen to use ImageNet statistics, so exp-29 is not affected.
- Still `[verify]`: the Efficiency-Prize formula, the hidden test size, the daily submission cap.
- `AGENTS.md` §8 sizes fix budgets against "~24 GPU h/week"; the real limit is **30 h**, shared
  with Vaibhav's other projects. Worth reconciling.

## Log

- **2026-09-18** — **exp-29 +1, the largest effect since the label swap**: convnext_tiny screens
  +0.0556 paired (CI [+0.0502, +0.0616], 12/12 targets up) — capacity, not geometry or schedule, was
  the binding constraint. exp-31 **null** (flip TTA −0.0007) and rank averaging **retracted** as n=58
  noise. exp-25 read as a 4-epoch finding and closed. exp-32 planned in three stages and armed
  against the quota reset. Cache p5 built on CPU. `screen.ipynb`, `pair_screen.py` and two `exp.sh`
  bugs (JSON booleans, the missing label key) landed. Runtime semantics resolved: 30/70 split, one
  rerun, no larger private rerun at the deadline.

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
