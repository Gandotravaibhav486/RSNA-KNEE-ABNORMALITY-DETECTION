# experiments.md — experiment ledger

Append-only. One row per experiment, proposed or run. Rejected proposals stay in the table with
`status: rejected` so no one re-proposes them. Details for each experiment live in
`experiments/<exp-id>.md`.

## Baseline (must be filled before any pipeline change — AGENTS.md §1)

| Field | Value |
|---|---|
| Metric | macro ROC AUC over 12 targets *(verify against competition page)* |
| CV protocol | repeated K-fold over the 58 gold studies, seeds `[0,1,2,3,4]` — **not yet run** |
| Baseline CV score | `UNKNOWN — blocking` |
| Baseline public LB | `UNKNOWN — blocking` (rsna-baseline.ipynb's provenance note claims **0.936** for the copied public ensemble; that number is *reported, not measured by us*) |
| Baseline commit | `UNKNOWN — blocking` |
| Baseline notebook | **`notebooks/baseline-v1.ipynb`** (built 2026-09-13, all in-notebook tests pass, not yet run on GPU) |
| Weak labeller `v1-keyword` | **macro AUC 0.6879 on the 58 gold studies** — measured 2026-09-13, CPU only. This is the floor the image model must beat. |
| Date measured | — |

**Blocking next actions:** (a) approve [plans/baseline-v1.md](plans/baseline-v1.md), (b) run
`notebooks/baseline-v1.ipynb` stages 1–3 on Kaggle for *our own* CV number and σ, (c) submit once
for *our own* public score, (d) record commit hashes here.

## Baseline lineages

The baseline moves only through the §13.1 promotion gate: **(A)** ≥20% error-gap closure
(`(gap_base − gap_new)/gap_base`, `gap = 1 − AUC`), or **(B)** a fundamentally new approach family,
which gets its own lineage rather than replacing the old one. Significant `+1`s that clear neither
gate are *accepted improvements* — merged and used, but they do not move a baseline row.

| lineage | approach family | notebook / branch | CV | public LB | promoted via | date |
|---|---|---|---|---|---|---|
| L0 | weak-label CNN starter | `rsna-starter.ipynb` / `main` | `UNKNOWN — blocking` | `UNKNOWN — blocking` | initial | — |

### Accepted improvements (inside a lineage, baseline unchanged)

| exp-id | lineage | Δ CV | closure % | LB | why it did not promote |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

## Ledger

| exp-id | date | type | change | hypothesis | baseline CV | new CV | Δ CV | public LB | lead ±1 | status |
|---|---|---|---|---|---|---|---|---|---|---|
| `exp-20260913-01-baseline-v1` | 2026-09-13 | paper | Build the baseline notebook: fixed-epoch training, gold never fitted, stratified fold σ, dropped-cell accounting, offline-safe, runtime instrumented | Produces a defensible yardstick + the 2σ bar | — | pending | — | — | n/a | approved-pending-run |
| `exp-20260913-02-labeller-es` | 2026-09-13 | data-analysis | Weak labeller misses Spanish `condropatía` / `cartílago` / `rotuliana`; only English `chondropath`/`cartilage loss` match. Spanish is the dominant report language | PF-OA coverage is 22.9% and Lateral OA 11.9%; closing Spanish OA vocabulary should lift coverage and therefore every downstream model | 0.6879 (labeller v1) | — | — | — | — | proposed |
| `exp-20260913-03-coverage-ceiling` | 2026-09-13 | paper | Compute the achievable ceiling: what macro AUC is reachable given current label coverage per target, assuming a perfect image model | Tells us whether to spend on labels or on models — no GPU needed | 0.6879 | — | — | — | — | proposed |

`type` ∈ `data-analysis` \| `split` \| `loss` \| `architecture` \| `training` \| `paper`
(`paper` = inferred without GPU spend).
`status` ∈ `proposed` \| `approved` \| `running` \| `done` \| `rejected` \| `abandoned (budget)`.

## Per-experiment entry template

Copy into `experiments/<exp-id>.md`:

```markdown
# exp-YYYYMMDD-NN-<slug>

- **Type:** loss | architecture | ...
- **Worktree:** /Users/vaibhavgandotra/RSNA-wt/exp-YYYYMMDD-NN-<slug>  (branch: same name)
- **Proposed by:** <agents>, from <discussion / notebook links>
- **Hypothesis:** ...
- **Mechanism:** why this should move the metric
- **Kill criterion:** what result makes this -1
- **Fix budget:** N attempts (per AGENTS.md §8) — used: 0
- **GPU estimate / actual:** Xh / Yh
- **Plan approved by Vaibhav:** yes/no, date

## Result
- CV (same folds/seeds as baseline): mean ± std
- Δ vs baseline, and 2×std(Δ) threshold
- Public LB (if submitted): score, submission date
- **Verdict:** +1 / -1

## Reviews
- Reviewer agent: ...
- Adjudicator sub-agent (differences in reasoning, required changes, likely failure mode): ...

## Inference
What we now believe that we did not believe yesterday. What this rules out.
What the next experiment should be.
```

## Daily rollup

| date | proposed | run | submitted | +1 leads | -1 leads | GPU h |
|---|---|---|---|---|---|---|
| — | — | — | — | — | — | — |
