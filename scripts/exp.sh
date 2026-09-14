#!/usr/bin/env bash
# exp.sh — run one experiment end to end on Kaggle, isolated from every other experiment.
#
#   ./scripts/exp.sh new    <exp-id>            # git worktree + branch, isolated working copy
#   ./scripts/exp.sh push   <exp-id> <nb> [cpu] # push to its own kernel and start the run
#   ./scripts/exp.sh watch  <exp-id>            # poll until the run ends
#   ./scripts/exp.sh fetch  <exp-id>            # pull log + results json into results/
#   ./scripts/exp.sh status                     # every experiment kernel, one line each
#
# Parallelism: each experiment is its own kernel, so N experiments = N invocations of `push`.
# They run concurrently on Kaggle's side, subject to the account's session limit and GPU quota.
set -euo pipefail

KAGGLE=${KAGGLE:-/Applications/anaconda3/bin/kaggle}
USER_SLUG=${KAGGLE_USER:-vaibhav486}
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CACHE_KERNEL="$USER_SLUG/rsna-knee-cache-build-p1"
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
  "dataset_sources": ["$WEIGHTS_DS"],
  "kernel_sources": ["$CACHE_KERNEL"],
  "model_sources": [],
  "version_notes": "$id"
}
JSON
  (cd "$dir" && "$KAGGLE" kernels push -p . "${accel[@]}") | tail -1
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
  "$KAGGLE" kernels output "$ref" -p "$out" >/dev/null 2>&1 || true
  # keep the small artefacts, drop the multi-GB caches a run may have written
  find "$out" -name '*.npz' -delete 2>/dev/null || true
  find "$out" -type d -name 'cache_*' -exec rm -rf {} + 2>/dev/null || true
  echo "results/$id:"; ls -la "$out" | tail -n +2
}

cmd_status() {
  printf '%-34s %s\n' KERNEL STATUS
  "$KAGGLE" kernels list --user "$USER_SLUG" --page-size 50 2>/dev/null \
    | awk 'NR>2 {print $1}' | grep -E 'rsna-knee' | while read -r ref; do
      printf '%-34s %s\n' "${ref##*/}" "$("$KAGGLE" kernels status "$ref" 2>&1 | sed 's/.*status //;s/"//g' | tr -d '\n')"
    done
}

case "${1:-}" in
  new)    cmd_new "$2" ;;
  push)   cmd_push "$2" "$3" "${4:-gpu}" ;;
  watch)  cmd_watch "$2" ;;
  fetch)  cmd_fetch "$2" ;;
  status) cmd_status ;;
  *) sed -n '2,14p' "$0"; exit 1 ;;
esac
