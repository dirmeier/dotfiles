(Local copy of what `gh issue view 468 --json title,body,comments` returns, saved for a dry run.)

TITLE: Write meeting title, short summary and detailed summary from one transcript

BODY:
Part of #467.

## Goal
Find out if the local LLM can write the meeting title, the short summary and the detailed summary of a recording from one transcript, and keep the three texts consistent. A judge checks the result. This issue covers English only.

**Exit criterion:** A verdict (works, works with limits, or does not work) for each of the five questions below, and the report posted in this issue.

**Time-box:** Starts in Sprint 11. Ends when the report is posted, at the latest 29 November (end of Sprint 12).

## Terms
- **Title card:** the meeting title, with time and people.
- **LAGOM summary:** the short summary of at most 280 characters. It has three styles: Casual Recap, Formal Report and Action Focus.
- **Extended summary:** the detailed summary. It is built from content blocks such as next steps, open questions and quotes.
- **Back reference:** a mark such as `#12` that names the transcript turn which supports an item.

## Steps
1. The LLM writes one full summary of the transcript and names the meeting type.
2. It writes the meeting title once. All texts use the same title. It then writes the three LAGOM styles from the summary.
3. It writes text for every content block that has material. A fixed table keeps the best-fitting blocks for the meeting type. No block is ruled out.

Every action item, block item and quote carries a back reference.

## Questions
| Question | Pass mark (proposed) |
|---|---|
| Can the LLM name the meeting type? | Right type on at least 80% of generated transcripts |
| Is the LAGOM summary a faithful short version of the full summary? | At least 90% of its statements are supported by the full summary |
| Is the title the same in all texts? | 100% identical |
| Are the blocks supported, and does the filter keep good blocks? | Block items are supported by the full summary. We report how often the filter cuts a block that the judge rates as good. |
| Do back references point to supporting text? | At least 90% of references point to a turn that supports the item |

## Fixed choices
- **Meeting types:** status update, decision meeting, brainstorm, external call, casual chat.
- **Fallback style:** Casual Recap fits every meeting.
- **Blocks:** all blocks are hypotheses. This issue tests and refines them.
- **User preferences:** we set them in the prompt.
- **Judge:** LLM-as-a-judge, as in nexo-bench-llm. No human labels.

## Open questions
- Does the 280-character limit apply to every LAGOM style? Formal Report is described as "a bit longer". This issue uses 280 for all styles.
- Which local models are tested? Which model generates the transcripts and runs the judge?

## Out of scope
User testing on Figma prototypes, the legal disclaimer and watermark, feedback buttons, re-summarise and regenerate, the custom prompt option, the app UI, the mapping from turn number to audio time, and other languages (see the second issue).

## Related
#312 (earlier summary personalisation spike), #413 (grounding judge for action items)

COMMENTS:
(none)
