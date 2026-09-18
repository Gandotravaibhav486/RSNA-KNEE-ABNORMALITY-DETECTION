#!/usr/bin/env bash
# await_quota.sh — push exp-32 stage 0 and stage 1 as soon as the weekly GPU quota resets.
#
# The reset is a rolling weekly window whose exact time is only shown in the Kaggle UI, so this
# does not try to schedule against it: it retries, and a refusal IS the signal that the quota is
# still exhausted (the same trick `exp.sh queue` uses for the 2-session cap).
#
# Both stages were approved by Vaibhav on 2026-09-18 (plans/exp-32-b2-convnext.md).
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
LOG=results/await_quota.log
export CACHE_KERNEL_OVERRIDE=vaibhav486/rsna-knee-cache-build-p2

say() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

stage0_done=0
stage1_done=0
say "waiting for the GPU quota to reset; retrying every 15 min for up to 20 h"

for attempt in $(seq 1 80); do
  if [ "$stage0_done" = 0 ]; then
    if out=$(./scripts/exp.sh screen exp-30-r18-lr5e5 '{"LR_BACKBONE":5e-05}' 2>&1); then
      stage0_done=1; say "STAGE 0 PUSHED — exp-30-r18-lr5e5 (the LR control)"
    else
      say "stage 0 refused (attempt $attempt): $(echo "$out" | tail -1)"
    fi
  fi
  if [ "$stage1_done" = 0 ] && [ "$stage0_done" = 1 ]; then
    if out=$(./scripts/exp.sh run exp-32-b2-convnext \
             '{"BACKBONE":"convnext_tiny","LR_BACKBONE":5e-05}' 2>&1); then
      stage1_done=1; say "STAGE 1 PUSHED — exp-32-b2-convnext (the full gold run)"
    else
      say "stage 1 refused (attempt $attempt): $(echo "$out" | tail -1)"
    fi
  fi
  [ "$stage0_done" = 1 ] && [ "$stage1_done" = 1 ] && { say "both stages running"; exit 0; }
  sleep 900
done
say "GAVE UP after 20 h — stage0=$stage0_done stage1=$stage1_done. Push by hand."
exit 1
