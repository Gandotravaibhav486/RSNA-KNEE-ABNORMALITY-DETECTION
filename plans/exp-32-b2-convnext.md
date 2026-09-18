# Plan — exp-32, promote convnext_tiny to `b2`

**Type:** architecture → packaging · **Fix budget:** 2 fixes / ≤3 GPU h per stage (AGENTS.md §8)
**Status:** awaiting approval (AGENTS.md §0)

## What exp-29 established, and what it did not

Screened: convnext_tiny **0.8105** vs b1's 0.7550 — **+0.0556 paired**, CI [+0.0502, +0.0616],
P=1.000, 12/12 targets up. Error-gap closure **22.7%**, which clears the §13.1 promotion gate of 20%.

What it did **not** establish: a gold CV number under b1's protocol, a leaderboard point, or that the
thing is submittable at all. **It is not submittable as b1 is built** — see the runtime section, which
is the reason this plan has three stages rather than one.

## Stage 0 — the control (screening, ~0.7 GPU h)

`./scripts/exp.sh screen exp-30-r18-lr5e5 '{"LR_BACKBONE": 5e-05}'`

exp-29 changed **two** things: the encoder and its backbone LR. This runs b1's resnet18 at
convnext's LR, which decomposes the +0.0556 exactly. Cheap, and it settles whether we learned
"convnext is better" or "we had been training at the wrong LR for every experiment since exp-08" —
the second would retroactively touch every architecture result we have, including exp-22's DINOv2.

**Kill:** none — both outcomes are informative. It runs in parallel with stage 1.

## Stage 1 — the full run (~4.5–6.5 GPU h)

`./scripts/exp.sh run exp-32-b2-convnext '{"BACKBONE": "convnext_tiny", "LR_BACKBONE": 5e-05}'`

b1's protocol exactly: 12 epochs × 3 seeds, 5-fold × 5-repeat evaluation over the 58 gold studies,
paired against b1's stored `gold_probs_seed*.npy`. Produces the gold CV, the per-label table, and —
the point of this stage — **three checkpoints**.

Budget: b1's full run was 2.25 h for 3 seeds; convnext is 2.8× per epoch → ~6.3 h. That fits the 9 h
session but not comfortably. **If the first seed exceeds 2.2 h, stop at 2 seeds** and say so; two
seeds still gives an ensemble and the third is worth +0.01 at most.

**Kill:** gold CV below b1's 0.8319 by more than the paired bar (0.0254) → stop, do not submit, and
report that the screening metric and gold disagree at a size that matters — which would be the first
time in this programme that has happened.

## Stage 2 — make it submittable (exp-19, now a prerequisite rather than a nice-to-have)

**b1's submission notebook trains from scratch during the rerun.** That was affordable at 2.25 h of
training. At convnext's 6.3 h it is not: training plus inference would exceed 9 h and score nothing.

So stage 2 is the split we have had queued since 2026-09-16:

1. Publish stage 1's checkpoints as a Kaggle dataset.
2. Submission notebook runs `RUN_MODE="submit"` only — loads weights, infers, writes `submission.csv`.
3. Measure honest per-study seconds on the visible path and extrapolate.

Then buy the runtime back until it fits, in this order, each measurable:

| lever | effect on inference | cost to accuracy |
|---|---|---|
| 1 model instead of 3 | ÷3 → ~2.1 s/study | −0.031 on gold (exp-31 measured the ensemble's worth) |
| `WINDOW_KEEP` 12 of 18 windows | ×0.67 | unknown — screen it first, it is ~0.7 h |
| both | ~1.4 s/study | the above, compounded |

**Kill:** if no combination lands under 6.75 h at a defensible hidden-test size, convnext does not
become b2 — it stays a measured finding, and b1 remains the submission. A configuration that cannot
state its per-study seconds is not reviewable (rules.md hard rule 7).

## Runtime, and what actually happens if we exceed our own limit

- **9 h is Kaggle's hard cap.** Over it, the rerun is killed and the submission **errors — it scores
  nothing at all**, on the public and the private leaderboard alike. There is no partial credit.
- **6.75 h is ours**, the cap minus 25%. Nothing enforces it. A run between 6.75 and 9 h scores
  normally on both boards.
- The headroom exists because three things we cannot control move the number: the **hidden test size
  is unpublished** (rules.md `[verify]`; we see 3 visible studies), Kaggle's hardware and queue vary
  run to run, and a cold cache costs more than a warm one. A 7.5 h estimate with ±20% variance is a
  coin flip against a cliff.
- **The failure is total, and it lands on a final-selection slot.** We have two. A timed-out
  submission is not a low score, it is no score.

**`[verify]` before any submission that leans on this:** whether this competition re-runs selected
submissions against a *different or larger* private test set at the deadline. If it does, a notebook
that fits today can time out at the deadline, and the 25% headroom stops being conservative and
starts being the only thing standing between us and a zero. Read the Code Requirements page and
record the answer verbatim in rules.md.

## Success

A gold CV and a leaderboard point for convnext under b1's protocol, and either a submittable
configuration under 6.75 h — in which case bump `BASELINE_VERSION` to `b2` and record which overrides
became defaults — or a clear statement of what the runtime cap costs us in accuracy.
