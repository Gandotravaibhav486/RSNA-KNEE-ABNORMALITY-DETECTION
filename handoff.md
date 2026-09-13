# handoff.md — session handoff

Updated before the end of every long session (AGENTS.md §10). Overwrite the "Current state"
section; append to "Log".

## Current state — 2026-09-13

**Set up today:** governance docs only — no pipeline change, no GPU spend.

- `AGENTS.md` — permanent rules (plan-gate on GPU, review chain, worktrees, fix budgets, cadence).
- `rules.md` — RSNA knee-MRI specific hard rules + the statistical test for +1/-1.
- `experiments.md` — ledger; **baseline CV and public LB are still UNKNOWN and are blocking.**
- `handoff.md` — this file.

**Repo state:** not yet a git repo / not yet pushed — needs Vaibhav's go-ahead on the GitHub remote.

**What the next session must do first (in order):**
1. Confirm the metric, runtime limit, and external-data rules on the competition page
   (everything marked **[verify]** in rules.md).
2. Run `rsna-starter.ipynb` end-to-end to produce *our own* CV number on the 58 gold studies,
   with repeated K-fold over ≥5 seeds. Record it in experiments.md with the commit hash.
3. Submit once to get *our own* public LB number. Record it.
4. Only then open the first experiment worktree.

**Open questions for Vaibhav:**
- GitHub remote (org/repo name, private?) for the baseline push.
- Are the extra worktree directories to live at `/Users/vaibhavgandotra/RSNA-wt/`?
- Kaggle CLI credentials available for automated submission, or submit manually?

## Log

- **2026-09-13** — created AGENTS.md, rules.md, experiments.md, handoff.md. Data inspected:
  4,407 train studies, 58 gold-labelled, 12 targets, multilingual reports, series metadata with
  plane/fluid-sensitive/fat-suppression flags. Two notebooks present: a copied public
  inference-only ensemble (reported 0.936) and a runnable starter pipeline.
