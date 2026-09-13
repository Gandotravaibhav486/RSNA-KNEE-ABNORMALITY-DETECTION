# Kaggle discussion findings — read 2026-09-14

Source: the competition's own discussion board. These are **other competitors' measurements**, not
ours. Treated as leads to verify, not as facts to build on — but several of them independently
confirm what our own runs found, and two of them say our pipeline is behind the community baseline.

## 1. Our weak labeller is far worse than the community's regex, let alone their LLM

From *"'Not addressed' is a label too — what we learned reading 4,407 knee reports with an LLM"*
(stevenleehans, 41 votes), macro AUC against the same 58 gold studies:

| label source | macro AUC vs gold |
|---|---|
| **our `v1-keyword` regex** | **0.6879** |
| their regex / lexicon extraction | 0.8136 |
| their LLM reading the same reports | 0.8780 |
| + targeted synovitis repair (below) | 0.8873 |

**Our labeller is ~0.13 behind a competent regex on the identical measurement.** This is the
single largest gap between us and the field, and it is upstream of everything else we do.

Public LLM-derived label sets already exist and **public external data is allowed** (rules.md):
- `stevenleehans` — RSNA Knee LLM Report Labels
- `Pilkwang Kim` — rsna-knee-llm-labels (first published, 2026-08-06)
- `barun2104` — Stratified Folds & LLM Soft Labels
- `lixin73` — LLM Report Labels (GPT-5.6-Sol)

## 2. "Not addressed" means different things per finding — this refines our exp-03

They asked the labeller for an explicit "the report does not address this" option (→ 0.5).
**25.4% of all cells** came back undecided, distributed very unevenly. The key table, gold positive
rate when the report is **silent** vs when it **speaks**:

| finding | silent | speaks |
|---|---|---|
| Synovitis | 0.34 | 0.76 |
| PF OA | 0.21 | 0.41 |
| Baker's | **0.03** | 0.44 |
| Medial OA | **0.00** | 0.36 |

For Baker's and Medial OA the **silence is the label** — absence of mention ≈ absence of finding.
For Synovitis silence is genuinely uninformative. Treating all unknowns alike is worse than leaving
them empty.

This sharpens our exp-03 result rather than contradicting it. We measured that the labeller is a
*mention detector* (pooled FP 0.66, miss 0.02). They measured what the *silence* is worth, per
finding. Both point at the same repair: the unknown/negative half is where the value is.

**What they tested and it worked:** filling only undecided *Synovitis* cells from the *Effusion*
field (never overriding an explicit statement) moved that column 0.678 → 0.790 and the key
0.8780 → 0.8873. P(syn | eff) = 0.63 vs P(syn | no eff) = 0.22.

**What failed:** doing the same for all twelve findings via a learned ridge imputation made it
*worse* (0.8805 < 0.8873). Blanket imputation destroys the informative silences.

## 3. Encoder capacity is not the constraint — measured, not asserted

From *"Scaling the encoder bought us nothing (+0.0011)"* (same author):
DINOv2-Small → Base (22M → 87M, 3.9× compute) moved CV **+0.0011 against a noise floor of 0.0020**.
Only 5 of 12 labels improved, and the whole macro gain rested on MCL — their least reliable label.
By contrast an earlier **crop-geometry fix paid +0.0059 and moved 10 of 12 labels**: "that's what a
real effect looks like."

**Geometry beats capacity here.** Directly relevant to our decode-bound cost model: we concluded a
bigger backbone is nearly free in wall-clock. It is also, apparently, nearly worthless.

## 4. Their image tensor vs ours

| | theirs | ours |
|---|---|---|
| slots | 6 | 3 |
| slices per slot | 9 | 4 windows × 3 adjacent |
| resolution | 224 | 192 |
| whole-dataset cache | **11.12 GiB** sharded `.npy`, memory-mapped | 4.84 GB per-study `.npz` (zlib) |
| decode cost | 55 min/run, removed permanently by persisting | 0.56 h once, then reloaded per epoch |

They report the cache made a laptop (M4 Pro, fp32) finish a fold *sooner* than a Kaggle T4, purely
by never rebuilding: 67 min vs 76 min, at **zero GPU quota**.

## 5. Two failure modes they hit that we also hit

- **Silent backbone fallback.** Off Kaggle, their weights lookup returned None and quietly fell back
  to ResNet-18, "which trains fine and logs a plausible score". *We lost 1.26 GPU h to exactly this.*
  Their rule — "any run that doesn't print which backbone it loaded is not evidence about that
  backbone" — is now enforced by our `preflight()`.
- **A checkpoint carries its own preprocessing contract.** Swapping to RAD-DINO while keeping
  ImageNet `mean/std` handicapped it silently; the fix is to read `image_mean`/`image_std` from the
  checkpoint's `preprocessor_config.json`. **We hardcode the ImageNet constants** — fine for our
  current resnet18, a trap the moment we swap encoders.

## 6. Their validation design confirms our exp-04 proposal

They report a **paired noise floor of 0.0020** measured on derived OOF over **2,652 studies**, and
separately warn that on the 58 gold studies "differences below roughly 0.02 macro are not
measurable" — they have had three gold-set readings overturned by the leaderboard.

Our 2σ bar on gold is **0.1110**. Theirs on the larger derived set is **0.0020** — a 50× tighter
instrument. This is exactly `exp-20260913-04`, and it is no longer a proposal we are arguing for
from first principles: a competitor is running it and reporting numbers we cannot currently detect.

## Consequences for our queue

1. **exp-04 (screening metric on the large derived set) is promoted to first.** Without it we cannot
   measure any of the improvements below.
2. **exp-07 (labeller precision) is superseded in scope:** the community-standard move is LLM-derived
   labels, not a better regex. Evaluate attaching a public LLM label set as a lineage **L1**, and
   keep our regex as the control.
3. **Per-finding treatment of unknowns**, following their silent-vs-speaks table — not a blanket rule.
4. Architecture experiments drop down the queue. Crop geometry stays up.
