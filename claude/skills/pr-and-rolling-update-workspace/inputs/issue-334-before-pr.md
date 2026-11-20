(Local copy of what `gh issue view 334 --json title,body,comments` returned BEFORE any PR for the spike existed, saved for a dry run. There is no PR yet.)

TITLE: Spike: typed artefact extraction — email, calendar event, task list

BODY:
**Exit criterion:** Per-primitive routing and field-extraction accuracy measured over real transcripts, plus a recommendation on what to change.

**Time-box:** 3–5 days

## Problem

Three artefact primitives exist today:

- draft email
- meeting / calendar event
- task list — catch-all for anything that fits neither of the above

Nothing measures whether the right primitive is chosen or whether its fields are usable. These drafts feed real Workspace integrations, so 'need to organise a follow-up meeting with Jon on Monday next week about project XYZ' has to come out as a Calendar event with attendee, date and subject filled in.

Routing errors matter as much as bad field values. A follow-up meeting that comes out as a task-list item instead of a Calendar event still looks like a valid result, so the eval has to count it as an error.

## Deliverables

- Test Gemma 4 E2B over chunked transcript from #252.
- Run a one-shot pass with a stronger model as the reference ceiling.
- Routing accuracy per primitive, plus a confusion matrix showing what leaks into the task-list catch-all.
- Field-level accuracy for calendar (attendee, date/time, subject) and email (recipient, subject, body gist).
- A written recommendation: prompt change, schema change, or a separate extraction pass.

## Out of scope

- New primitives beyond these three.
- Production wiring to Workspace APIs.
- Any production implementation — throwaway harness and recommendation only.

COMMENTS:
[2026-08-25T15:24:16Z] url=https://github.com/Logitech/vnv-nexo-benchmark/issues/334#issuecomment-1111111111
@orivier3 how do you see this growing?

Do we define each API as an MCP tool using this protocol definition and mostly try to evaluate the ability of a small local LM to work with an MCP protocol / re-use some libraries?

https://modelcontextprotocol.io/specification/2026-07-28/server/tools#tool
---
[2026-10-01T12:55:05Z] url=https://github.com/Logitech/vnv-nexo-benchmark/issues/334#issuecomment-1111111112
Branch `334-349-350-typed-actions` pushed (`aaf81ee..HEAD`): typed artefact schema/registry (`task`/`email_draft`/`calendar_event`/`followup_ai`/`none`) plus a single-pass vs. two-pass extraction comparison on the `ami30` AMI-domain panel.

Full `AlignmentJudge` results and the ship/no-ship call are posted on #349: https://github.com/Logitech/vnv-nexo-benchmark/issues/349#issuecomment-5931905982

Note: this is cloud-provider extraction (anthropic/openai/gemini), not the local chunking/L1/L2/L3 + GBNF pipeline this issue originally scoped — that local-vs-cloud comparison still hasn't been started.
