# Plan — exp-22, DINOv2-small as the encoder

**Type:** architecture · **Fix budget:** 2 · **GPU:** ≤3 h (screening arm ≈0.5–1 h)

## Why this, and not the other weights in that notebook

The 0.936 notebook attaches two very different kinds of input, and they are not equally usable:

| input | usable? | why |
|---|---|---|
| **DINOv2 small / base** (Meta), RadImageNet ResNet-50 | **yes** | Generic pretrained encoders. Public, permitted, reproducible, and swapping one in is *our* experiment. |
| `raptor_ft_coatnet384.pt`, `raptor_ft_cnv2b336.pt`, `raptor_ft_effv2l480.pt`, knee-mri-fold-weights | **only for profiling** | These are models already fine-tuned **on this competition** by someone else. Legal as public external data, but a submission built on them is their solution wrapped in our notebook: nothing is learned, the winners' obligation to open-source *a working solution* becomes awkward, and the forum already has a thread about byte-for-byte notebook copying. We use them in exp-21 to *measure where we lag*, not to score. |

## Hypothesis

Our encoder is `resnet18` at 224 px — chosen when the pipeline was decode-bound and capacity looked
free. A competitor measured DINOv2-S → DINOv2-B at **+0.0011 against a 0.0020 floor** (a null), which
says *scaling within DINOv2* does nothing. It does **not** say resnet18 ≈ DINOv2-S: that is a
different jump, from a small supervised CNN to a self-supervised ViT. Our own pretrained-vs-random
result (+0.046 on the LB) shows encoder quality is worth something at our level.

Expected: somewhere between nothing and +0.02. The screening bar is 0.0044, so either answer is legible.

## What the code does carefully

- Reads `preprocessor_config.json` for the checkpoint's own `image_mean`/`image_std` and re-maps the
  dataset's ImageNet normalisation to it. A competitor lost an 11-hour run by assuming ImageNet
  constants for RAD-DINO; this is that lesson applied.
- ViT-S/14 at 224 px = 256 patches, so the geometry divides cleanly.
- CLS token as the window embedding, so `KneeNet`'s attention head is untouched — the encoder is the
  only variable.

## Kill criteria

- OOM at `BATCH=4` with 18 windows → drop to 12 windows before touching anything else, and say so.
- Per-epoch time > 6× resnet18 → the efficiency cost outweighs a small gain; stop and report.
- Δ < 0 on the screening metric → resnet18 stays; record that capacity is not the constraint here,
  which would corroborate the competitor's null from a different direction.

## Success

**+1** if Δ > 0.0044 paired on the screening metric **and** inference stays inside the 6.75 h working
limit at 5,000 studies. A gain that breaks the runtime budget is an Efficiency-Prize loss traded for a
leaderboard gain, and needs to be argued, not assumed.
