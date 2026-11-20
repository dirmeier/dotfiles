# Commands, in order (dry run: none of these was run)

All git commands run in the umbrella worktree and go through `rtk proxy`, because the rtk git filter mis-resolves paths in nested worktree directories. The new PR number is not known yet. The body and the title do not mention it, so #NNN appears nowhere in these commands.

## 1. Check what is dirty (read-only)

```bash
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/334-typed-artefact-routing && rtk proxy git status --short
```

Expected output: one line, `?? experiments/334-typed-artefact-routing/key_public_r2.json`. The file is the round 2 public answer key (our sentences and positions, no transcript text). The run book in README.md describes it next to the committed `key_public.json`, and it was never committed.

## 2. Commit the round 2 answer key

No Co-Authored-By trailer, per the user's standing rule.

```bash
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/334-typed-artefact-routing && rtk proxy git add experiments/334-typed-artefact-routing/key_public_r2.json
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/334-typed-artefact-routing && rtk proxy git commit -m "feat(334-typed-artefact-routing): add public answer key for round 2"
```

## 3. Push the umbrella branch (it already tracks origin/spike/334-typed-artefact-routing)

```bash
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/334-typed-artefact-routing && rtk proxy git push origin spike/334-typed-artefact-routing
```

## 4. Check that no PR exists for the branch (read-only)

```bash
gh pr list --repo Logitech/vnv-nexo-benchmark --head spike/334-typed-artefact-routing --state all --json number,title,state
```

Expected output: `[]`.

## 5. Open the draft PR

Base is `develop`. The diff against `origin/develop` is 75 commits and 59 files, all under `experiments/334-typed-artefact-routing/` (60 files with the answer key). The local `develop` is 3 commits behind the remote and is not used.

The body is the text between the two `EOF` lines, identical to pr-body.md.

```bash
cd /Users/sdirmeier/PROJECTS/vnv-nexo-benchmark/.worktrees/spike/334-typed-artefact-routing && gh pr create --repo Logitech/vnv-nexo-benchmark --draft --base develop --head spike/334-typed-artefact-routing --title "[DO NOT MERGE] spike(334-typed-artefact-routing): typed artefact routing for email, calendar event and task list" --body "$(cat <<'EOF'
Spike on typed artefact extraction: email draft, calendar event and task list. The code is a throwaway harness. The result is the numbers and a written recommendation.

- **Question:** How often does Gemma 4 E2B (Q8, run with llama.cpp on a Mac) give an action in a chunked meeting transcript the right type, and how many of its fields are right? A cloud model that reads the whole transcript in one call (`claude-haiku-5-5`, called the ceiling) gives the upper limit.
- **Method:** Sentences with a known right type are planted into real QMSum transcripts, and a judge model scores the fields. Round 1 plants 90 sentences of our own wording (30 calendar events, 30 email drafts, 30 task list items) into the held-out half of the meetings, and no fix was tuned on them. Round 2 plants 240 sentences in five types (calendar event, email draft, task, follow-up question for the AI, no action) at three difficulty levels. Two cloud models wrote them (`claude-haiku-5-5` and `gemini-3.8-flash`), `gpt-6-luna` judged the fields, and a judge from another company re-scored 60 moments.
- **Fixes tried in round 1:** a prompt change, a schema change (separate date and time fields) and a separate extraction pass in three versions.
- **Code:** runner, scoring, reports and tests (with a fake model) in `experiments/334-typed-artefact-routing`.

**Result: use a separate extraction pass with one second call per chunk. The first call picks the type of each action in a chunk. The second call fills the fields of every action found in that chunk, from the quoted sentences with 3 lines on each side. This design is called the batch below.**

The product runs on a phone, so the calls per transcript must stay bounded by the number of chunks. The batch makes at most 2 calls per chunk, the fewest among the fixes that beat the run-to-run spread. The prompt change made routing worse. The schema change did not help.

**Round 1** (90 planted sentences). Calls, prompt tokens and time are per transcript. Time is how long Gemma took on the Mac. Nobody measured a phone.

| Arm | Routing | Leak into task list | Fields | Calls | Prompt tokens | Time on the Mac | Verdict |
|---|---|---|---|---|---|---|---|
| baseline | 57% | 10% | 50% | 4.0 | 21,547 | 54 s | – |
| prompt change | 50% | 27% | 38% | 4.0 | 17,703 | 40 s | INVALIDATED |
| schema change | 59% | 8% | 51% | 4.0 | 21,555 | 56 s | PARTIAL |
| separate pass, whole chunk, one call per action | 72% | 2% | 65% | 17.1 | 71,758 | 116 s | VALIDATED |
| separate pass, small extract, one call per action | 72% | 2% | 70% | 17.1 | 30,593 | 86 s | VALIDATED |
| **separate pass, small extract, one call per chunk (batch)** | 72% | 2% | 66% | 7.9 | 26,431 | 75 s | VALIDATED |
| cloud ceiling | 89% | 0% | 97% | 1.0 | 23,562 | not recorded | – |

Round 1 routing counts a moment as right when Gemma finds it and gives it the right type. Round 1 fields count a missed moment or a wrong type as 0.

**Round 2** (240 planted sentences: 192 with an action and 48 with no action). Found means Gemma made an item for the sentence. Both means found with the right type.

| Arm | Found | Right type given found | Both | Fields given right type | False alarms on `none` | Calls | Prompt tokens | Time |
|---|---|---|---|---|---|---|---|---|
| baseline | 68% (131/192) | 66% (87/131) | 45% (87/192) | 86% | 8% (4/48) | 4.2 | 22,543 | 57 s |
| batch | 79% (151/192) | 81% (123/151) | 64% (123/192) | 86% | 19% (9/48) | 8.3 | 28,357 | 82 s |
| ceiling | 81% (155/192) | 99% (154/155) | 80% (154/192) | 96% | 0% (0/48) | 1.0 | 24,336 | not timed |

- **Batch against the baseline, round 1:** routing +15.6 points (95% interval +4.4 to +26.7) and fields +15.6 points (interval +2.8 to +28.3). Both gains are above the run-to-run spread of the baseline (4.4 and 2.2 points). The price is 2.0 times the calls, 1.2 times the prompt tokens and 1.4 times the time.
- **Batch against the baseline, round 2:** Both rises from 45% to 64%, with a gain at every level (level 1: 55% to 75%, level 2: 42% to 59%, level 3: 39% to 58%). The gain comes from finding and typing more moments. Fields given the right type are 86% for both arms.
- **Batch against the per-action small extract:** PARTIAL. Round 1 fields are 4.4 points lower (interval -8.9 to -0.6), and the calls fall from 17.1 to 7.9. The per-action version stays as an alternative whose calls grow with every action found.
- **Where the gap to the cloud sits:** Gemma mostly misses moments and rarely picks the wrong type. In round 1 the separate pass gets 65 right, 7 with the wrong type and 18 missed, and the cloud gets 80, 8 and 2. Calendar date and time is the weakest field, given the right type: 40–48% for the baseline, 52% for the batch and 100% for the cloud.
- **Leak into the task list:** in round 1 the share of calendar and email moments filed as a task list item falls from 10% to 2%. The interval of that gain starts at 0.0, so the leak verdict is PARTIAL. In round 2, counted from the confusion matrix, the share is 22% (21/96) for the baseline, 18% (17/96) for the batch and 1% (1/96) for the cloud.
- **Watch:** the batch raises false alarms on `none` moments from 8% to 19% in round 2. Follow-up questions for the AI stay weak: Both is 19% for the baseline, 15% for the batch and 42% for the cloud.
- **Format:** the round 1 batch run parsed 111 of 120 chunks (92.5%), below the 95% target. Two chunks failed because Gemma wrote Python `None` in the route call. Seven failed because the reply held one object too few, which leaves 7 of 390 actions with empty fields. The round 2 batch run parsed 97% of replies.
- **Decision rule:** for the best routing quality, use the ceiling design (one cloud call per transcript). For a local model only, as on the phone, use the batch.
- **Limits:** one run per arm and one variant per fix. The planted sentences are our own wording in round 1 and model-written in round 2. Gemma reads chunks and the cloud model reads the whole transcript. The ceiling model also wrote 188 of the 378 round 2 sentences. The two judges agree on 88–90% of field scores, and nobody has checked either judge against human labels. The round 1 judge is not recorded. All times come from one Mac.
- **Next steps, not tested:** build the batch design in product code. Accept Python `None` in the reply parser and ask for exactly N objects in the batch reply. Find out why Gemma misses moments and cut the false alarms. Turn day words into dates in code. Decide the rule for vaguely timed talks (`catch_up_sometime`: calendar event or task list). Label a small set of moments by hand to test the judges. Measure a phone.
- **Written recommendation:** [RECOMMENDATION.md](https://github.com/Logitech/vnv-nexo-benchmark/blob/spike/334-typed-artefact-routing/experiments/334-typed-artefact-routing/RECOMMENDATION.md)

Closes #334
EOF
)"
```

## 6. Check the result (read-only)

```bash
gh pr view spike/334-typed-artefact-routing --repo Logitech/vnv-nexo-benchmark --json number,url,isDraft,baseRefName,title
```

Expected: `isDraft` true, `baseRefName` develop.

## Not run

- No comment on issue #334 (see issue-comment.md).
- No labels, assignees or project fields, because none was asked for.
