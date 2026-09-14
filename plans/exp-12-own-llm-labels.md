# Plan — exp-20260914-12, our own LLM label key

**Type:** data-analysis (but GPU-consuming, so §0 applies) · **Fix budget:** 3

## Why, given the public key already scores 0.8927

1. **Reproducibility.** The public keys name no model and publish no prompt. We cannot correct or
   extend them. Winners must open-source a working solution; targets from an unreproducible CSV
   make that awkward.
2. **Decorrelation pays more than solo quality here.** The public v4 blend gained most from its
   *weakest* partner (0.8347 alone, rank-correlation 0.718) — an independent key is worth having
   even below 0.8927.
3. **We know specifically what to fix.** exp-03 measured the failure: pooled false-positive rate
   0.66 vs a 0.02 miss rate, and 5–8% negatives among decided OA cells. The prompt targets that.

## Staging

| stage | what | cost |
|---|---|---|
| 1 **pilot** (this run) | 300 reports incl. all 58 gold; measure s/report and score the prompt | ~0.3–0.6 GPU h |
| 2 decide | full run only if the pilot's extrapolation is affordable and gold-test is competitive | — |
| 3 full | all 4,407 reports → our key, published in-repo | est. from stage 1 |
| 4 blend | our key + public key, weighted; measure the blend, not just ours | 0 GPU |

Model: `Qwen2.5-7B-Instruct` (Apache-2.0, Kaggle Models, offline). Greedy decoding, one report per
call — so the key is reproducible from this repo.

## Kill criteria

- Pilot extrapolates to **> 4 GPU h** for the full corpus → stop; drop to a smaller Qwen or batch.
- Parse failures **> 5%** → the prompt's output contract is wrong; fix before scaling (fix budget).
- gold-test macro **< 0.75** → the key is not competitive on its own; keep it only if it still
  improves the blend (stage 4), otherwise abandon and stay on the public key.
- gold-dev minus gold-test **> 0.08** → the prompt is tuned to 29 studies; report both, trust test.

## Success

| Verdict | Condition |
|---|---|
| **+1** | gold-test ≥ 0.85 **or** the blend with the public key beats 0.8927 by more than the screening metric's bar. Either gives us an auditable key worth training on. |
| **Partial** | 0.75–0.85 solo and no blend gain — usable as a second opinion, not as the primary key. |
| **−1** | Below 0.75 and no blend gain. Stay on the public key, and record that the gap is the prompt/model, not the idea. |

## Gold discipline

29 dev / 29 test, fixed seed. Prompt revisions look only at dev; every reported number is test.
Not as clean as an untouched hold-out — stated openly because 58 labelled studies leave no better
option.
