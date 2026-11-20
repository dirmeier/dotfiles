Spike on typed artefact extraction: email draft, calendar event and task list.

- **Question:** How well does Gemma 4 E2B (Q8) pick the right type for an action in a chunked meeting transcript? A cloud model (claude-haiku-5-5) gives the ceiling.
- **Method:** Planted sentences go into real QMSum transcripts, so the right type is known. A judge model scores the items (round 1 judge not recorded; round 2 judge `gpt-6-luna`). Numbers come from the held-out half: 90 planted moments that no fix was tuned on.
- **Fixes tried:** a prompt change, a schema change (date and time fields), a separate extraction pass, a small extract for the second call of the separate pass, and one second call per chunk instead of one per action.
- **Code:** a throwaway runner, scoring and report in `experiments/334-typed-artefact-routing`.

**Result: use a separate extraction pass with one second call per chunk. That call gets only the quoted sentences with 3 lines on each side.**

## Round 1: preliminary analysis

The product runs on a phone, so calls must stay bounded by the number of chunks. This design makes at most 2 calls per chunk.

Calls, prompt tokens and time are per transcript. Time is how long Gemma took on the Mac, in seconds. Nobody measured a phone.

| Arm | Routing | Fields | Calls | Prompt tokens | Time on the Mac | Verdict |
|---|---|---|---|---|---|---|
| baseline | 57% | 50% | 4.0 | 21,547 | 54 s | – |
| prompt change | 50% | 38% | 4.0 | 17,703 | 40 s | INVALIDATED |
| schema change | 59% | 51% | 4.0 | 21,555 | 56 s | PARTIAL |
| separate pass, whole chunk, one call per action | 72% | 65% | 17.1 | 71,758 | 116 s | VALIDATED |
| separate pass, small extract, one call per action | 72% | 70% | 17.1 | 30,593 | 86 s | VALIDATED |
| **separate pass, small extract, one call per chunk (batch)** | 72% | 66% | 7.9 | 26,431 | 75 s | VALIDATED |
| cloud ceiling | 89% | 97% | 1.0 | 23,562 | not recorded | – |

- **Batch against the baseline:** routing +15.6 points (95% interval +4.4 to +26.7) and fields +15.6 points (interval +2.8 to +28.3). Both are above the run-to-run spread of the baseline (4.4 and 2.2 points). The price is 2.0 times the calls, 1.2 times the prompt tokens and 1.4 times the time.
- **Batch against the per-action small extract:** PARTIAL. Fields are 4.4 points lower (interval -8.9 to -0.6). Calls fall from 17.1 to 7.9 and time from 86 s to 75 s. The per-action version stays as an alternative, but its calls grow with every action found.
- **Time on the Mac, per transcript:** baseline 54 s, prompt change 40 s, schema change 56 s, whole chunk 116 s, per-action small extract 86 s, batch 75 s. Cutting the calls from 17.1 to 7.9 saved only 11 s.
- **Where the gap sits:** Gemma mostly misses moments (18 of 90 with the separate pass) and rarely picks the wrong type. Dates and times are the weakest field: 44% baseline, 52% batch, 60% per-action small extract, 100% cloud.
- **Format:** the batch run parsed 111 of 120 chunks (92.5%), below the 95% target. Two chunks failed because Gemma wrote Python `None` in the route call. Seven failed because the reply held one object too few, which leaves 7 of 390 actions with empty fields.
- **Not tested:** a parser that accepts `None` was checked on the two saved replies only. Its effect on the numbers was not measured. It is at most 2 chunks of 120. No further runs were made.
- **Limits:** 90 moments per arm, one run and one variant per fix, one extract size. The planted sentences are our own wording. Gemma reads chunks and the cloud model reads the whole transcript. The cloud call time was not recorded.
- **Written recommendation:** [RECOMMENDATION.md](https://github.com/Logitech/vnv-nexo-benchmark/blob/baf0e381/experiments/334-typed-artefact-routing/RECOMMENDATION.md) holds both rounds.

## Round 2: builds on the prior analysis above

Round 2 builds on the round 1 analysis above. It adds new test sentences, a second judge check on a sample, and a full model map. The full write-up is in [RECOMMENDATION.md](https://github.com/Logitech/vnv-nexo-benchmark/blob/baf0e381/experiments/334-typed-artefact-routing/RECOMMENDATION.md).

### Models by job

| Job | Model | Where it runs |
|---|---|---|
| Baseline and batch: find and sort planted moments | Gemma 4 E2B (small local model file) | Local (Mac) |
| Ceiling: one cloud call per transcript | `claude-haiku-5-5` | Cloud |
| Test sentence author | `claude-haiku-5-5` (188 sentences), `gemini-3.8-flash` (190) | Cloud |
| Main scoring judge (round 2) | `gpt-6-luna` | Cloud |
| Second judge (cross-check only) | `gemini-3.8-flash` for Haiku sentences; `claude-haiku-5-5` for Gemini sentences | Cloud |
| Main scoring judge (round 1) | Not recorded | Unknown |

### Round 2 results by level (all types)

| Arm | Found | Right type given found | Both | Fields given right type | Extra items per transcript |
|---|---|---|---|---|---|
| Baseline | 68% (131/192) | 66% (87/131) | 45% (87/192) | 86% | 8.06 |
| Batch | 79% (151/192) | 81% (123/151) | 64% (123/192) | 86% | 11.72 |
| Ceiling | 81% (155/192) | 99% (154/155) | 80% (154/192) | 96% | 4.14 |

### Difficulty levels

The author of each test sentence set its level. A model score did not. Level 1 has clear wording. Level 3 is the hardest.

| Type | Level 1 | Level 2 | Level 3 |
|---|---|---|---|
| calendar_event | Scheduling verb, person, day and time | No scheduling verb, or time in spoken form | Time vague or missing, or phrased as someone's to-do |
| email_draft | "Email" or "send a message", recipient, subject | Other words for a message | A message that proposes a meeting |
| task | Owner, action, due date | Owner or due date implied | Action sits next to a meeting but is a task |
| followup_ai | Question with no owner | Wondering aloud | Person named near the question, but nobody is asked |
| none | Plain fact in the past | Decision already made | Sounds like an action, but is not one |

Both, by type and level. Each cell counts moments out of 16. The `none` rows count false alarms, so lower is better.

| Type | Level | Baseline | Batch | Ceiling |
|---|---|---|---|---|
| calendar_event | 1 | 11/16 (69%) | 14/16 (88%) | 16/16 (100%) |
| calendar_event | 2 | 9/16 (56%) | 16/16 (100%) | 15/16 (94%) |
| calendar_event | 3 | 6/16 (38%) | 9/16 (56%) | 16/16 (100%) |
| email_draft | 1 | 12/16 (75%) | 15/16 (94%) | 16/16 (100%) |
| email_draft | 2 | 7/16 (44%) | 8/16 (50%) | 14/16 (88%) |
| email_draft | 3 | 9/16 (56%) | 15/16 (94%) | 16/16 (100%) |
| task | 1 | 6/16 (38%) | 14/16 (88%) | 15/16 (94%) |
| task | 2 | 10/16 (63%) | 12/16 (75%) | 13/16 (81%) |
| task | 3 | 8/16 (50%) | 13/16 (81%) | 13/16 (81%) |
| followup_ai | 1 | 6/16 (38%) | 5/16 (31%) | 10/16 (63%) |
| followup_ai | 2 | 1/16 (6%) | 2/16 (13%) | 3/16 (19%) |
| followup_ai | 3 | 2/16 (13%) | 0/16 (0%) | 7/16 (44%) |
| none (false alarms) | 1 | 0/16 | 2/16 | 0/16 |
| none (false alarms) | 2 | 1/16 | 2/16 | 0/16 |
| none (false alarms) | 3 | 3/16 | 5/16 | 0/16 |

Totals by level, all types, Both:

| Level | Baseline | Batch | Ceiling |
|---|---|---|---|
| 1 | 55% | 75% | 89% |
| 2 | 42% | 59% | 70% |
| 3 | 39% | 58% | 81% |

- Level 1 is the easiest level for every arm.
- Level 2 is the lowest level for the ceiling (70%). Level 3 is the lowest for baseline and batch, by 1 to 3 points.
- Follow-up items are weak at every level for every arm. The ceiling gets 3 of 16 at level 2 and 7 of 16 at level 3.
- Each cell holds 16 moments. One moment is 6 points, so a gap of one or two moments is noise.

### Round 2 "Both" by type

| Type | Baseline | Batch | Ceiling |
|---|---|---|---|
| calendar_event | 54% (26/48) | 81% (39/48) | 98% (47/48) |
| email_draft | 58% (28/48) | 79% (38/48) | 96% (46/48) |
| task | 50% (24/48) | 81% (39/48) | 85% (41/48) |
| followup_ai | 19% (9/48) | 15% (7/48) | 42% (20/48) |
| none (false alarm rate) | 8% (4/48) | 19% (9/48) | 0% (0/48) |

### Ceiling by sentence author

| Author of sentence | Found | Both | Fields given right type |
|---|---|---|---|
| `claude-haiku-5-5` | 81% (78/96) | 81% (78/96) | 94% |
| `gemini-3.8-flash` | 80% (77/96) | 79% (76/96) | 99% |

The gap is 2 points in the direction a self-favoring model would show. The intervals are about ±10 points, so the gap is too small to call.

### Judge cross-check (60 calendar and email moments)

| Arm | Same score from both judges | Mean field score, main (`gpt-6-luna`) | Mean field score, second judge | Gap (points) | Above 3 points? |
|---|---|---|---|---|---|
| Baseline | 90% (54/60) | 0.41 | 0.37 | 3.3 | Yes |
| Batch | 88% (53/60) | 0.63 | 0.62 | 1.7 | No |
| Ceiling | 90% (54/60) | 0.91 | 0.91 | 0.0 | No |

This measures agreement between two judges. It does not measure accuracy. It checks field scores only, not routing.

### Conclusions

- The ceiling is best on every routing measure. It makes no false alarms on `none` moments.
- Batch finds more than baseline but makes more false alarms (19% against 8%).
- Follow-up items are weak for all arms (ceiling finds 42%).
- The main judge agrees with a second judge on 88% to 90% of moments. No human check has been done yet.


Closes #334
