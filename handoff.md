# handoff.md — session handoff

Updated before the end of every long session (AGENTS.md §10). Overwrite "Current state";
append to "Log".

## Current state — 2026-09-15

**Lineage L1 is the baseline: gold CV 0.7642, public LB 0.803.** One label change did it.

| | value |
|---|---|
| **L1 gold CV** | **0.7642** (3 seeds, ensemble 0.7760) — public LLM label key `llm_labels_v4_blend` |
| **L1 public LB** | **0.803** (submission 56235067) |
| L0 (regex labels) | CV 0.6339, LB 0.641 |
| **Primary instrument** | **screening metric v2, 2σ = 0.0068** — 16× tighter than gold |
| Gold σ / bar | 0.0555 → Δ > 0.1110 — confirmation set only now |
| GPU spent so far | ≈4.3 h of the ~24 h/week |
| Deadline | **final submission 2026-10-22** — 37 days |

## In flight right now

| kernel | what | expect |
|---|---|---|
| `exp-13-epochs-L1` | epoch sweep 2/4/8/12 on the **L1** key | does the optimum move once labels are clean? |
| `cache-build-p2` | CPU, 6 slots × 3 windows @224, **train studies only** | the cache exp-11 needs; also makes inference timing honest |

`exp-11` (geometry) is ready to push the moment `cache-build-p2` completes — it needs
`CACHE_INPUT_DIRS` pointed at the p2 output and `PREPROC_VERSION = "p2"`.

## What we learned, in the order it matters

1. **Labels were the binding constraint, and the fix is bought, not built.** Swapping our regex key
   (0.6879 on gold) for the public LLM key (0.8927) moved CV +0.1303 and the LB +0.162. Nothing else
   changed — same model, folds, seeds, cache, epochs.
2. **Measurement was the second constraint.** 58 gold studies give a 2σ bar of 0.1110, which cannot
   see effects the LB proves real. The screening metric (3-fold OOF over 3,406 studies, scored
   against the L1 key) gives **0.0068**. Everything small is nowmeasurable.
3. **The model overfits noisy labels rather than underfitting.** exp-10: 4→8→12 epochs on L0 gave
   0.6333 → 0.6127 → 0.5998, monotone down, while training loss kept falling. exp-13 re-asks this
   under clean labels.
4. **A "not addressed" option needs a cost.** exp-12's own prompt let Qwen2.5-7B answer "not
   addressed" for 74.9% of cells (public key: 25.4%) and emit explicit negatives 1.5% of the time —
   the mirror image of the regex's 0.66 false-positive rate.
5. **CV predicts direction, not level.** CV/LB gaps: −0.009, +0.007, **+0.039**. The offset grows as
   the model improves, probably because gold is the annotator's sampling (every gold study has ≥1
   positive, mean 4.14 findings) rather than the test distribution.

## Queue, in order

1. **exp-11 geometry** — 6 slots × 224 px vs 3 × 192. A competitor measured crop geometry at +0.0059
   across 10/12 labels while encoder scaling was a null. Push when p2 finishes.
2. **exp-09 per-finding silence** — silence ⇒ negative for Baker's / Medial OA (gold-positive 0.03 /
   0.00 when the report is silent), unknown for Synovitis (0.34). Never blanket — the community
   measured blanket imputation *losing* 0.0068.
3. **exp-14 own LLM key, reopened** — only with prompt v2 (a cost on "not addressed") **and** batched
   generation. Must beat 0.80 on gold-test in a pilot before any full run. 1 of 3 fix attempts used.
4. **Confidence-weighted loss** — the L1 key is soft, and `2·|p−0.5|` is the natural weight, which
   sends "not addressed" cells to zero automatically. Cheap, untested, sits inside L1.
5. **Blend keys** — the public v4 gained most from its *weakest* partner because it was least
   correlated. Any second key we build has value even below 0.89.

## Environment facts (do not re-learn these)

- `kaggle kernels push --accelerator NvidiaTeslaT4`. Valid: `NvidiaTeslaT4` / `NvidiaTeslaP100` /
  `Tpu1VmV38`. Anything else is silently ignored → P100 (sm_60), which this PyTorch cannot use.
  A CLI push overwrites the accelerator chosen in the UI.
- **2 concurrent batch GPU sessions, measured.** A third push is refused. CPU pushes are exempt —
  `./scripts/exp.sh push <id> <nb> cpu`, and `queue` waits for a slot.
- Mounts are **nested**: `/kaggle/input/{datasets,notebooks,competitions,models}/<owner>/<slug>/…`.
  Notebooks discover their inputs rather than assuming a layout.
- Kernel logs are only exposed after a run completes.
- Training is decode-bound: ~50 s/epoch on 3,406 cached studies.
- `preflight()` (fails a `full` run before epoch 1 if weights or cache are missing) and
  `scripts/lint_nb.py` (pyflakes pre-push gate) exist because every failure so far died *after* the
  expensive part.
- LLM-derived labels are explicitly permitted by the host (discussion 733965).

## Assets on Kaggle

| what | ref |
|---|---|
| L1 baseline notebook | `vaibhav486/rsna-knee-exp-08-llm-labels` |
| screening metric | `vaibhav486/rsna-knee-exp-04-screening-metric` (v2 = L1 key) |
| tensor cache p1 | `vaibhav486/rsna-knee-cache-build-p1` (4,410 studies, 4.84 GB) |
| tensor cache p2 | `vaibhav486/rsna-knee-cache-build-p2` (building) |
| offline backbones | `vaibhav486/timm-backbones-offline` (Apache-2.0) |
| public label key | `stevenleehans/rsna-knee-llm-report-labels` (CC0) |

## Open items

- The L1 key's prompt and model are **unpublished**. We cannot reproduce or extend it, which sits
  awkwardly with the winners' open-source obligation. exp-14 is the answer if it can be made to work.
- We hardcode ImageNet `mean`/`std`; read `preprocessor_config.json` instead before swapping encoders.
- Still `[verify]` in rules.md: the Efficiency-Prize formula, hidden test size, daily submission cap.
- `.claude/`, `.agents/`, `skills-lock.json` untracked — track or leave?
- Submitting a notebook that has no inference cell wastes a slot (exp-04 scored 0.500). Check
  `submission.csv` is not the fallback before submitting.

## Log

- **2026-09-15** — exp-12 −1 (own LLM key: 0.7125 gold-test, 11.7 h corpus, 74.9% "not addressed").
  exp-13 and cache-p2 launched. Fixed `exp.sh`'s cpu push path (macOS bash 3.2 empty-array bug).
- **2026-09-14** — **exp-08 +1 → L1 promoted** (CV 0.6339→0.7642, LB 0.641→0.803, 45.1% LB error-gap
  closure). exp-04 +1, screening metric adopted (2σ 0.0182 → 0.0068 on the L1 key). exp-10 −1
  (more epochs is worse). exp-03 +1 (labeller is a mention detector; killed exp-02 before it ran).
  Read the competition discussions; built `scripts/exp.sh` and the notebook lint.
- **2026-09-13** — baseline L0 measured (CV 0.6339, LB 0.641) and submitted; cache p1 built
  (4,410 studies, 0 errors); governance docs written.
