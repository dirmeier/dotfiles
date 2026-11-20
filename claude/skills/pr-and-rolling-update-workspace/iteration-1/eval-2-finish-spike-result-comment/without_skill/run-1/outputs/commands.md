# Commands, in order (dry run: none of the gh or push commands were run)

Worktree: `/Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/334-typed-artefact-routing`
Repo: `Logitech/vnv-nexo-benchmark`. All git commands use `rtk proxy git` (the rtk git filter mis-resolves paths in nested worktrees) and an explicit `cd` (the shell cwd drifts in nested worktrees).

## 1. Check the umbrella branch is pushed and RECOMMENDATION.md is final (read-only)

Already run locally: branch `spike/334-typed-artefact-routing` is at `baf0e381`, equal to `origin/spike/334-typed-artefact-routing`, and RECOMMENDATION.md has no uncommitted change. Part branches `spike/334-typed-artefact-routing-r2-01-parser` to `-r2-09-fixes` are merged locally into the umbrella (last-part check assumed to pass in this dry run). Real run would first refresh the remote ref:

```bash
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/334-typed-artefact-routing && rtk proxy git fetch origin spike/334-typed-artefact-routing
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/334-typed-artefact-routing && rtk proxy git status -sb
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/334-typed-artefact-routing && rtk proxy git rev-parse HEAD origin/spike/334-typed-artefact-routing
```

Expected: both hashes start with `baf0e381`, so no `git push` is needed. The links in the PR body and the issue comment pin that commit.

## 2. Read the current PR body (stand-in: inputs/pr-485-body.md)

```bash
gh pr view 485 --repo Logitech/vnv-nexo-benchmark --json title,isDraft,baseRefName,headRefName,body
```

## 3. Replace the PR body (title, draft state and base stay as they are)

Text sent (identical to pr-body.md):

```bash
gh pr edit 485 --repo Logitech/vnv-nexo-benchmark --body-file - <<'PRBODY'
Spike on typed artefact extraction: email draft, calendar event and task list. The spike is finished and the written recommendation is final.

- **Question:** How well does Gemma 4 E2B (Q8) pick the right type for an action in a chunked meeting transcript? A cloud model (`claude-haiku-5-5`) gives the ceiling.
- **Method:** Planted sentences go into real QMSum transcripts, so the right type is known. A judge model scores the fields (round 1 judge not recorded; round 2 judge `gpt-6-luna`).
- **Round 1:** 90 planted moments from the held-out half, which no fix was tuned on. Arms: baseline, prompt change, schema change (date and time fields), and three versions of a separate extraction pass.
- **Round 2:** 192 planted moments in three difficulty levels, written by two cloud models, with a second judge on a sample.
- **Code:** a throwaway runner, scoring and report in `experiments/334-typed-artefact-routing`.

**Result: use a separate extraction pass with one second call per chunk (the batch). The first call picks the type of each action in a chunk. The second call fills the fields of every action found in that chunk, from the quoted sentences with 3 lines on each side.**

- **Round 1:** routing rises from 57% to 72% and fields from 50% to 66%. Both gains are above the run-to-run spread of the baseline.
- **Round 2:** moments found with the right type rise from 45% to 64%. The gain holds at all three difficulty levels.
- **Cost:** 2.0 times the calls (7.9 per transcript against 4.0 in round 1, 8.3 against 4.2 in round 2), 1.2 times the prompt tokens and 1.4 times the time. The product runs on a phone, so calls must stay bounded by the number of chunks. The batch makes at most 2 calls per chunk, the fewest among the fixes that beat the spread.
- **Drop the prompt change:** it made routing worse (50%). The schema change gave +2.2 points, inside the spread.
- **Watch:** the batch raises false alarms on `none` moments from 8% to 19% in round 2. Follow-up items stay weak at 15%.
- **Alternative (too many calls for a phone):** one second call per found action, with the same small extract. Fields reach 70% instead of 66%, at 17.1 calls per transcript, and the count grows with every action found.
- **Decision rule:** for the best routing quality, use the ceiling design (one cloud call per transcript). For a local model only, as on the phone, use the batch.

## How to read the numbers

- **Baseline:** Gemma reads each chunk in one call and lists the actions with their fields.
- **Separate pass:** one call picks the type of each action in a chunk, a second call fills the fields. **Batch** is the recommended version (one second call per chunk, small extract).
- **Ceiling:** a cloud model reads the whole transcript in one call.
- **Both:** the moment was found and the type was right. Round 1 calls this "routing".
- **Fields:** the share of right details (date, time, subject, recipient, body). Round 1 counts a wrong type or a missed moment as 0. Round 2 counts only moments with the right type.
- **Leak:** the share of calendar and email moments that Gemma filed as a task list item. Lower is better.
- **False alarm:** the model made an item for a `none` moment (a sentence with no action).
- **Spread:** the baseline ran three times on the held-out half. Routing varied by 4.4 points and fields by 2.2. A gain counts above that spread and with a 95% paired interval above zero.

## Round 1: 90 planted moments

Calls, prompt tokens and time are per transcript. Time is how long Gemma took on the Mac, in seconds. Nobody measured a phone.

| Arm | Routing | Leak | Fields | Calls | Prompt tokens | Time on the Mac | Verdict |
|---|---|---|---|---|---|---|---|
| baseline | 57% | 10% | 50% | 4.0 | 21,547 | 54 s | – |
| prompt change | 50% | 27% | 38% | 4.0 | 17,703 | 40 s | INVALIDATED |
| schema change | 59% | 8% | 51% | 4.0 | 21,555 | 56 s | PARTIAL |
| separate pass, whole chunk, one call per action | 72% | 2% | 65% | 17.1 | 71,758 | 116 s | VALIDATED |
| separate pass, small extract, one call per action | 72% | 2% | 70% | 17.1 | 30,593 | 86 s | VALIDATED |
| **separate pass, small extract, one call per chunk (batch)** | 72% | 2% | 66% | 7.9 | 26,431 | 75 s | VALIDATED |
| cloud ceiling | 89% | 0% | 97% | 1.0 | 23,562 | not recorded | – |

- **Batch against the baseline:** routing +15.6 points (95% interval +4.4 to +26.7) and fields +15.6 points (interval +2.8 to +28.3). Both are above the baseline spread (4.4 and 2.2 points).
- **Batch against the per-action small extract:** PARTIAL. Fields are 4.4 points lower (interval -8.9 to -0.6). Calls fall from 17.1 to 7.9 and time from 86 s to 75 s, so cutting 9.2 calls saved only 11 s. The per-action version stays as an alternative.
- **Batch against the whole-chunk version:** fields are 66% against 65%, at less than half the calls and 37% of the prompt tokens.
- **Where the gap sits:** Gemma mostly misses moments (18 of 90 with the separate pass) and rarely picks the wrong type. Dates and times are the weakest field: 44% baseline, 52% batch, 60% per-action small extract, 100% cloud.
- **Format:** the batch run parsed 111 of 120 chunks (92.5%), below the 95% target. Two chunks failed because Gemma wrote Python `None` in the route call. Seven failed because the reply held one object too few, which leaves 7 of 390 actions with empty fields.
- **Not tested:** a parser that accepts `None` was checked on the two saved replies only, so its effect on the numbers is unmeasured. It affects at most 2 chunks of 120.

## Round 2: 192 planted moments, three difficulty levels

### Models by job

| Job | Model | Where it runs |
|---|---|---|
| Baseline and batch: find and sort planted moments | Gemma 4 E2B (small local model file) | Local (Mac) |
| Ceiling: one cloud call per transcript | `claude-haiku-5-5` | Cloud |
| Test sentence author | `claude-haiku-5-5` (188 sentences), `gemini-3.8-flash` (190) | Cloud |
| Main scoring judge (round 2) | `gpt-6-luna` | Cloud |
| Second judge (cross-check only) | `gemini-3.8-flash` for Haiku sentences; `claude-haiku-5-5` for Gemini sentences | Cloud |
| Main scoring judge (round 1) | Not recorded | Unknown |

### Results by level (all types)

| Arm | Found | Right type given found | Both | Fields given right type | Extra items per transcript |
|---|---|---|---|---|---|
| Baseline | 68% (131/192) | 66% (87/131) | 45% (87/192) | 86% | 8.06 |
| Batch | 79% (151/192) | 81% (123/151) | 64% (123/192) | 86% | 11.72 |
| Ceiling | 81% (155/192) | 99% (154/155) | 80% (154/192) | 96% | 4.14 |

Parse rate: baseline 100%, batch 97% (1 of 192 moments lost), ceiling 99% (3 of 192 lost). Per transcript, the batch makes 8.3 calls, 28,357 prompt tokens and takes 82 s on the Mac. The baseline makes 4.2 calls, 22,543 tokens and takes 57 s.

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

### Both, by type

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

This measures agreement between two judges; accuracy against a human is unchecked. It covers field scores of calendar and email moments, and leaves routing out.

## Conclusions

**The data supports:**

- The batch beats the baseline in both rounds. The round 2 gain comes from finding and typing more moments, since fields given the right type are 86% for both arms.
- The batch makes more false alarms than the baseline: 19% against 8% on `none` moments, 11.72 extra items per transcript against 8.06.
- The ceiling is the best arm on every routing measure. It finds 81%, gets the type right 99% of the time given found, and makes no false alarms.
- Follow-up items are the weak spot for every arm. The ceiling finds 42%.
- The main judge agrees with a second judge on 88% to 90% of field scores.
- Self-favoring by the ceiling is small: 81% on its own sentences and 79% on Gemini sentences.

**The data leaves open:**

- Whether the main judge is accurate. Agreement with a second judge is not agreement with a human or with the answer key, and no human labels were checked.
- A rating for `gpt-6-luna`. No verified Elo rating exists.
- Judged routing. The cross-check covers field scores only.
- Round 1 field scores. The round 1 judge is not recorded.
- Larger cloud models. The ceiling is `claude-haiku-5-5`, which also wrote 188 of the 378 test sentences.

## Limits

- **Sample size:** round 1 has 90 moments per arm and one run per fix. Round 2 has 192 moments, 16 per type and level.
- **One variant per fix:** a better prompt change or schema change might do better.
- **Extract size:** one size (3 lines), one run each for the small extract and the batch.
- **Planted sentences:** round 1 uses our own wording inside real QMSum transcripts. Round 2 uses sentences from two cloud models. Real meetings may phrase things differently.
- **Chunks against one read:** Gemma reads chunks and the cloud model reads the whole transcript, so the gap mixes model strength with that difference.
- **Unplanted transcripts:** Gemma proposes 27% calendar items and the cloud model 11%, and 15% of Gemma's items match a cloud item. There is no answer key, so this shows a difference.
- **Judge:** the round 1 judge is not recorded in any file. The audit file for the round 2 judge table is missing from the folder.
- **Time:** one Mac, one run per arm. A phone will be slower and the ratios may differ. The cloud call time was not recorded.

## Next steps (not tested here)

- Build the batch design in product code: one route call and one fill call per chunk, with the small extract in the fill call.
- Accept `None` in the reply parser and check the effect on the 2 lost chunks.
- Ask for exactly N objects in the batch reply, or match objects to actions by number, to remove the short lists.
- Try other extract sizes (1 line or 5 lines on each side) and repeat the run to see the noise.
- Find out why Gemma misses moments (18 of 90 with the separate pass).
- Cut the batch false alarms on `none` moments (19% in round 2).
- Resolve dates in code: the model gives the day word ("Friday") and code turns it into a date from the meeting date.
- Decide the `catch_up_sometime` rule: calendar event or task list.
- Label a small set of moments by hand to test the judges against truth.
- Measure a phone. All times come from a Mac.

[RECOMMENDATION.md](https://github.com/Logitech/vnv-nexo-benchmark/blob/baf0e381/experiments/334-typed-artefact-routing/RECOMMENDATION.md) holds both rounds with every table.

Closes #334
PRBODY
```

## 4. Find the marker comment on issue #334 (stand-in: inputs/issue-334-with-marker.md, comment 1111111113)

```bash
gh api repos/Logitech/vnv-nexo-benchmark/issues/334/comments --paginate --jq '.[] | select(.body | startswith("<!-- pr-and-rolling-update -->")) | .id'
```

Expected output: `1111111113`. One marker comment exists, so it is edited in place and no second comment is posted. The issue body ("Results, recommendation and open items are in PR #485.") stays as it is.

## 5. Edit the marker comment

Text sent (identical to issue-comment.md):

```bash
gh api --method PATCH repos/Logitech/vnv-nexo-benchmark/issues/comments/1111111113 -f body="$(cat <<'ISSUECOMMENT'
<!-- pr-and-rolling-update -->
Draft PR #485 holds the final results. Last update: 2026-11-13 (spike finished).
Results are written to https://github.com/Logitech/vnv-nexo-benchmark/blob/baf0e381/experiments/334-typed-artefact-routing/RECOMMENDATION.md.

**Recommendation:** use a separate extraction pass with one second call per chunk.

- **Round 1** (90 planted moments): routing 57% to 72%, fields 50% to 66%. Cloud ceiling: 89% and 97%.
- **Round 2** (192 planted moments, three difficulty levels): found with the right type 45% to 64%. Cloud ceiling: 80%.
- **Cost:** 2.0 times the calls of the baseline (at most 2 per chunk), 1.2 times the prompt tokens, 1.4 times the time.
- **Watch:** false alarms on `none` moments rise from 8% to 19%. Follow-up items stay weak at 15%.
- **Open items:** the next steps are listed in the RECOMMENDATION.md and in PR #485.
ISSUECOMMENT
)"
```

## 6. Check the result (read-only)

```bash
gh pr view 485 --repo Logitech/vnv-nexo-benchmark --json isDraft,title,body --jq '{isDraft, title, last: (.body | split("\n") | map(select(length>0)) | last)}'
gh api repos/Logitech/vnv-nexo-benchmark/issues/comments/1111111113 --jq .body
```

Expected: `isDraft` true, the title unchanged, the last body line `Closes #334`, and the comment starting with `<!-- pr-and-rolling-update -->`.

## Not run on purpose

- `git push`: nothing to push.
- `gh pr ready 485`: the PR stays a draft, since marking it ready was not asked for.
- `gh pr edit 485 --title ...`: the title was not asked to change (see summary.md).
- `git add` of `experiments/334-typed-artefact-routing/key_public_r2.json` (untracked, see summary.md).
