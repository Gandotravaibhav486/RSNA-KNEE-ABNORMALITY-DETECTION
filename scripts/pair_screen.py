"""Paired bootstrap between two screening runs, offline and free.

Both runs write screen_oof_*.npy over the SAME study order (all_train_uids) with the SAME folds
and SCREEN_SEED, so the arrays are comparable study-by-study. Pairing is worth several times the
sample size and costs no GPU (AGENTS.md; measured 4.4x on gold, tighter still here).

    python3 scripts/pair_screen.py <new.npy> <ref.npy> [--n 2000]
"""
from __future__ import annotations
import json, re, sys, unicodedata
from pathlib import Path
import numpy as np
import pandas as pd
from sklearn.metrics import roc_auc_score

REPO = Path(__file__).resolve().parent.parent
TARGETS = ["ACL", "MCL", "Medial Meniscus", "Lateral Meniscus", "Medial OA", "Lateral OA",
           "PF OA", "Effusion", "Synovitis", "Baker's", "Contusion", "Fracture"]


def screening_pool() -> np.ndarray:
    """The study order both OOF arrays are indexed by: train.csv order, gold studies removed.

    The baseline drops studies the REGEX labeller cannot decide at all; that filter is what
    `usable` means, and it must be reproduced exactly or every row is misaligned."""
    train = pd.read_csv(next(REPO.glob("train*.csv")))
    train["StudyInstanceUID"] = train["StudyInstanceUID"].astype(str)
    gold_mask = train[TARGETS].notna().all(axis=1)
    src = json.loads((REPO / "notebooks/baseline.ipynb").read_text())
    labeller = "".join(src["cells"][8]["source"])
    g = {"np": np, "pd": pd, "re": re, "unicodedata": unicodedata,
         "TARGETS": TARGETS, "train": train}
    exec(labeller, g)                                   # the labeller cell, verbatim
    weak = g["weak_labels"]
    usable = weak[TARGETS].notna().any(axis=1) & ~gold_mask.values
    return weak.loc[usable, "StudyInstanceUID"].to_numpy()


def weak_truth(uids: np.ndarray, key_csv: Path) -> np.ndarray:
    """The L1 key, binarised. Exactly 0.5 means 'the report does not address this' — not a label."""
    llm = pd.read_csv(key_csv)
    llm["StudyInstanceUID"] = llm["StudyInstanceUID"].astype(str)
    soft = llm.set_index("StudyInstanceUID").reindex(uids)[TARGETS].values.astype(np.float32)
    return np.where(soft > 0.5, 1.0, np.where(soft < 0.5, 0.0, np.nan)).astype(np.float32)


def screen_auc(y: np.ndarray, p: np.ndarray, idx: np.ndarray) -> float:
    aucs = []
    for j in range(len(TARGETS)):
        yy, pp = y[idx, j], p[idx, j]
        m = np.isfinite(yy) & np.isfinite(pp)
        if m.sum() < 20 or len(np.unique(yy[m])) < 2:
            continue
        aucs.append(roc_auc_score(yy[m], pp[m]))
    return float(np.mean(aucs)) if aucs else float("nan")


def main() -> None:
    new_p, ref_p = Path(sys.argv[1]), Path(sys.argv[2])
    n_boot = int(sys.argv[sys.argv.index("--n") + 1]) if "--n" in sys.argv else 2000
    new, ref = np.load(new_p), np.load(ref_p)
    assert new.shape == ref.shape, f"{new.shape} vs {ref.shape} — not the same pool"

    uids = screening_pool()
    assert len(uids) == len(new), f"pool {len(uids)} != OOF rows {len(new)} — alignment is wrong"
    key = next((REPO.parent).glob("**/llm_labels_v4_blend.csv"), None) or Path(sys.argv[-1])
    y = weak_truth(uids, key)

    full = np.arange(len(uids))
    a, b = screen_auc(y, new, full), screen_auc(y, ref, full)
    print(f"{new_p.name:<40} {a:.4f}")
    print(f"{ref_p.name:<40} {b:.4f}")
    print(f"{'marginal delta':<40} {a - b:+.4f}")

    rng = np.random.default_rng(0)
    d = np.array([screen_auc(y, new, i) - screen_auc(y, ref, i)
                  for i in (rng.integers(0, len(uids), len(uids)) for _ in range(n_boot))])
    print(f"\nPAIRED over {len(uids)} studies, {n_boot} resamples:")
    print(f"  delta {d.mean():+.4f}   2 sigma {2 * d.std():.4f}   "
          f"CI [{np.percentile(d, 2.5):+.4f}, {np.percentile(d, 97.5):+.4f}]   "
          f"P(delta>0) {(d > 0).mean():.3f}")

    print("\nper target:")
    for j, t in enumerate(TARGETS):
        m = np.isfinite(y[:, j])
        if m.sum() < 20 or len(np.unique(y[m, j])) < 2:
            print(f"  {t:<18} —"); continue
        va = roc_auc_score(y[m, j], new[m, j]); vb = roc_auc_score(y[m, j], ref[m, j])
        print(f"  {t:<18} {vb:.3f} -> {va:.3f}   {va - vb:+.3f}")


if __name__ == "__main__":
    main()
