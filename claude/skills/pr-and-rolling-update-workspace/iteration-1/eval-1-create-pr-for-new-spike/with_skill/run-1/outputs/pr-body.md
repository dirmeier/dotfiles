This spike measures how well Gemma 4 E2B (Q8 GGUF, run with llama.cpp on a Mac) sorts meeting actions into the right artefact type (email draft, calendar event or task list item), and which of three fixes helps most: a prompt change, a schema change or a separate extraction pass.

## Status against the pass marks
| Metric | Target | Current status |
|---|---|---|
| Format (Q1) | At least 95% of chunk replies parse into valid items | Below target. Round 1 baseline: 100% parse, 79% valid items. Round 1 batch: 92.5% parse (111/120 chunks), valid items not computed. Round 2 batch: 97% parse, 1 of 192 moments lost to a parse failure. |
| Routing (Q2) | Gain over the baseline above the run-to-run spread (4.4 pp) and a 95% paired interval above zero | Met by the separate pass in round 1: 72% (65/90) against 57% (51/90), +15.6 pp, interval +4.4 to +26.7. |
| Leak (Q2) | Same rule, lower is better | PARTIAL in round 1: 2% (1/60) against 10% (6/60), +8.3 pp, interval +0.0 to +16.7. |
| Fields (Q3) | Gain over the baseline above the field spread (2.2 pp) and a 95% paired interval above zero | Met by the batch in round 1: 66% against 50%, +15.6 pp, interval +2.8 to +28.3. Round 2, given the right type: 86% for baseline (n=54) and batch (n=77), no gain. |
| Gap to the cloud ceiling (Q4) | Report whether the gap sits in routing or in fields | Round 1: ceiling 89% (80/90) routing and 97% fields, batch 72% and 66%. Most of the gap is missed moments (18 of 90 for the separate pass, 2 of 90 for the ceiling). Round 2: 64% (123/192) against 80% (154/192). |
| Small extract (Q5) | Prompt tokens and seconds fall, fields at most 2.2 pp below the whole-chunk version | VALIDATED in round 1: 30,593 against 71,758 prompt tokens and 86 s against 116 s per transcript, fields 70% against 65%. |
| One second call per chunk (Q6) | Calls and seconds fall, fields at most 2.2 pp below one call per action | PARTIAL in round 1: calls 7.9 against 17.1 and 75 s against 86 s per transcript, fields 66% against 70% (-4.4 pp, interval -8.9 to -0.6). |
| Second judge (R2-Q4) | Second judge moves the gap to the ceiling by at most 3 points | Round 2, 60 moments: 3.3 points for the baseline (above), 1.7 for batch, 0.0 for the ceiling. |

Round 1 numbers come from 90 planted moments in 30 held-out transcripts built from QMSum meetings, one run per fix and three runs of the baseline. Round 2 numbers come from 240 planted moments (192 with an action, 48 with none) in 80 transcripts, one run per arm. A planted moment is a sentence we put into a transcript on purpose, with one correct type.

## Current results
- **Recommendation:** use a separate extraction pass with one second call per chunk ("batch" below). The first call picks the type of each action in a chunk. The second call fills the fields of every action in that chunk, from the quoted sentences with 3 lines on each side. It costs 2.0 times the calls of the baseline (7.9 against 4.0 per transcript in round 1, 8.3 against 4.2 in round 2), and in round 1 1.2 times the prompt tokens and 1.4 times the seconds. The prompt change made routing worse. The schema change gave no gain beyond the spread.

### Round 1, three fixes on 90 held-out moments
The separate pass is VALIDATED, the prompt change is INVALIDATED and the schema change is PARTIAL. Each fix had one variant. Routing is the share of moments found and typed right. Leak is the share of the 60 calendar and email moments filed as a task list item (lower is better). Fields is the share of right details over those 60 moments, where a wrong type or a miss counts 0.

| Arm | Routing | Leak | Fields | Verdict |
|---|---|---|---|---|
| baseline | 57% (51/90) | 10% (6/60) | 50% | – |
| prompt change | 50% (45/90), -6.7 pp | 27% (16/60) | 38% | INVALIDATED |
| schema change | 59% (53/90), +2.2 pp | 8% (5/60) | 51% | PARTIAL |
| separate pass, whole chunk, one call per action | 72% (65/90), +15.6 pp, interval +4.4 to +26.7 | 2% (1/60) | 65%, +15.0 pp, interval +2.2 to +27.2 | VALIDATED |
| separate pass, small extract, one call per action | 72% (65/90) | 2% (1/60) | 70%, +20.0 pp, interval +7.2 to +32.8 | VALIDATED |
| separate pass, small extract, one call per chunk (batch) | 72% (65/90) | 2% (1/60) | 66%, +15.6 pp, interval +2.8 to +28.3 | VALIDATED |
| cloud ceiling, `claude-haiku-5-5` | 89% (80/90) | 0% (0/60) | 97% | – |

Cost per transcript on the Mac (30 held-out transcripts):

| Arm | Calls | Prompt tokens | Seconds |
|---|---|---|---|
| baseline | 4.0 | 21,547 | 54 |
| separate pass, whole chunk, one call per action | 17.1 | 71,758 | 116 |
| separate pass, small extract, one call per action | 17.1 | 30,593 | 86 |
| separate pass, small extract, one call per chunk (batch) | 7.9 | 26,431 | 75 |

- **Spread:** the baseline ran three times. Routing varied by 4.4 pp and fields by 2.2 pp. A gain counts only above that and with a 95% paired interval above zero.
- **Leak:** the separate pass gains 8.3 pp, but the interval starts at 0.0, so its verdict on leak is PARTIAL. The gain shows in routing and fields.
- **Batch against one call per action:** PARTIAL. Fields are 4.4 pp lower, and calls fall from 17.1 to 7.9, prompt tokens from 30,593 to 26,431 and seconds from 86 to 75. Against the whole-chunk version, fields are 66% against 65% at under half the calls and 37% of the prompt tokens.
- **Where Gemma loses moments:** mostly by missing them. Missed moments: baseline 28 of 90, separate pass 18 of 90, ceiling 2 of 90. Wrong type: separate pass 7, ceiling 8.
- **Date and time:** the weakest field. Given the right type, Gemma gets the calendar date and time right 40% to 48% of the time with the baseline, the prompt change, the schema change and the whole-chunk separate pass. The per-action small extract raises it to 60% and batch to 52%. The ceiling gets 100%.
- **`catch_up_sometime`:** the ceiling scores 0 of 9 on this case because the registry calls a vaguely timed talk with a named person a calendar event and the key says task list. Without this case the ceiling routes 80 of 81 moments right and the separate pass 65 of 81.
- **Format:** the batch run parsed 111 of 120 chunks. 2 chunks failed because Gemma wrote Python `None` instead of JSON `null`. 7 chunks returned one object too few, which left 7 of 390 actions with empty fields. 25 of 120 batch second calls found no line matching a quoted sentence and got the whole chunk.
- **Unplanted transcripts:** Gemma proposes 27% calendar items and the cloud model 11%. 15% of Gemma's items (45 of 305) match a cloud item. There is no answer key there.

### Round 2, 240 moments at three difficulty levels
Round 2 agrees with the round 1 verdict for batch (VALIDATED) and sets no verdict of its own. `claude-haiku-5-5` and `gemini-3.8-flash` wrote the sentences (120 moments each) at levels 1 (easy) to 3 (hard). `gpt-6-luna` scored the fields. Both is the share of moments found with the right type. Found is the share with any linked item. A `none` moment has no action, so an item linked to it is a false alarm.

| Group | Baseline | Batch | Ceiling, `claude-haiku-5-5` |
|---|---|---|---|
| Level 1, Both | 55% (35/64) | 75% (48/64) | 89% (57/64) |
| Level 2, Both | 42% (27/64) | 59% (38/64) | 70% (45/64) |
| Level 3, Both | 39% (25/64) | 58% (37/64) | 81% (52/64) |
| All, Found | 68% (131/192) | 79% (151/192) | 81% (155/192) |
| All, right type given found | 66% (87/131) | 81% (123/151) | 99% (154/155) |
| All, Both | 45% (87/192) | 64% (123/192) | 80% (154/192) |
| calendar_event, Both | 54% (26/48) | 81% (39/48) | 98% (47/48) |
| email_draft, Both | 58% (28/48) | 79% (38/48) | 96% (46/48) |
| task, Both | 50% (24/48) | 81% (39/48) | 85% (41/48) |
| followup_ai, Both | 19% (9/48) | 15% (7/48) | 42% (20/48) |
| none, false alarms (lower is better) | 8% (4/48) | 19% (9/48) | 0% (0/48) |

- **Where the batch gain comes from:** finding and typing more moments (Found 68% to 79%, right type given found 66% to 81%). Fields given the right type are 86% for both arms. Both rises at every level, by 20, 17 and 19 points.
- **False alarms:** batch makes more than the baseline on `none` moments (19% against 8%), and 11.72 extra items per transcript against 8.06 (ceiling 4.14).
- **Follow-up items:** weak for every arm. The ceiling finds 42% (20/48) and batch 15% (7/48).
- **Author check:** the ceiling scores 81% (78/96) on `claude-haiku-5-5` sentences and 79% (76/96) on `gemini-3.8-flash` sentences. The 95% intervals (73 to 89 and 71 to 86) overlap, so no self-favoring is shown. The ceiling model also wrote half of the action sentences.
- **Judge check:** 60 calendar and email moments were scored by `gpt-6-luna` and a second judge (`gemini-3.8-flash` for `claude-haiku-5-5` sentences, `claude-haiku-5-5` for `gemini-3.8-flash` sentences). The judges gave the same field score on 90% (baseline), 88% (batch) and 90% (ceiling) of moments. Mean field scores, main against second: baseline 0.41 against 0.37, batch 0.63 against 0.62, ceiling 0.91 against 0.91. It covers field scores only.
- **Cost per transcript on the Mac (80 transcripts):** baseline 4.2 calls, 22,543 prompt tokens, 57 s. Batch 8.3 calls, 28,357 prompt tokens, 82 s. Ceiling 1.0 call and 24,336 prompt tokens (cloud, not timed). Parse rate: baseline 100%, batch 97% (1 of 192 moments lost), ceiling 99% (3 of 192 lost).

## Not measured yet
- Speed on a phone. All times come from one Mac, one run per arm.
- Other prompt and schema variants. Each fix ran one variant.
- Other extract sizes (1 or 5 lines on each side) and repeat runs of the small extract and batch.
- Why Gemma misses moments (18 of 90 with the separate pass in round 1).
- The effect of accepting Python `None` in the reply parser on the 2 lost chunks.
- Whether either judge matches a person. No human labels were checked, and the round 1 judge is not recorded in any file.
- A cloud ceiling larger than `claude-haiku-5-5`.
- Routing under the second judge. The cross-check covers field scores only.
- The round 2 answer key audit. The audit file is missing, so the audit table of the round 2 report has no data.
- The registry rule for `catch_up_sometime` (calendar event or task list).

**Next:** the team decides on the recommendation. The first follow-up in RECOMMENDATION.md is building the batch design in product code, which is outside this spike.

Details: [RECOMMENDATION.md](https://github.com/Logitech/vnv-nexo-benchmark/blob/spike/334-typed-artefact-routing/experiments/334-typed-artefact-routing/RECOMMENDATION.md) holds the results above, [DESIGN.md](https://github.com/Logitech/vnv-nexo-benchmark/blob/spike/334-typed-artefact-routing/experiments/334-typed-artefact-routing/DESIGN.md) the questions and pass marks, and [key_public.json](https://github.com/Logitech/vnv-nexo-benchmark/blob/spike/334-typed-artefact-routing/experiments/334-typed-artefact-routing/key_public.json) the round 1 answer key. The run files and full reports in `results/` are git-ignored and are not on this branch.

Closes #334
