# Label prompt v1 — `own-llm-v1`

The prompt below is the whole labelling method. Published here because the public keys we compared
against (`stevenleehans`, `lixin73`) name no model and publish no prompt, so they cannot be
reproduced, corrected, or extended — see rules.md.

- **Model:** `Qwen2.5-7B-Instruct` (Kaggle Models `qwen-lm/qwen2.5/transformers/7b-instruct/1`,
  Apache-2.0, runs offline inside the competition notebook).
- **Decoding:** greedy (`do_sample=False`), `max_new_tokens=220`. Deterministic, so the key is
  reproducible from this repo alone.
- **Unit:** one report per call. No batching across studies, so one bad report cannot corrupt another.
- **Failure handling:** unparseable output → all twelve cells set to 0.5 and counted in the manifest.

## System prompt

```
You are a musculoskeletal radiologist reading knee MRI reports. Reports may be in Spanish,
English, German, Dutch, Croatian, French, Turkish or other languages. Answer only with JSON.
```

## User prompt

```
Read this knee MRI report and give the probability that each of the twelve findings is present
IN THIS KNEE, according to the report.

Report:
<<<REPORT>>>

Rules:
- Use a probability between 0 and 1 for each finding.
- Use exactly 0.5 when the report DOES NOT ADDRESS that finding. Silence is not a negative:
  0.5 means "the report does not say", not "absent".
- Use a LOW value (0.02-0.10) when the report explicitly states the structure is normal, intact,
  preserved or without tear. A negative statement is information — do not mark it 0.5.
- Use a HIGH value (0.80-0.99) when the report describes the finding as present.
- Osteoarthritis is graded per compartment. "Medial OA", "Lateral OA" and "PF OA" (patellofemoral,
  including retropatellar and trochlear) are separate findings: a statement about one compartment
  says nothing about the others.
- Cartilage loss, chondropathy, chondral thinning, osteophytes and joint-space narrowing all count
  as osteoarthritis in the compartment where they are described.
- "Contusion" means bone marrow oedema, bone bruise or contusion.
- Report your reading of the text only. Do not guess from what is statistically likely in a knee.

Answer with this JSON object and nothing else:
{"ACL": p, "MCL": p, "Medial Meniscus": p, "Lateral Meniscus": p, "Medial OA": p,
 "Lateral OA": p, "PF OA": p, "Effusion": p, "Synovitis": p, "Baker's": p,
 "Contusion": p, "Fracture": p}
```

## Design notes — each line answers something we measured

| rule | why it is there |
|---|---|
| `0.5` = not addressed | exp-03: our regex treated silence and negation identically; 25.4% of the public key's cells are 0.5 and that value carries real information |
| explicit low value for normality | exp-03's central finding: pooled false-positive rate 0.66 versus a 0.02 miss rate. The regex could barely say "no" — only 5–8% of decided OA cells were negative |
| compartment independence spelled out | our regex leaked medial statements into lateral; PF OA was the worst target at 0.537 |
| cartilage/chondropathy listed explicitly | the regex missed Spanish `condropatía` and `cartílago` entirely, which is why the three OA targets had the lowest coverage |
| "do not guess from what is likely" | a prior-following labeller would score well on prevalence and teach the model nothing |

## Gold discipline

The 58 gold studies are split **29 dev / 29 test** with a fixed seed. Prompt wording may only be
revised by looking at **gold-dev**. Every number reported for a prompt version is on **gold-test**,
which is looked at once per version. This is not as clean as a held-out set we never touch, but it
is the most honest thing available with 58 labelled studies, and it is stated openly.
