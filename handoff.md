# handoff.md — session handoff

Updated before the end of every long session (AGENTS.md §10). Overwrite the "Current state"
section; append to "Log".

## Current state — 2026-09-13

**Set up today:** governance docs only — no pipeline change, no GPU spend.

- `AGENTS.md` — permanent rules (plan-gate on GPU, review chain, worktrees, fix budgets, cadence).
- `rules.md` — RSNA knee-MRI specific hard rules + the statistical test for +1/-1.
- `experiments.md` — ledger; **baseline CV and public LB are still UNKNOWN and are blocking.**
- `handoff.md` — this file.

**Repo state:** git initialised on `main`, docs + notebooks committed (`.gitignore` excludes the
competition CSVs, `work/`, `cache/`, `worktrees/`). Not pushed yet — waiting on the private
GitHub repo URL from Vaibhav (`gh` is not installed on this Mac, so the repo is created by hand).

**What the next session must do first (in order):**
1. Confirm the metric, runtime limit, and external-data rules on the competition page
   (everything marked **[verify]** in rules.md).
2. Run `rsna-starter.ipynb` end-to-end to produce *our own* CV number on the 58 gold studies,
   with repeated K-fold over ≥5 seeds. Record it in experiments.md with the commit hash.
3. Submit once to get *our own* public LB number. Record it.
4. Only then open the first experiment worktree.

**Decisions made 2026-09-13:**
- Baseline is measured by Vaibhav running the notebook on Kaggle; Claude logs the numbers here.
- GitHub: private repo created by Vaibhav, URL pending; then `git remote add origin … && git push -u origin main`.
- Worktrees live at `RSNA/worktrees/<exp-id>/` (gitignored).

**Open questions for Vaibhav:**
- The private GitHub repo URL.
- Kaggle CLI credentials available for automated submission, or submit manually?

## Log

- **2026-09-13** — created AGENTS.md, rules.md, experiments.md, handoff.md. Data inspected:
  4,407 train studies, 58 gold-labelled, 12 targets, multilingual reports, series metadata with
  plane/fluid-sensitive/fat-suppression flags. Two notebooks present: a copied public
  inference-only ensemble (reported 0.936) and a runnable starter pipeline.
