---
name: lightweight-sdd
description: Execute an implementation plan with a fresh subagent per task, like superpowers:subagent-driven-development but with far fewer reviews - implementer self-review gates every task, a task review runs only for tasks flagged risky, and one final whole-branch review closes the plan. Use whenever the user asks for "lightweight SDD", "light SDD", "SDD lite", "quick/cheap/fast subagent execution", or wants to run a plan with subagents with fewer reviews or less overhead, even if they never name this skill. Prefer it over subagent-driven-development when speed and token cost matter more than a review after every task.
---

# Lightweight SDD

Run a written plan by dispatching one fresh implementer subagent per task and coordinating from this session. Reviews are the expensive part of full subagent-driven development, so this version spends them where the risk is: the implementer's tests and self-review gate every task, tasks flagged risky get one extra review, and the whole branch gets one review at the end.

Use `superpowers:subagent-driven-development` instead when every task needs independent assurance (a security-critical plan, an unfamiliar codebase).

**Why subagents:** each implementer starts with an isolated context holding exactly its task, so it stays focused, and your own context stays free for coordination. Hand every artifact (briefs, reports, diffs) over as a file path. Anything you paste into a dispatch or a subagent prints back stays in your context for the rest of the session.

**Narration:** between tool calls, at most one short line.

**Never pause between tasks.** The user asked for the plan to be executed, so execute it; "should I continue?" prompts and progress summaries cost their time and buy nothing. Four things stop you: an irreversible or destructive operation, a security-sensitive action, a side effect outside this worktree that norms say to ask about first (a merge, a push to a shared branch, a publish), and a plan so broken that every path forward is a guess. Everything else you decide: the spec is the binding authority, the plan is its argument, and your judgment settles what neither answers. Record each decision in the ledger as `Ruling: <decision> - <why> - <cost if wrong>` and keep going. A wrong ruling costs visible rework; a session parked on a question costs the user's day.

## Setup

1. Work in an isolated worktree (`superpowers:using-git-worktrees`, or verify the current one). Never implement on a main branch without the user's explicit consent.
2. Create the plan's workspace and ledger. Conversation memory does not survive compaction, and a controller that loses its place re-dispatches finished tasks, the costliest failure there is. The ledger is the recovery map; after compaction trust it and `git log` over your recollection.
   ```bash
   WS=$(git rev-parse --show-toplevel)/.superpowers/sdd/$(basename PLAN_FILE .md); mkdir -p "$WS"
   git check-ignore -q .superpowers || echo '.superpowers/' >> "$(git rev-parse --git-path info/exclude)"
   ```
   The ledger is `$WS/progress.md`. Its first line is `# SDD ledger - plan: <plan file path>`. If it already exists with your plan on line one, tasks with a `Task N: complete` line are done: resume at the first task without one. A ledger naming a different plan belongs to that plan; leave it alone.
3. Read the plan once (and the spec, if it names one), note its Global Constraints, and create a todo per task.
4. Scan once for tasks that contradict each other or the Global Constraints. Rule on each hit and ledger the ruling. A clean scan needs no comment.
5. Flag risky tasks. A task is risky when the plan marks it (`Risk:`, "risky", or similar). When the plan marks nothing, flag a task that touches auth or secrets, concurrency, a public interface or schema, data migration or deletion, or that integrates the outputs of two or more earlier tasks. Write `Risk: Task N - <why>` per flagged task. Flags you added are your call; say so in the final message.

## Model selection

Pick the cheapest model that can do the role. Judge each task from the plan's text, one task at a time. Never pass `fable`; opus is the top tier.

- **Simple task** (the plan gives exact names, signatures and tests; one or two files; or the same edit repeated): `model: "haiku"`.
- **Normal task** (new logic with many branches, joins the output of earlier tasks, or needs debugging): omit `model`, so it uses this session's model.
- **Task that needs design judgment:** `model: "opus"`.
- **Task reviewer:** the same judgment scaled to the diff. `haiku` for a small mechanical diff, the session model for most diffs, `opus` for a risky one.
- **Final reviewer:** `opus`.

Write `Model: Task N - <tier> - <why>` in the ledger for each dispatch, so the user can see what ran where.

## Per task

Batch small same-shape work (the same edit repeated across files, a run of constant changes) into one dispatch and one diff instead of one subagent per task.

1. **Brief.** Extract the task's text to a file; the implementer never reads the whole plan:
   ```bash
   awk -v n=N '/^(#|##|###) /{f=index($0,"Task " n ":")>0} f' PLAN_FILE > "$WS/task-N-brief.md"
   ```
   (Adjust the pattern to the plan's heading style if it is not `### Task N:`.)
2. **Record BASE** with `git rev-parse HEAD`, then dispatch the implementer using the template below. Dispatch one at a time; parallel implementers conflict. Name the report file after the brief (`task-N-report.md`).
3. **Handle the status.**
   - `DONE`: continue.
   - `DONE_WITH_CONCERNS`: read the concerns; fix correctness or scope concerns first (step 5), note observations and move on.
   - `NEEDS_CONTEXT`: supply it and re-dispatch.
   - `BLOCKED`: supply context, move to a more capable model, split the task, or rule on a plan correction and re-dispatch. Never retry unchanged.
4. **Review only if flagged risky.** Write the review package to a file and dispatch the task reviewer. The package carries the commit list and stat as well as the diff, because a reviewer given a bare diff spends a "cannot verify" line on the commit-message format every time:
   ```bash
   { git log --oneline BASE..HEAD; git diff --stat BASE..HEAD; git diff BASE..HEAD; } > "$WS/task-N.diff"
   ```
   Unflagged tasks go straight to step 6 on the implementer's tests and self-review.
5. **One fix round.** For Critical or Important findings (or a confirmed gap), resume the implementer with the findings verbatim; if your harness cannot resume it, dispatch a fresh one with the brief, report path, and findings. It fixes, re-runs the covering tests, and appends a fix report with the command and output. Check that evidence is present. There is no re-review and no second round: anything still open gets `Task N: parked - <finding> - Ruling: <why the code stands or what it defers>`, and the final review sees it. Never fix findings yourself here; controller fixes pollute your context.
6. **Complete.** Ledger `Task N: complete (commits <base7>..<head7>, reviewed | self-reviewed)`. Record Minor findings as `Task N: minor (deferred): <one-liner>`. Mark the todo done.

### Implementer template

```
You are implementing one task of a plan, working in <worktree path>.

Context: <one line on where this task fits>
Requirements: read <brief path> first. It holds the exact values (names, signatures, strings, test cases) to use verbatim.
From earlier tasks: <interfaces and decisions the brief cannot know, or "none">
Conventions: <commit format and style rules binding this repo>

Implement the task, with tests where the brief asks for them. Run the tests that cover your change, commit, then re-read your diff against the brief and fix gaps and anything extra.
If a requirement is unclear, ask before starting. Never dispatch subagents. Stay within the task's files.

Write the full report (what you did, test command and output, decisions, concerns) to <report path>. Return only: status (DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED), commit hashes, one line of test results, concerns.
```

Copy the commit and style conventions you know bind this repo (CLAUDE.md, memory) into the Conventions line; subagents do not see them.

### Reviewer template (task and final)

```
Review <one task of a plan | a whole branch> from the diff alone.
Inputs: brief <path> (task review only), implementer report <path> (task review only), diff <path>.
Constraints that bind it (verbatim from the plan or spec): <exact values, formats, stated relationships>.
For the final review also read the plan at <path> (judge behaviour against its text) and the ledger at <path>: triage its Risk, minor, parked, and Ruling lines and say which must be fixed before merge.

Check that every requirement is met and nothing extra was built; then correctness bugs, tests that assert nothing, duplicated logic.
Do not re-run tests the report shows passing, and write no strengths section.
Return: Spec pass/fail, then findings as Critical / Important / Minor, each with file:line and a one-line reason. A requirement you cannot verify from the diff goes under "Cannot verify from diff".
```

Do not pre-judge findings for a reviewer. If the prompt you are writing says "do not flag" or "at most Minor", you are sparing yourself a fix round; let the reviewer raise it and adjudicate afterwards. Resolve each "Cannot verify" item yourself, since you hold the cross-task context; a real gap counts as a finding.

## Final review

When all tasks are complete, write the review package over the whole branch (`{ git log --oneline MERGE_BASE..HEAD; git diff --stat MERGE_BASE..HEAD; git diff MERGE_BASE..HEAD; } > "$WS/final.diff"`, where MERGE_BASE is the commit the branch started from, e.g. `git merge-base origin/develop HEAD`) and dispatch one reviewer on opus with the reviewer template. Give it the plan path as well: without the plan's text it can only guess at the intended behaviour and pads its report with speculative minors.

If it returns findings, dispatch ONE fix subagent with the complete list, never one fixer per finding. Re-review that fix diff once only when the final review reported a Critical finding. Park or rule on any residual finding; residual load-bearing ones surface to the user when finishing the branch.

## Finish

Collect every ledger line containing `Ruling:` into the final message under "Rulings I made", in order, each with its cost if wrong. This list is the only way the decisions you took on the user's behalf reach them. Add the risk flags you set yourself. Then `rm -rf "$WS"` (git history is the record) and use `superpowers:finishing-a-development-branch`.
