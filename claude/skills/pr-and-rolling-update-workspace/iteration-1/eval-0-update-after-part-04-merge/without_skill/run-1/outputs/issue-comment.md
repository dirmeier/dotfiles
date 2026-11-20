**Status after part 04 of the spike (2026-11-13)**

The spike runs in parts on the branch `spike/467-468-summary-layers` (draft PR #488). Part 04 ran the full pipeline on the 30 generated English transcripts (6 per meeting type), 3 seeds each, with Gemma 4 E2B on a Mac CPU (Apple M5). The judge (`claude-haiku-5-5`) ran on seed 1. The verdicts below are proposed. The final verdicts and the report follow in part 05.

| Question | Pass mark | Result | Proposed verdict |
|---|---|---|---|
| Can the LLM name the meeting type? | Right on at least 80% | 80% (72 of 90 runs). External call is named wrongly in 18 of 18 runs ("decision meeting" 15, "status update" 3). The other four types are right in 72 of 72. | PARTIAL |
| Is the LAGOM summary a faithful short version of the full summary? | At least 90% of statements supported by the full summary | 86% (155 of 180). Formal Report 95%, Action Focus 85%, Casual Recap 78%. Casual chat is the weakest meeting type. All short summaries are within 280 characters. | PARTIAL |
| Is the title the same in all texts? | 100% identical | 100% (90 of 90 runs, both layers) | VALIDATED |
| Are the blocks supported, and does the filter keep good blocks? | At least 90% of block items supported (the spike's choice), and the cuts of good blocks are reported | 93% (594 of 639 items) supported by the transcript. Decisions 85%, Next steps 89% and Asks from the other side 84% are below 90%. The filter cut 56 of 126 written blocks, and 37 of them were rated good. | PARTIAL |
| Do back references point to supporting text? | At least 90% | 54% (344 of 639 items). With the 2 turns before the cited turn: 66%. Quotes 96%, action items 71%, block items 36%. | PARTIAL |

- **Blocks are judged against the transcript** (decided 2026-11-11). The issue text says the full summary. Against the full summary the numbers are far lower, for example Decisions 70%, Next steps 14% and Quotes 4%. The blocks table in the findings shows both.
- **Back references:** 103 of the 408 block items cite 2 or more turns (such as `#4, #5`). The judge reads only a reference written exactly `#N`, so it never read their turns and counts them as not supported. Among the 536 items with a one-turn reference, the cited turn supports 64% and the window of 3 turns 79%.
- **Meeting type:** the model gives the same answer for a text in all 3 seeds, so the 90 runs hold 30 independent answers.
- **Limits:** all 30 texts are model-written. The context stays at 8,192 tokens, so long meetings (a transcript in chunks) did not run. Only seed 1 was judged. The judge changed its answer on 2 of 30 repeated statements at temperature 0.

**Next:** part 05 writes the report, the final verdicts and the list of cuts for #469.

Details: [part 04 findings](https://github.com/Logitech/vnv-nexo-benchmark/blob/spike/467-468-summary-layers/experiments/467-468-summary-layers/docs/architecture-design/07-full-run-findings.md) and PR #488.
