# exp-20260914-12 — our own LLM label key

**Verdict: −1.** Pilot run 2026-09-14/15, 300 reports, ~0.8 GPU h. Two independent kill criteria hit.

## Result

| | value | kill criterion |
|---|---|---|
| gold-test macro AUC | **0.7125** | < 0.75 → stop |
| gold-dev macro AUC | 0.7667 | dev−test 0.054, within the 0.08 limit |
| seconds per report | **9.57** | — |
| **extrapolated full corpus** | **11.72 GPU h** | > 4 h → stop |
| parse failures | 1 / 300 (0.3%) | > 5% → fix first |
| **cells at exactly 0.5** | **74.9%** | public key: 25.4% |
| cells below 0.2 (explicit negative) | **1.5%** | this is what the prompt was written to fix |

Reference on the same gold studies: public v4_blend **0.8927**, public v2 0.8873, our regex 0.6879.

## What went wrong, precisely

The prompt was written to fix exp-03's finding — a labeller that could not say "no" (pooled false
positive rate 0.66, only 5–8% negatives among decided OA cells). It produced the **opposite failure
and a worse one**: the model answers "not addressed" for three quarters of all cells and emits an
explicit negative 1.5% of the time.

So the instruction `Use exactly 0.5 when the report DOES NOT ADDRESS that finding` dominated every
other rule. Given an out, a 7B model takes it. Our regex said "positive" too readily; this prompt
says "I don't know" too readily. Neither is reading the report.

It also costs 11.7 h for the corpus — 9.57 s/report for ~220 greedy tokens from a 7B model, one
report per call, no batching.

## Inference

1. **The "not addressed" option needs a cost.** Forcing a three-way choice (present / absent /
   genuinely not mentioned) with the third option described as rare, or few-shot examples that
   demonstrate explicit negatives, is the obvious repair. That is a prompt fix, not an idea failure.
2. **Throughput needs batching.** One report per generate call wastes the GPU. Batched generation
   (8–16 reports) plus a shorter output contract (12 comma-separated numbers instead of JSON) should
   move 11.7 h toward 1–2 h. Without that, no prompt is affordable to test on the full corpus.
3. **dev−test = 0.054 on 29/29** shows how noisy a 29-study ruler is — even our gold split needs the
   screening metric to be read properly.

## Status

Abandoned at its current budget: 1 of 3 fix attempts used. The **auditability motive is unchanged**
— we still depend on a key whose prompt and model are unpublished. Reopen as **exp-14** only with
both repairs (prompt v2 + batching) and a pilot that must beat 0.80 on gold-test before any full run.
