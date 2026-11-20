Part of #467. Spike on whether the local LLM (Gemma 4 E2B on LiteRT-LM, on a Mac) can write the meeting title, the short summary and the detailed summary from one transcript.

## Status against the pass marks

| Metric | Target | Current Status |
|---|---|---|
| Back references | 90% | Not met on one text (part 03c, seed 1, 30 items): the cited turn supports 43%, the cited turn plus the 2 turns before it supports 77% |
| LAGOM faithfulness | 90% | Not met on one text (part 03c, seed 1, 6 statements): 3/6 (50%) supported by the kept blocks, 4/6 (67%) by the full summary |
| Blocks | 90% | 30/30 items supported by the transcript (one text). The filter cut 3 blocks, and all 3 were good blocks |
| Meeting type | 80% | 12/12 passed (parts 01 and 03c; status update and brainstorm only) |
| Title | 100% | 18/18 replies copy the title of their run (part 03c). This holds by construction |

All numbers on this page come from one or two texts. They are a first look, not a result. Part 04 runs the 30 texts of part 03b.

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

**Not measured yet**
- Other meeting types with the local model. Every number in parts 02, 03a and 03c comes from one status update.
- Long meetings (nexo-app splits them in chunks). The spike keeps the 8,192-token context and does not test this path.
- Whether the judge's "not supported" on two near-copy items is right. The judge answers only "supported" or "not supported".

**Next:** part 04 is the full run on the 30 texts, with the judge. Part 05 is the report, the verdicts and the list of cuts for #469.

Details: `experiments/467-468-summary-layers/docs/architecture-design/` (files 02 to 06, with all tables).

Closes #468
