---
name: pr-and-rolling-update
description: Open a draft pull request for a spike's umbrella branch, then keep it current as part branches merge into it. Creates the draft PR with a body that shows the current state and results, ends the body with "Closes #issue", and posts one short pointer comment on the issue. After each part-branch merge it pushes the umbrella branch, rewrites the PR body, adds a dated EDIT line, and updates the issue comment. When the user says the spike is finished, it collects the results of all parts into ONE report and recommendation document, links it from the PR body, and switches the issue comment to the result form. Use this whenever the user asks to open or create the PR for a spike, says "update the PR", "push and update the PR body", "part NN is merged", "sub-branch merged into the umbrella", finishes a part of a rolling spike, says the spike is finished, or asks for the final report, even if they do not name the skill. Do not use it for ordinary feature or fix PRs.
---

# PR and rolling update

Colleagues follow a spike by reading its draft PR. The PR body must show the current state at any moment, and the issue must point to it. This skill creates the PR once, then refreshes the body and the issue comment after every part merge. When the spike is finished, it collects all results into one report document.

## The setup this skill assumes

- One **umbrella branch** per spike, named `spike/<issue numbers>-<name>`, in its own worktree under `.worktrees/spike/`.
- One **part branch** per task, named `<umbrella>-NN-<name>`, each in its own worktree.
- Part branches merge **locally** into the umbrella. Only the umbrella is pushed. Push a part branch only when the user asks.
- One umbrella, one PR. Never split it.

This skill starts after the merge. If the part is not in the umbrella yet, say so and stop. Do not merge it yourself.

## Step 0: Collect the facts

Do this before any write. A wrong issue number or a stale results file is hard to undo once it is public.

- **Umbrella branch and worktree path:** `rtk proxy git worktree list`, matched against the current directory.
- **Existing PR:** `gh pr list --head <umbrella> --json number,url,isDraft`. None means Mode A. One means Mode B.
- **Issue to close:** read it from the last line of the existing PR body. For a new PR, read it from the spike's question or design doc. Two issue numbers usually mean a parent and a child. The child gets `Closes`, and the first line of the body says `Part of #<parent>.` If this is still unclear, ask the user.
- **Results files:** the findings, report or recommendation files of the spike (for example `experiments/<spike>/docs/architecture-design/NN-*-findings.md`, the filled report skeleton, or `RECOMMENDATION.md`). The body is a summary of these files. Read all that changed since the last update.
- **Results files are committed:** run `cd <absolute worktree path> && rtk proxy git ls-files --error-unmatch <file>` for each file you will link. If a file is untracked or ignored by git, its link shows a 404 page. Name the file to the user and do not link it.
- **Repo URL:** `gh repo view --json url --jq .url`.

Two traps in the nested worktrees:
- Start every command with `cd <absolute worktree path> &&`. The shell directory silently resets between calls.
- Use `rtk proxy git ...` instead of plain `git`. The rtk wrapper resolves paths wrongly there.

Reading an issue: `gh issue view N` prints nothing here. Use `gh issue view N --json title,body,comments`.

## Mode A: Create the draft PR

1. Check the finished parts are in the umbrella (`rtk proxy git merge-base --is-ancestor <part> <umbrella>`). Push: `rtk proxy git push -u origin <umbrella>`.
2. Pick the title. Format: `spike(<scope>): <what the spike answers> (#<issues>)`. The scope is the experiment folder name. Look at sibling spike PRs (`gh pr list --search spike`) for wording. The type is always `spike`, never `feat`.
3. Write the body (layout below). Leave out the EDIT lines. The first version is not an edit.
4. Create it as a draft, with the body read from stdin so no temp file is needed:
   ```bash
   gh pr create --draft --base develop --head <umbrella> --title "<title>" --body-file - <<'EOF'
   ...body...
   EOF
   ```
5. Post the issue comment (Mode C). Then give the user the PR URL.

## Mode B: Update after a part merge

1. Confirm the part is in the umbrella. Push the umbrella: `rtk proxy git push origin <umbrella>`. Never force-push.
2. Read the current body: `gh pr view <n> --json body --jq .body`.
3. Rewrite the **main text** to the current state, from the results files:
   - Replace numbers that changed. Do not append a second number next to the old one. A body with two conflicting numbers is the main way this skill goes wrong.
   - Add the new part under Current results, with its verdict, as a bullet or a `###` subsection (see "How to write it").
   - Update the status table, "Not measured yet" and "Next". Move an item out of "Not measured yet" when a part measured it.
   - Keep the layout the body already has. Do not reorganize it.
4. Add one **EDIT line** just above the `Details:` line and below the `**Next:**` line. Use no heading. The newest EDIT line goes first, above the older ones. Keep every older EDIT line unchanged.
   ```
   EDIT (2026-11-13): updated results of part 04
   EDIT (2026-11-12): added results of part 03c
   ```
   Get the date with `date +%F`. Name the part. Use "updated results of", "added results of" or "corrected" as the verb.
5. Write it back: `gh pr edit <n> --body-file - <<'EOF' ... EOF`. The PR stays a draft. Do not change the title or mark it ready unless the user asks.
6. Update the issue comment (Mode C).
7. Tell the user in two or three lines what changed in the body.

## Body layout

The last line is always `Closes #<issue>`. Nothing comes after it. Leave out any "Generated with" line.

```markdown
Part of #<parent>. <One sentence: the question the spike answers, and on what.>

## Status against the pass marks
| Metric | Target | Current status | Evidence |
|---|---|---|---|
| <metric> | <target> | <number with denominator, part and seed, or "not measured yet"> | <branch link to the file that holds the number> |

<One line: how many texts or runs the numbers come from, the run date, the exact model IDs and the tool versions.>

## Current results
- **Part 01, <name>:** <verdict>. <what was run, the numbers>.
- **Part 02, <name>:** ...

### Part 03, <name>
<verdict>. <what was run>.

| <arm, seed or level> | <metric> | <metric> |
|---|---|---|
| ... | ... | ... |

- <what the table showed, one bullet per point>

## Not measured yet
- ...

**Next:** <the next part, one line>.

EDIT (<date>): <what changed>

Details: <link to the results folder or files on the umbrella branch>

Closes #<issue>
```

If the spike has no pass marks, use the sections of its question doc instead (Question, Method, Result, Limits). Keep "Not measured yet" and "Details" in both layouts.

How to write it:
- Use short, plain sentences. Explain a term the first time it appears.
- Give every number its denominator, and say which part and seed it comes from. "43% (13/30)" beats "43%".
- End each part with a verdict: VALIDATED, PARTIAL or INVALIDATED.
- Show a result in a table when it compares arms, seeds, texts or levels, as the part 03a and 03c tables do in PR #488. Keep a result that is one number as a bullet.
- Give a large part its own `### Part NN, <name>` subsection under Current results. Put the verdict line first, then the table, then bullets on what it showed. A small part stays one bullet.
- Fill the Evidence column with a branch link to the file that holds the number. Leave the cell empty for "not measured yet". A reader can then check every number in one click.
- Name models and tools by their exact ID. Give the run date and tool versions in the line under the status table, so results from different dates stay comparable.
- State limits as facts, such as the number of texts and the models that wrote or judged them.
- Link results files with the **branch** URL, `<repo url>/blob/<umbrella>/<path>`. A link pinned to one commit goes stale after the next push.

## Mode C: The issue comment

The issue gets one comment. The skill creates it once and edits it in place after that. Do not post a second comment. Editing in place keeps the issue quiet and the comment current.

- The first line of the comment is the marker `<!-- pr-and-rolling-update -->`. This lets the skill find its own comment again.
- Find it: `gh issue view <issue> --json comments --jq '.comments[] | select(.body | contains("<!-- pr-and-rolling-update -->")) | .url'`. The number after `#issuecomment-` is the comment ID.
- Edit it: `gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id> -f body="<new body>"`.
- Create it, when none exists: `gh issue comment <issue> --body-file - <<'EOF' ... EOF`.

While the spike runs, the comment stays this short:

```
<!-- pr-and-rolling-update -->
Draft PR #488 holds the current results. Last update: 2026-11-13 (part 04).
Results are written to <link to the results file or folder>.
```

Switch to the result form only when the user says the spike is finished, the final report from Mode D exists, and the user has okayed it. Never decide this yourself, because a result in the issue is read as the final answer. Then replace the text with the result:

```
<!-- pr-and-rolling-update -->
Spike result: <one-line verdict>. Resolved in PR #485. Full write-up: <link>.
```

Take the verdict from the final report. Do not write a result that no file states. If the report does not exist yet, run Mode D first, or keep the short progress form.

## Mode D: Final report

Run this only when the user says the spike is finished. Never decide it yourself. The final result must live in ONE document, so a reader does not have to open every part file.

1. Read every results file of every part: the per-part findings files, the filled report skeleton and the current PR body.
2. Find the one document. Look for an existing `RECOMMENDATION.md` or final report in the spike's docs folder. If none exists, create `<results folder>/NN-report-and-recommendation.md`, numbered after the last file in that folder. Never write a second summary file.
3. Collect all results in that document, with this layout:

   ```markdown
   # <Spike name>: report and recommendation

   **Question:** <the question the spike answers, one sentence>.
   **Recommendation:** <what to do, one or two sentences>.
   **Verdict:** <VALIDATED, PARTIAL or INVALIDATED, and the reason in one line>.

   ## Status against the pass marks
   <the same table as in the PR body, every row final>

   ## Results by part
   ### Part 01, <name>
   <verdict>. <what was run>. <the part's tables and numbers, copied in full>. Source: <branch link to the part's findings file>.

   ### Part 02, <name>
   ...

   ## Limits
   - ...

   ## Not measured
   - ...

   **Run info:** <run dates, exact model IDs, tool versions, number of texts or runs>.
   ```

4. Every number comes from a part's findings file, with its denominator, part and seed. When a later part replaced an earlier number, show the later number and say in one line that it replaced the earlier one. Never show two conflicting numbers as if both were current.
5. Show the file path to the user and wait for their ok. Do not commit the document before they have read it.
6. After the ok, commit it on the umbrella branch (`docs(<scope>): ...`) and push. Then update the PR (Mode B, steps 2 to 5): point `Details:` at this document, make sure the numbers in the body match it, and add an EDIT line such as `EDIT (2026-11-13): added the final report and recommendation`.
7. Update the issue comment to its result form (Mode C), with a link to this document.

## Rules that never bend

- Commit messages use `type(scope): description` with no co-author trailer. This skill rarely commits. If it must, follow this.
- Never use `--no-verify`. Never force-push. Never merge the PR.
- Do not run benchmarks or scripts. Read results from the files.
- Do not open an issue. Only comment on the existing one.
- At the end, all results live in ONE report and recommendation document. The PR body and the issue comment link to it. Never create a second summary file.
- When something is unclear (which issue, which file holds the results, whether the spike is finished), ask the user in one short question.
