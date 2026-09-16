#!/usr/bin/env bash
# exp.sh — run one experiment end to end on Kaggle, isolated from every other experiment.
#
#   ./scripts/exp.sh new    <exp-id>            # git worktree + branch, isolated working copy
#   ./scripts/exp.sh push   <exp-id> <nb> [cpu] # push to its own kernel and start the run
#   ./scripts/exp.sh watch  <exp-id>            # poll until the run ends
#   ./scripts/exp.sh fetch  <exp-id>            # pull log + results json into results/
#   ./scripts/exp.sh status                     # every experiment kernel, one line each
#   ./scripts/exp.sh queue  <exp-id> <nb>       # wait for a free GPU slot, then push
#
# Kaggle allows at most 2 concurrent batch GPU sessions (measured 2026-09-14: a third push is
# refused with "Maximum batch GPU session count of 2 reached"). CPU pushes are not subject to it.
#
# Parallelism: each experiment is its own kernel, so N experiments = N invocations of `push`.
# They run concurrently on Kaggle's side, subject to the account's session limit and GPU quota.
set -euo pipefail

KAGGLE=${KAGGLE:-/Applications/anaconda3/bin/kaggle}
USER_SLUG=${KAGGLE_USER:-vaibhav486}
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CACHE_KERNEL="${CACHE_KERNEL_OVERRIDE:-$USER_SLUG/rsna-knee-cache-build-p1}"
WEIGHTS_DS="$USER_SLUG/timm-backbones-offline"
COMP="rsna-knee-abnormality-detection"

kernel_ref() { echo "$USER_SLUG/rsna-knee-$1"; }

cmd_new() {
  local id=$1
  git -C "$REPO" worktree add "$REPO/worktrees/$id" -b "$id" 2>/dev/null \
    || git -C "$REPO" worktree add "$REPO/worktrees/$id" "$id"
  echo "worktree: $REPO/worktrees/$id   branch: $id"
  echo "Work only inside it (AGENTS.md §9). Its work/, cache/, subs/ are its own."
}

cmd_push() {
  local id=$1 nb=$2 hw=${3:-gpu} dir
  # EXTRA_DS="owner/slug,owner/slug2" attaches more datasets to this run
  local DATASETS="\"$WEIGHTS_DS\""
  if [ -n "${EXTRA_DS:-}" ]; then
    IFS="," read -ra _ds <<< "$EXTRA_DS"
    for d in "${_ds[@]}"; do DATASETS="$DATASETS, \"$d\""; done
  fi
  local KERNELS="\"$CACHE_KERNEL\""
  [ "${NO_CACHE:-0}" = 1 ] && KERNELS=""
  local MODELS=""
  if [ -n "${MODEL_SRC:-}" ]; then MODELS="\"$MODEL_SRC\""; fi
  dir=$(mktemp -d)
  cp "$nb" "$dir/$(basename "$nb")"
  local gpu=true accel=(--accelerator NvidiaTeslaT4)
  if [ "$hw" = cpu ]; then gpu=false; accel=(); fi
  # NvidiaTeslaT4 is the only usable GPU enum: P100 is sm_60 and this PyTorch cannot run on it.
  cat > "$dir/kernel-metadata.json" <<JSON
{
  "id": "$(kernel_ref "$id")",
  "title": "Rsna Knee $id",
  "code_file": "$(basename "$nb")",
  "language": "python",
  "kernel_type": "notebook",
  "is_private": true,
  "enable_gpu": $gpu,
  "enable_internet": false,
  "competition_sources": ["$COMP"],
  "dataset_sources": [$DATASETS],
  "kernel_sources": [$KERNELS],
  "model_sources": [$MODELS],
  "version_notes": "$id"
}
JSON
  # Static check first: our local harness skips every `if HAVE_IMAGES:` branch, so a missing name
  # inside one is invisible until it costs a Kaggle run. exp-10 v1 died on `preflight` that way.
  if ! "${PY:-/Applications/anaconda3/bin/python3}" "$REPO/scripts/lint_nb.py" "$nb"; then
    echo "lint failed — not pushing" >&2; return 1
  fi
  local out
  out=$( (cd "$dir" && "$KAGGLE" kernels push -p . ${accel[@]+"${accel[@]}"}) 2>&1 | tail -1 )
  echo "$out"
  case "$out" in
    *"error"*|*"Maximum batch"*)
      echo "NOT STARTED: $(kernel_ref "$id")" >&2
      return 1 ;;
  esac
  mkdir -p "$REPO/results"
  grep -qxF "$(kernel_ref "$id")" "$REPO/results/kernels.txt" 2>/dev/null \
    || echo "$(kernel_ref "$id")" >> "$REPO/results/kernels.txt"
  echo "pushed: $(kernel_ref "$id")  [$hw]"
}

cmd_watch() {
  local id=$1 ref st
  ref=$(kernel_ref "$id")
  for _ in $(seq 1 240); do
    st=$("$KAGGLE" kernels status "$ref" 2>&1 | tr -d '\n')
    case "$st" in *COMPLETE*|*ERROR*|*cancel*) echo "$(date +%H:%M:%S) $st"; return 0 ;; esac
    sleep 30
  done
  echo "still running after 2 h — check manually"; return 1
}

cmd_fetch() {
  local id=$1 ref out
  ref=$(kernel_ref "$id")
  out="$REPO/results/$id"
  mkdir -p "$out"
  "$KAGGLE" kernels logs "$ref" > "$out/log.json" 2>/dev/null || true
  # kaggle skips files that already exist locally, so a re-fetch after a NEW VERSION silently
  # keeps the OLD artefacts. That produced a wrong paired comparison once. Clear them first.
  find "$out" -type f ! -name 'log.json' ! -name '*.log' -delete 2>/dev/null || true
  "$KAGGLE" kernels output "$ref" -p "$out" >/dev/null 2>&1 || true
  # keep the small artefacts, drop the multi-GB caches a run may have written
  find "$out" -name '*.npz' -delete 2>/dev/null || true
  find "$out" -type d -name 'cache_*' -exec rm -rf {} + 2>/dev/null || true
  echo "results/$id:"; ls -la "$out" | tail -n +2
}

cmd_status() {
  printf '%-38s %s\n' KERNEL STATUS
  [ -f "$REPO/results/kernels.txt" ] || { echo "(no pushes recorded yet)"; return 0; }
  while read -r ref; do
    [ -n "$ref" ] || continue
    printf '%-38s %s\n' "${ref##*/}" \
      "$("$KAGGLE" kernels status "$ref" 2>&1 | sed 's/.*status //;s/"//g' | tr -d '\n')"
  done < "$REPO/results/kernels.txt"
}

cmd_queue() {
  local id=$1 nb=$2 running dep
  # AFTER="owner/slug" blocks until that kernel is COMPLETE. A run whose cache is still building
  # will fail preflight on arrival — cheap, but it wastes a slot and confuses the log.
  if [ -n "${AFTER:-}" ]; then
    for _ in $(seq 1 240); do
      dep=$("$KAGGLE" kernels status "$AFTER" 2>&1 | tr -d '\n')
      case "$dep" in
        *COMPLETE*) echo "$(date +%H:%M:%S) dependency ready: $AFTER"; break ;;
        *ERROR*|*cancel*) echo "dependency FAILED: $AFTER — not launching $id" >&2; return 1 ;;
      esac
      sleep 60
    done
  fi
  for _ in $(seq 1 240); do
    running=$(cmd_status | grep -c RUNNING || true)
    if [ "$running" -lt 2 ]; then
      echo "$(date +%H:%M:%S) slot free ($running running) — pushing $id"
      cmd_push "$id" "$nb" gpu && return 0
    fi
    sleep 60
  done
  echo "no GPU slot freed within 4 h"; return 1
}

case "${1:-}" in
  new)    cmd_new "$2" ;;
  queue)  cmd_queue "$2" "$3" ;;
  push)   cmd_push "$2" "$3" "${4:-gpu}" ;;
  watch)  cmd_watch "$2" ;;
  fetch)  cmd_fetch "$2" ;;
  status) cmd_status ;;
  *) sed -n '2,14p' "$0"; exit 1 ;;
esac
