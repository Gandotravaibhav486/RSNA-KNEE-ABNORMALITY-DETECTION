# rules.md — RSNA Knee MRI Abnormality Detection (competition-specific)

Every code change is checked against this file before acceptance (AGENTS.md §2).
Facts marked **[verify]** were inferred from the local data/notebooks and must be confirmed
against the official competition page before they are relied on.

## Competition facts

- **Task:** multi-label classification, 12 findings per study — ACL, MCL, Medial Meniscus,
  Lateral Meniscus, Medial OA, Lateral OA, PF OA, Effusion, Synovitis, Baker's, Contusion, Fracture.
- **Unit of prediction:** one row per `StudyInstanceUID`, 12 probability columns in `[0,1]`.
- **Train:** 4,407 studies. **Only 58 are fully labelled ("gold").** The other 4,349 have a
  free-text `Report` (multilingual — Spanish-dominant) and no labels.
- **Series metadata:** `train_series.csv` / `test_series.csv` give `Fluid_Sensitive`,
  `Fat_Suppression`, `Anatomical_Plane` per series. Studies have a variable bag of series.
- **Metric:** macro / column-wise ROC AUC **[verify]**.
- **Submission:** notebook rerun against a hidden test set; the visible `test.csv` has 3 studies.

## Hard rules (violation = automatic reject)

1. **Reports are training-time only.** `Report` does not exist at test time. No feature, label,
   threshold, or calibration may read a test-side report. Any text model is a *label generator*
   or a *teacher*, never an inference-time input.
2. **The 58 gold studies are never trained on.** They are the validation anchor. Any experiment
   that fits on gold — including threshold tuning, blend-weight search, or early stopping —
   must do it inside a nested CV over the 58, and must report the nested number, not the fitted one.
3. **No dependency on the visible test set.** The code must handle studies it has never seen,
   any number of them, missing planes, missing series, corrupt DICOM. Never index `test.csv` by
   position, never assume 3 rows, never cache by test UID.
4. **Submission contract:** exactly the test UIDs, exactly the 12 target columns in the sample
   order, float in `[0,1]`, no NaN. A `0.5`-everywhere fallback must survive any per-study failure —
   one bad DICOM must not fail the submission.
5. **Determinism:** seed set for numpy/torch/python; the same notebook on the same input yields
   the same CV number, or the difference is reported as run-to-run noise.
6. **No leakage across studies within a split** — split at `StudyInstanceUID` level, never at
   series or slice level.
7. **Runtime budget:** inference must fit the competition's notebook time limit **[verify]** with
   ≥25% headroom, measured on the visible test path scaled to the expected hidden test size.
8. **No external data or pretrained weights that the competition disallows** **[verify]** — check the
   rules page before adding any Kaggle dataset dependency, and record the dataset URL in the experiment.

## Statistical rules (how we decide +1 / -1)

- With **58 gold studies**, the standard error on a macro AUC is large. A CV delta is only called
  **significant** when it survives:
  - repeated CV (≥5 seeds) on the gold set, and
  - a paired comparison (same folds, same seeds) against the baseline, and
  - `delta > 2 × std(delta across seeds)`.
- Any delta smaller than that is reported as **noise → -1**, no matter how good it looks.
- Because gold is tiny, a **second validation signal is mandatory** for architecture/loss changes:
  agreement with weak labels on held-out reported studies, or rank correlation with the public LB.
- **Public LB is a 1-bit-per-submission oracle.** Never tune on it. Treat LB/CV disagreement as
  information about the split, and record it.

## Label rules

- Weak labels from reports carry a known error rate. Every experiment using them states the
  labeller version (`labels/v<N>.md`) and its measured macro AUC against the 58 gold studies.
- "Unknown" is not 0. Unknown cells are masked out of the loss, never filled with 0 or 0.5,
  unless the experiment is explicitly testing fill strategy.
- Negation handling is part of the labeller contract — "sin rotura" / "no tear" must not become a 1.
  Any labeller change ships with negation unit tests.

## Cost rules

- Building study tensors from DICOM is the expensive CPU step: cache it once per worktree
  (`cache/`), key by `(study_uid, preprocessing_version)`. A preprocessing change bumps the version —
  it never silently reuses a stale cache.
- Prefer experiments that reuse an existing cache and existing OOF predictions.
