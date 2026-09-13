# AGENTS.md — permanent operating rules

Scope: every coding task, review, and experiment in this repository.
These rules are **permanent**. Competition-specific rules live in [rules.md](rules.md).
The experiment ledger is [experiments.md](experiments.md). End-of-session state is [handoff.md](handoff.md).

---

## 0. Prime directive: no GPU spend without an approved plan

Before **any** code change that will consume GPU time (training, fine-tuning, full-data
inference, large embedding jobs):

1. Enter `/plan` mode. Write the plan into `plans/<exp-id>.md`.
2. The plan must state: hypothesis, the mechanism by which it should help, expected delta on CV,
   GPU hours, data touched, and the kill criterion (what result makes this a `-1`).
3. Get explicit human approval (Vaibhav) before exiting plan mode.

Ask first: **can this be inferred without running it?** If a statistic, a dry-run on cached
features, a label-only simulation, a pen-and-paper argument, or a re-read of a public notebook
settles the question, do that instead and log it as a *paper experiment* (`type: paper`) in
experiments.md. GPU hours are reserved for questions that only a GPU can answer.

## 1. Baseline first

No change to the pipeline is made until the current baseline is recorded in
[experiments.md](experiments.md):

- baseline **cross-validation score** (metric + protocol + fold seed), and
- baseline **public Kaggle score** (submission id + date), and
- the exact commit / notebook hash that produced them.

If a number is unknown, it is written as `UNKNOWN — blocking` and obtaining it is the next task.
Never compare a new result against a baseline that was never measured.

## 2. Every change passes the competition rules

Before a change is accepted it is checked line-by-line against [rules.md](rules.md).
A change that violates a rule is rejected regardless of its score. If a rule looks wrong,
change the rule in a separate commit with its justification — do not quietly break it.

## 3. Changes are made in notebooks, then verified

- Each code change lands as a Python notebook (`notebooks/<exp-id>-<slug>.ipynb`).
- The notebook must be **run** — a change that has not executed does not exist.
- Its effect is checked by **unit tests** (`tests/test_<exp-id>.py`) and/or a **code reviewer**
  agent. Tests cover: shape/dtype contracts, leakage checks, determinism under fixed seed,
  and submission-format validity.
- Cells are ordered so a fresh kernel + "Run All" reproduces the logged score.

## 4. Two-layer review

1. **Reviewer agent** — reviews the diff for correctness, leakage, and rules.md compliance.
2. **Adjudicator sub-agent** (separate, does not see the reviewer's conclusion first) — reads the
   code *and* the review, and reports:
   - where its reasoning **differs** from the reviewer's,
   - what the implementing agent must change,
   - the most likely **failure mode** of this code in the hidden-test rerun.

Disagreement between the two is not resolved by vote — it is resolved by a test or a statistic.
Both reviews are pasted into the experiment's entry in experiments.md.

## 5. Worktrees, and the ±1 lead rule

- Accepted changes land in a **git worktree**, one worktree per experiment. Multiple worktrees
  run concurrently; **each agent gets its own unique directory** (see *Worktree layout* below)
  and never writes outside it. No two agents share a worktree, a cache dir, or an output path.
- Once the output exists, filter it and write the **inference** (what we learned), not just the score.
- Scoring the idea:
  - **+1 lead** — significant positive change vs the public/CV baseline → pursue, design follow-ups.
  - **-1** — no significant change or worse → stop pursuing this branch, and record *why*,
    so it is never re-run by a later agent.
- "Significant" is defined per competition in rules.md (effect size vs fold noise), not by eyeballing.
- The next round of experiments is designed from the current round's results, not from a fixed wishlist.

## 6. Experiment intake: what gets built at all

An experiment is accepted for implementation only after **2–3 agents** (chosen for the current
trajectory) independently argue for it. Those agents:

- read current **Kaggle discussions** for this competition,
- read the **top public notebooks / baselines** and the top public scores,
- draft and post the open questions on how to implement it,
- and fold discussion feedback back into the proposal.

Their output is a one-page proposal; disagreement among them is stated in the proposal, not hidden.

## 7. Daily cadence

- **≥ 5 experiments run per day.**
- **≥ 10 experiments proposed per day**; the top 5 by expected-value-per-GPU-hour are selected,
  and of those the strongest are submitted (respect the daily Kaggle submission cap).
- Every proposal and every run gets a row in experiments.md the same day — including the rejected ones.

## 8. Fix budgets

Each change type carries a budget. When the budget is exhausted, **stop**, write the inference,
mark the lead `-1`, and move on. Budgets are per experiment, not per day.

| Change type | Fix budget | GPU budget | Plan gate | Notes |
|---|---|---|---|---|
| **Data analysis** (EDA, label quality, statistics) | 3 fix attempts | 0 h — CPU only | not required | Must produce a written inference, not a plot dump. |
| **Split** (CV design, fold assignment, leakage) | 2 fix attempts | ≤ 0.5 h | required if retraining | A split change invalidates every prior CV number — say so loudly. |
| **Loss** (objective, weighting, label smoothing) | 3 fix attempts | ≤ 2 h | required | Must be validated on the same folds as baseline. |
| **Architecture** (backbone, head, input geometry) | 2 fix attempts | ≤ 6 h | required | Most expensive per unit of learning; needs the strongest prior. |
| **Training** (schedule, aug, epochs, EMA, AMP) | 4 fix attempts | ≤ 4 h | required | Cheap fixes; but 4 failed fixes = the idea is wrong, not the config. |

A "fix attempt" is one debug-and-rerun cycle after the first run fails or underperforms.

## 9. Worktree layout and isolation

```
/Users/vaibhavgandotra/RSNA            # main, baseline + docs, no experiments run here
/Users/vaibhavgandotra/RSNA-wt/<exp-id>/   # one worktree per experiment  (git worktree add)
```

Rules:
- Branch name == worktree dir name == experiment id: `exp-YYYYMMDD-NN-<slug>`.
- Each worktree sets `WORK_DIR=$PWD/work`, its own `cache/`, its own `oof/`, its own `subs/`.
  Nothing is written to a shared path except `experiments.md` (append-only, one commit per row).
- Branches carry their own baseline and experiment results; main carries the canonical baseline.
- An agent that needs a second directory asks for one — it does not borrow another agent's.

## 10. Git and session hygiene

- Baseline is committed and pushed to GitHub before experiments begin.
- One experiment = one branch = one worktree = one commit trail.
- **Before ending a long session**, update [handoff.md](handoff.md): what ran, what the numbers were,
  what is in flight, what the next agent should do first. A session that ends without a handoff
  costs the next day an hour.

## 11. Workflow → schema

If the same workflow is run more than once in a day, or shows up every day, **propose it to
Vaibhav as a schema/skill** (name, trigger, steps, inputs, outputs) rather than re-typing it.
Do not create the schema unilaterally; propose, get a yes, then build it.

---

## Reporting honestly

Report what happened. A failed run is data. Never round a CV score in our favour, never compare
against a different split, never report a public score that was not actually submitted.
