# exp-20260913-03-coverage-ceiling

- **Type:** paper (0 GPU) · **Fix budget:** 3 · **Plan gate:** not required
- **Run before exp-02** — it decides whether exp-02 is worth doing.

## Question

For each target, if the image model learned the weak labels *perfectly*, what macro AUC would it
reach? That is the ceiling imposed by the labels, and it separates two very different diagnoses for
a weak target: the labels are too thin (fix labels) vs. the labels are fine and the model is not
using them (fix the model).

## Method

On the 58 gold studies we know both the truth and what the labeller said, so per target we can
measure the weak label's precision, recall and coverage. Then, for each target, simulate a learner
that reproduces the weak labels exactly on the 4,349 reported studies and score that simulation
against gold. Report the ceiling next to the measured model AUC and the gap between them.

## Success / failure

| Verdict | Condition |
|---|---|
| **Success (+1)** | Produces a per-target ceiling **with stated uncertainty**, and the ceiling-vs-actual gap **reorders the experiment queue** — i.e. at least one target moves between "label-limited" and "model-limited", changing what we build next. |
| **Success, null result** | Ceilings come back uniformly close to the measured AUCs. That is a real answer: labels are not the binding constraint, and priority shifts to the model. Still `+1` — it redirects the budget. |
| **Failure (−1)** | The estimate's uncertainty is wider than the gaps it is meant to resolve, so no target can be classified either way. Record why (almost certainly n=58 per target), and stop. |
| **Invalid** | Ceiling computed on studies the labeller had already been tuned on, or precision/recall estimated without accounting for the "unknown" cells. |

**This experiment produces no CV number, so the ±2σ rule in AGENTS.md §13 does not apply to it.**
Its output is a decision, and it is judged on whether the decision is well-supported.

## Kill criterion

If per-target positive counts (9–35) make every ceiling estimate span more than ±0.15 AUC,
abandon the per-target framing and report only the macro-level conclusion.
