# Commands, in order (dry run: none of these was run)


## 1. Checks before the push (read-only)

```bash
# Part 04 is in the umbrella. Assumed to pass in this dry run.
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/467-468-summary-layers && git merge-base --is-ancestor spike/467-468-summary-layers-04-full-run spike/467-468-summary-layers && echo merged

# The umbrella worktree has no uncommitted changes (expected: no output)
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/467-468-summary-layers && git status --short

# The commits the push sends (expected: the commits of part 04 and the merge commit)
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/467-468-summary-layers && git log --oneline origin/spike/467-468-summary-layers..HEAD

# CI gate before every push. Part 04 only changed files under experiments/467-468-summary-layers/, so no change is expected here.
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/467-468-summary-layers && uv run mypy src/
```

## 2. Push the umbrella (no force, no --no-verify; the upstream is already set)

```bash
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/467-468-summary-layers && rtk proxy git push origin spike/467-468-summary-layers
```

## 3. Replace the body of PR #488 (title, base and draft state stay as they are)

Sends the text between the EOF lines; identical to pr-body.md.

```bash
gh pr edit 488 --repo Logitech/vnv-nexo-benchmark --body-file - <<'EOF'
Part of #467. Spike on whether the local LLM (Gemma 4 E2B on LiteRT-LM, on a Mac) can write the meeting title, the short summary and the detailed summary from one transcript.

## Status against the pass marks

| Metric | Target | Current Status |
|---|---|---|
| Back references | 90% | Not met (part 04, 639 items): the cited turn supports 54%, the cited turn plus the 2 turns before it supports 66%. Quotes 96%, action items 71%, block items 36%. 103 block items cite 2 or more turns and the judge never read their turns, so the shares are a lower bound for them. Proposed verdict: PARTIAL |
| LAGOM faithfulness | 90% | Not met (part 04, 180 statements): 155 supported by the full summary (86%). Formal Report 95%, Action Focus 85%, Casual Recap 78%. Casual chat is the weakest meeting type. All short summaries are within 280 characters (90 runs). Proposed verdict: PARTIAL |
| Blocks | 90% | Met over all items, not met for 3 blocks (part 04, 639 items): 594 (93%) supported by the transcript. Decisions 85%, Next steps 89% and Asks from the other side 84% are below 90%. The filter cut 56 of 126 written blocks, and 37 of the 56 were rated good. Proposed verdict: PARTIAL |
| Meeting type | 80% | Met with no margin (part 04, 90 runs): 72 right (80%). External call 0 of 18, the other four types 72 of 72. Counting texts: 24 of 30. Proposed verdict: PARTIAL |
| Title | 100% | Met (part 04, 90 runs): 90 of 90 copy the title exactly, in both layers. The title is copied, so this holds by construction. Proposed verdict: VALIDATED |

Meeting type and title count all 90 runs (30 texts, 3 seeds each). Back references, LAGOM faithfulness and blocks count the 30 runs of seed 1, the only seed the judge ran on. All 30 texts are model-written. The verdicts are proposed, and part 05 gives the final ones.

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

- **Part 04, the full run on the 30 texts (verdicts proposed, final ones in part 05):** the pipeline of part 03c ran on all 30 texts of part 03b with seeds 1, 2 and 3. That is 90 local runs and 1,458 local calls, with 0 errors. The judge (`claude-haiku-5-5`, temperature 0) ran on seed 1 only: 30 judged runs and 2,710 LogiQ calls, plus a repeat sample of 60 calls. No prompt changed. Machine: Apple M5, 10 cores, 24 GB, CPU only (`litert-lm-api` 0.19.1 with XNNPACK; the NPU did not load).

| Part 04, short summaries (60 statements per cell) | Casual Recap | Formal Report | Action Focus |
|---|---|---|---|
| Supported by the full summary (the pass mark) | 78% | 95% | 85% |
| Supported by the kept blocks | 67% | 83% | 77% |
| Supported by the full summary or the kept blocks | 83% | 98% | 95% |

| Part 04, back references | Items | Cited turn supports | Cited turn plus 2 turns before it supports |
|---|---|---|---|
| Action items | 93 | 71% | 74% |
| Block items | 408 | 36% | 54% |
| Quotes | 138 | 96% | 96% |
| All | 639 | 54% | 66% |

**What part 04 showed**
- **External call is never named.** The model says "decision meeting" for 5 of the 6 texts and "status update" for the sixth, in every seed. The filter keeps "Asks from the other side" only for an external call, so it cut that block in all 6 judged runs, and the transcript supports 84% of its items.
- **The seeds do not change the type answer.** Each text gets the same name in all 3 seeds, so the 90 runs hold 30 independent answers.
- **Block items cite several turns.** 103 of the 408 block items cite 2 or more turns (such as `#4, #5`). The scorer reads a reference only when it is written exactly `#N`, so the judge never read their turns and the shares count them as not supported. The 305 block items with a one-turn reference: the cited turn supports 48%, the window of 3 turns 72%.
- **The filter cuts good blocks.** Of the 56 cut blocks, 37 are good (at least 90% of their items supported by the transcript). Quotes lose 16 (18 cut, 99% of items supported), Risks and blockers 7, Ideas 6, Key points 5, Asks from the other side 2, Decisions 1.
- **Casual chat short summaries are the weakest.** Against the full summary 42%, 83% and 58% for the three styles, against the kept blocks 25%, 42% and 33%. The cause is not found.
- **No Open questions block.** The model wrote none in any judged run.
- **The judge changes its answer at temperature 0.** 28 of 30 repeated statements got the same answer in all 3 runs (93%). 3 of the 2,710 judge answers are web request timeouts, counted as "not supported".
- **A slow stretch in seed 3.** 27 calls took 300 to 2,109 s each, all in four status update texts. The cause is not found and no run was dropped or repeated.

**Not measured yet**
- Long meetings (nexo-app splits them in chunks). The spike keeps the 8,192-token context and does not test this path.
- Real meetings. Models wrote all 30 texts.
- The 103 block items with several cited turns, and seeds 2 and 3. Judging the 103 items costs 206 LogiQ calls and waits for a go-ahead.
- The job-title part of the name rule, and the blind check without the type descriptions.
- Whether the judge's "not supported" on near-copy items is right (two cases in part 03c, no cause found). The judge answers only "supported" or "not supported", so a half-right statement counts as not supported.
- Frequency and thermal state of the machine, and the cause of the slow stretch in seed 3.

**Next:** part 05 is the report, the final verdicts and the list of cuts for #469. Two decisions come first: whether to change the type prompt or the filter table (the two places the numbers point to), and whether to run the 206 judge calls for the multi-turn items.

Details: `experiments/467-468-summary-layers/docs/architecture-design/` (files 02 to 07, with all tables).

Closes #468
EOF
```

## 4. Post one new comment on issue #468 (it has no comments yet; the issue body stays as it is)

Sends the text between the EOF lines; identical to issue-comment.md.

```bash
gh issue comment 468 --repo Logitech/vnv-nexo-benchmark --body-file - <<'EOF'
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
EOF
```

After part 05 the same comment is edited instead of a second one posted: `gh issue comment 468 --repo Logitech/vnv-nexo-benchmark --edit-last --body-file <new text>`.

## 5. Read back (read-only)

```bash
# The PR body on GitHub equals the new body (expected: no diff output)
gh pr view 488 --repo Logitech/vnv-nexo-benchmark --json body --jq .body | diff - /Users/sdirmeier/.claude/skills/pr-and-rolling-update-workspace/iteration-1/eval-0-update-after-part-04-merge/without_skill/outputs/pr-body.md

# The comment exists on the issue (gh issue view --comments prints nothing here, so --json)
gh issue view 468 --repo Logitech/vnv-nexo-benchmark --json title,comments --jq '.comments | length'
```
