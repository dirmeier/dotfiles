Part of #467. Spike on whether the local LLM (Gemma 4 E2B on LiteRT-LM, on a Mac) can write the meeting title, the short summary and the detailed summary from one transcript.

## Status against the pass marks

| Metric | Target | Current Status |
|---|---|---|
| Back references | 90% | Not met (part 04, seed 1, 639 items): the cited turn supports 54% (344/639), the cited turn plus the 2 turns before it supports 66%. 103 items cite 2 or more turns and were never checked against them. By item kind: quotes 96% of 138, action items 71% of 93, block items 36% of 408 |
| LAGOM faithfulness | 90% | Not met (part 04, seed 1, 180 statements): 155/180 (86%) supported by the full summary. Formal Report 95%, Action Focus 85%, Casual Recap 78% (60 statements each). Against the kept blocks: 83%, 77% and 67% |
| Blocks | 90% | Met over all items (part 04, seed 1): 594/639 (93%) supported by the transcript. Three blocks are below 90%: Decisions 85% of 33 items, Next steps 89% of 93, Asks from the other side 84% of 31. The filter cut 56 of 126 written blocks, and 37 of the 56 were rated good |
| Meeting type | 80% | Met with no margin (part 04, seeds 1 to 3): 72/90 runs (80%), 24/30 texts. External call 0/18, the other four types 72/72 |
| Title | 100% | Met: 90/90 runs copy the title of their run, in both layers (part 04, seeds 1 to 3). This holds by construction |

Part 04 numbers come from 30 generated texts (6 per meeting type), each run with 3 seeds, so 90 local runs. The judge `claude-haiku-5-5` ran on seed 1 only. The judged numbers (back references, LAGOM faithfulness, blocks) count those 30 runs. Meeting type and title count all 90 runs. The verdicts are proposed. Part 05 gives the final ones.

## Current results

- **Part 01, quick checks:** the model loads and answers on the CPU. 6/6 replies parse and name the right meeting type. 24/24 back references name a turn that exists.
- **Part 02, one transcript through all three stages:** 13 local calls took 107 s, and the judge made 136 calls. The title is identical in all layers (written once, then copied). 10/10 LAGOM statements are supported, but the Formal Report has 305 characters (limit 280). The model never answered NONE, quotes did not parse, and 36 items started with a number. On the cited turn alone 45% of 42 back references are supported, and 86% with the 2 turns before it.
- **Part 03a, fix the prompts and run the same transcript again (3 seeds, local model only, no judge):** all four format targets are met.

| Same transcript | Part 02 (old prompts) | Part 03a (final prompts, seeds 1, 2, 3) |
|---|---|---|
| Lines outside the format | 6 | 0, 0, 0 |
| Items that start with a number | 36 | 0, 0, 0 |
| Quote items | 0 | 5, 5, 5 |
| Blocks answered NONE | 0 | 2, 2, 2 |
| LAGOM summaries over 280 characters (of 3) | 1 | 0, 0, 0 |

- **Part 03b, the transcript set (verdict VALIDATED with four limits):** 30 transcripts, 6 per meeting type, 40 to 50 turns each, all turns numbered. A blind check with `claude-haiku-5-5` named the known type in 30 of 30 texts. I read one text per type: 5 of 5 were believable. Writers: `gemini-3.8-flash` 15 texts, `gpt-6-luna` 11 and `gpt-5.1` 4 (the old part 01 texts). 43 LogiQ calls.
  - The blind check shares the type descriptions with the writer prompt. So 30 of 30 shows that the texts follow the descriptions, not that they are real meetings.
  - Names repeat (Priya is in 21 of 30 texts) and the 21 new texts use only 5 settings.
  - The 4 old texts use two label styles. The summary and agenda words appear as normal speech in 6 texts.
- **Part 03c, blocks first (verdict PARTIAL):** the blocks now come before the three short summaries. The order is: full summary and meeting type, title, the blocks (a yes/no question before each), then the three short summaries. The short summaries read the title, the full summary and the kept blocks. The judge checks each short-summary statement against the kept blocks. One text (a status update), two tries with 3 local seeds each, judge on seed 1 only. 108 local calls and 260 LogiQ calls.

| Part 03c, seed 1 | First try | Second try (after the name rule) |
|---|---|---|
| Short summaries with the right format (of 9) | 9 | 9 |
| Statements supported by the kept blocks (of 6) | 3 | 3 |
| Statements supported by the full summary (of 6) | 5 | 4 |
| Action items: cited turn plus 2 turns before it supports the item | 0 of 6 | 5 of 5 |
| Action items: cited turn alone supports the item | 0 of 6 | 2 of 5 |

**What part 03c showed**
- The blocks check stays at 50%. Two of the three misses in the second try are a wrong detail or a wrong person in the short summary.
- In the first try the action items said a role ("The engineering lead will ...") and the turn said a name ("Ben"). One line in the block prompt (name the speaker, use a job title only when the transcript gives no name) fixed most of it.
- The new action items copy their cited turn (95% word overlap). So the cited-turn number partly measures copying.
- The filter cut Decisions, Ideas and Quotes in every seed. One text cannot say how often it cuts a good block.
- The job-title part of the name rule is untested, because every text names its speakers.

### Part 04, the full run on the 30 texts

Title VALIDATED. Meeting type, LAGOM faithfulness, blocks and back references PARTIAL (proposed, part 05 gives the final verdicts). The part ran the full pipeline on the 30 texts of part 03b with Gemma 4 E2B (`litert-lm-api` 0.19.1, CPU), 3 seeds each: 90 local runs, 1,458 local calls, 0 errors. `claude-haiku-5-5` through LogiQ judged seed 1 (30 runs, 2,710 calls) and a repeat sample (60 calls). In all, 2,770 LogiQ calls. The plan had estimated 3,900 judge calls.

**Meeting type** (90 runs, 18 per type)

| Known type | Right (of 18) | Named instead |
|---|---|---|
| Status update | 18 | none |
| Decision meeting | 18 | none |
| Brainstorm | 18 | none |
| External call | 0 | decision meeting 15, status update 3 |
| Casual chat | 18 | none |

**LAGOM faithfulness** (seed 1, share of statements supported by the full summary, 12 statements per cell)

| Meeting type | Casual Recap | Formal Report | Action Focus |
|---|---|---|---|
| Status update | 83% | 92% | 75% |
| Decision meeting | 100% | 100% | 100% |
| Brainstorm | 92% | 100% | 100% |
| External call | 75% | 100% | 92% |
| Casual chat | 42% | 83% | 58% |
| **All (60 each)** | 78% | 95% | 85% |

All 90 runs keep the three short summaries within 280 characters.

**Blocks** (seed 1, 30 runs)

| Block | Written | Items | Supported by the transcript | Kept by the filter | Cut by the filter | Cut and rated good |
|---|---|---|---|---|---|---|
| Key points | 24 | 133 | 95% | 18 | 6 | 5 |
| Decisions | 8 | 33 | 85% | 7 | 1 | 1 |
| Next steps | 24 | 93 | 89% | 21 | 3 | 0 |
| Open questions | 0 | 0 | n/a | 0 | 0 | 0 |
| Risks and blockers | 16 | 85 | 93% | 6 | 10 | 7 |
| Ideas | 18 | 126 | 92% | 6 | 12 | 6 |
| Asks from the other side | 6 | 31 | 84% | 0 | 6 | 2 |
| Quotes | 30 | 138 | 99% | 12 | 18 | 16 |

A cut block counts as good when at least 90% of its items are supported by the transcript.

**Back references** (seed 1, 30 runs)

| Item kind | Items | Reference names an existing turn | Cited turn supports the item | Cited turn plus 2 turns before supports the item |
|---|---|---|---|---|
| Action item | 93 | 100% | 71% | 74% |
| Block item | 408 | 75% | 36% | 54% |
| Quote | 138 | 100% | 96% | 96% |
| **All** | 639 | 84% | 54% | 66% |

**What part 04 showed**
- **Meeting type:** the model never names an external call. Five of the six external call texts become "decision meeting" and `external-call-5` becomes "status update", in every seed. The pass mark is met only because the other four types are right in 72 of 72 runs. Each text gets the same name in all 3 seeds, so the 90 runs hold 30 independent answers.
- **Filter:** the filter keeps "Asks from the other side" only for an external call. With the wrong type it cut that block in all 6 judged runs. It also cut 18 of 30 Quotes blocks, and 16 of those are good. The model wrote no Open questions block in any judged run.
- **Casual chat:** the short summaries are the weakest of the set. Against the full summary: 42%, 83% and 58% (Casual Recap, Formal Report, Action Focus). Against the kept blocks: 25%, 42% and 33%. The texts were not read to find the cause.
- **Multi-turn references:** all 103 items that do not name an existing turn cite 2 or more turns, such as `#4, #5`. They sit in Key points (60 of 133), Ideas (25 of 126) and Risks and blockers (18 of 85). The check reads only a reference written exactly `#N`, so these items count as not supported and 54% is a lower bound. Among the 536 items with a one-turn reference, the cited turn supports 64% and the window of 3 turns 79%. For block items alone the two numbers are 48% (145/305) and 72%.
- **Judge:** at temperature 0, 28 of 30 repeat statements got the same answer in all 3 runs (93%). The 2 others are in `casual-chat-5` and `status-update-2`. 3 of the 2,710 judge answers are request timeouts, counted as not supported. If the one in Decisions were "supported", Decisions would rise from 85% to 88%, still below 90%.
- **Speed:** model time per run is about 130 s (seed 1), 96 s (seed 2) and 83 s (seed 3). In seed 3, 27 calls took 300 to 2,109 s each, all in four status update texts (`status-update-1` to `status-update-4`). The cause is unknown. A normal call takes 5 to 8 s on average. Machine: Apple M5, 10 cores, 24 GB, CPU only (XNNPACK), no frequency or thermal record. One machine, one time.
- **Limits:** all 30 texts were written by models (`gemini-3.8-flash` 15, `gpt-6-luna` 11, `gpt-5.1` 4), so no real meeting ran. Context stays at 8,192 tokens. The judge answers only "supported" or "not supported", so a half-right statement counts as not supported. A short summary that copies the items of the kept blocks passes the blocks check. The title check shows that every reply copies the title, and whether the title is good is untested.
- **Decision open:** no prompt changed in this part. The numbers point at two places, the meeting type prompt and the filter table. Changing either needs a decision.

## Not measured yet
- Long meetings (nexo-app splits them in chunks). The spike keeps the 8,192-token context and does not test this path.
- The 103 items with 2 or more cited turns. A judge run for them costs 206 LogiQ calls (2 per item).
- Seeds 2 and 3 with the judge. They ran and were not judged.
- Whether the judge's "not supported" on near-copy items is right (two cases in part 03c). The judge answers only "supported" or "not supported".
- The job-title fallback, and the blind check of the texts without the type descriptions.
- The cause of the slow stretch in seed 3.

**Next:** part 05 is the report with the final verdicts, the recommendation and the list of cuts for #469.

## Edits

EDIT (2026-11-13): added results of part 04

Details: [results folder](https://github.com/Logitech/vnv-nexo-benchmark/tree/spike/467-468-summary-layers/experiments/467-468-summary-layers/docs/architecture-design) (files 00 to 07 with all tables). Part 04: [07-full-run-findings.md](https://github.com/Logitech/vnv-nexo-benchmark/blob/spike/467-468-summary-layers/experiments/467-468-summary-layers/docs/architecture-design/07-full-run-findings.md). Filled report: [01-report-skeleton.md](https://github.com/Logitech/vnv-nexo-benchmark/blob/spike/467-468-summary-layers/experiments/467-468-summary-layers/docs/architecture-design/01-report-skeleton.md).

Closes #468
