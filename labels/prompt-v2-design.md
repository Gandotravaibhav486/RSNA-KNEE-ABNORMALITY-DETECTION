# Label prompt v2 — design, from a published labeller

exp-12 failed because "not addressed" had no cost: Qwen2.5-7B used it for **74.9%** of cells and
emitted an explicit negative 1.5% of the time. While evaluating a blend, the `pilkwang` dataset
turned out to ship its **labelling script** (`api_labeler.py`, mirrored here as
`reference-api_labeler.py`) — the provenance the other public keys withhold. Its design answers our
failure directly.

## What it does differently

1. **Three-way verdict, not a probability.** `YES` / `NO` / `UNK`, plus a severity 0–3. Asking for a
   number invites the model to hedge at 0.5; asking for a verdict forces a reading.
2. **Two rules that name our exact failure modes:**
   - *"A structure described as normal or intact is NO, not UNK."* — our v1 collapsed these.
   - *"A finding the report never names is UNK, not NO."* — the opposite error, which our regex made.
   - *"Medial and lateral are distinct. If the report names one, the other is not thereby answered."*
   - *"Judge only what the report states. Do not infer a finding from a related one."*
3. **Schema-constrained output, not parsed text.** The reply is constrained to the twelve keys with
   enum verdicts, so "there is no reply that parses into a partial answer". Our v1 parsed JSON out of
   free text with a 0.3% failure rate — small, but silent when it happens.
4. **Instructions hoisted into a cacheable system block**, report as the only varying part.
5. **Bulk submission.** Their note: a local model runs "roughly eighteen seconds a report… affordable
   while a prompt is being tuned and unaffordable across the corpus". Ours was 9.57 s/report —
   the same wall, hit at the same place.

## What exp-14 should therefore be

- Verdict + severity schema, mapped to a probability, instead of asking for a probability.
- The four judgement rules above, quoted in substance.
- Batched generation, and an output contract short enough that generation is not the bottleneck.
- Pilot gate unchanged: must beat **0.80** on gold-test before any full-corpus run.

Note their key scores **0.8658** on our gold split — below `v4_blend`'s 0.8927 — and correlates 0.891
with it, so blending the two is worth **+0.0004** (noise). The value here is the **method**, not the
labels.
