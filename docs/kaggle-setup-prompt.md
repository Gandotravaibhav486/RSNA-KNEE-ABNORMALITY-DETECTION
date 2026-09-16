# Kaggle competition setup prompt

Paste at the start of a new competition, after putting the data in the working directory.

---

You are setting up a disciplined experiment programme for a Kaggle competition. Work in this
directory. Do the setup below in order, and do not train anything until step 4.

**1. Establish the facts before any code.**
Read the competition's Overview, Evaluation, Rules and Code Requirements pages and write
`rules.md`: the exact metric and its formula, runtime and hardware limits, whether internet is
disabled at rerun, what external data and pretrained weights are permitted, submission filename and
format, every deadline, the daily submission cap, and any second prize track (efficiency, etc.).
Mark anything you could not confirm as `[verify]` rather than assuming it. Also read the discussion
board and the top public notebooks *now*, not later — record what other people have already measured,
because some of your planned experiments will already have been answered.

**2. Write the rules you will work under.**
`AGENTS.md`: no GPU spend without a written plan I approve (hypothesis, expected effect, cost, and
the result that would kill it); every change lands as a notebook that is actually run; a fix budget
per change type, after which you stop rather than keep debugging; verdicts of +1 / −1 / null /
invalid, decided against a stated significance bar; and a promotion gate for what is allowed to
become the new baseline.

**3. Set up the bookkeeping.**
`experiments.md` — one row per experiment including the rejected and the abandoned, so nothing is
proposed twice. `agent-log.md` — append-only, one line per action, with a column for where you are
stuck; three stuck entries in a row means escalate to me. `handoff.md` — rewritten before the end
of every session. Version axes for anything that changes results without changing the code path
(preprocessing version, training version); two results are only comparable when their versions match.

**4. Measure the baseline, and record it.**
Get a real cross-validation number and a real leaderboard number from a runnable pipeline, with the
commit that produced them. Never compare against a baseline that was never measured.

**5. Then measure the instrument — this is the step most people skip.**
Establish the noise floor of your validation before trusting any result from it: repeated folds,
multiple seeds, and a **paired** bootstrap between two runs on the same samples. Pairing is typically
worth several times the sample size and costs nothing if you save every run's predictions to disk.
If the trustworthy labels are few, build a larger proxy metric (out-of-fold agreement with weak or
derived labels over the whole corpus) and validate it on a **known answer** — a comparison whose true
direction you already know from the leaderboard. Report every change against whichever instrument can
actually resolve an effect of that size, and say which one you used.

**6. Put the guards in before the experiments, not after.**
- A preflight assertion that fails a run *before* the expensive step if its inputs are missing or
  wrong. Every silent failure costs a full run; every guard costs a second.
- A static lint over each notebook before it is submitted to run — local checks skip branches that
  only execute on the real hardware, so undefined names hide there.
- Save predictions after every fold or arm, never only at the end. Runs die after the expensive part.
- Before any submission, verify the file is not a placeholder or fallback.

**7. Learn the platform's constraints empirically and write them down.**
Accelerator selection, concurrent session limits, quota, where inputs are actually mounted, when
logs become visible, how caches are attached. Discover each once, record it, never rediscover it.

**8. How to run experiments after that.**
Cheap screening runs to decide questions; expensive full runs only to convert a decided question into
a submission. CPU-only work on CPU machines where no GPU quota applies. One isolated working
directory and one compute job per experiment. State the kill criterion before starting, and when a
result contradicts the mechanism you proposed, say so plainly — a gain through the wrong mechanism is
a different finding from the one you were testing.

**Throughout:** report what happened, not what was hoped. A negative result that is cleanly measured
is worth more than a positive one that is not. If you notice you are about to claim a gain that your
own significance bar cannot support, say that instead.
