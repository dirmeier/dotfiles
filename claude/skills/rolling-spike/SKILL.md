---
name: rolling-spike
description: Run a technical spike or experiment as a rolling plan, in which findings reshape the plan as they arrive. It starts from a one-page question doc and an empty report skeleton, runs the risky probes and one thin end-to-end slice first, plans only the next part in full, and records VALIDATED / PARTIAL / INVALIDATED verdicts per part. Use this whenever the user starts or restructures a spike, a feasibility study, a benchmark or evaluation campaign, a "can we run X on Y" investigation, or any exploratory work whose answers are unknown up front, even if they don't say "spike". Also use it when an existing spike plan has grown into a long up-front task list, when the user asks how to structure exploratory work, or at a part boundary when the next part needs planning.
---

# Rolling spike

A spike answers questions whose answers nobody knows yet. A full design → plan → execute pipeline written before the first probe goes stale as soon as findings arrive. This skill keeps the plan short-sighted on purpose: decide what to learn, build the empty report, learn the riskiest thing first, and plan only the next step in detail.

## The artifacts

Create these at the start, in this order. Each is short.

1. **Question doc**: one page; the template is below.
2. **Report skeleton**: the final result tables with empty cells, plus a skeleton of the recommendation doc. Every measurement in the spike must fill a cell here. A measurement with no cell to fill doesn't get run, and a cell that no part fills gets an owner or is cut. This stops the spike from drifting into interesting side quests.
3. **Glossary** (optional, but useful when terms are overloaded): a list of the domain terms with one meaning each, and the words to avoid.
4. **Rolling plan**: the parts table, with the next one or two parts detailed (see below).
5. **Backlog**: draft detail for later parts. It is input for re-planning, not a commitment.
6. **Playbook** (when the spike teaches a reusable skill, such as exporting a model or porting a kernel): it grows with every part and is finished at the end.

Put them wherever the repo keeps design docs and plans. Follow existing conventions over these names.

### Question doc template

```markdown
# <Spike name>

## Questions
Riskiest first. Each one is falsifiable:
Q1. Given <setup>, when <action>, then <observable outcome + threshold>.
Q2. ...

## Deciding metric
The one number (or short list) the final recommendation turns on.

## Scope
What is in. Name the models, components, platforms and datasets.

## Non-goals
What is out, even if tempting. Scope creep is the main way spikes die.

## Hard rules
Constraints that never bend (licensing, data handling, what may be committed, budgets).

## Check-ins
The fixed points where the user reads findings and steers (see below).
```

Two to five questions is right. If there are more, the spike is several spikes, or some questions are really tasks.

## Order of work

1. **Probes**: small, throwaway checks of the riskiest assumptions (does the toolchain install, does the op exist, does the runtime load the file). Probes take hours, not days. A failed probe changes the plan before anything is built on top of it.
2. **Thin vertical slice**: one real cell of the report, filled end to end through the real harness, with the real scoring, on real data. This flushes out integration problems that unit work hides.
3. **Widen**: fill the remaining cells, one part at a time.
4. **Readouts and recommendation**: fill the recommendation skeleton from the report.

## Rolling plan

- The parts table lists every part with a **goal** and a **done when**. Only the next one or two parts get full task detail.
- Write the detailed plan for a part only when the previous part has finished, using the findings it produced. Use the repo's normal plan-writing skill for this (for example `superpowers:writing-plans`).
- Show the user the next part's plan before starting it.
- When findings invalidate later parts, rewrite the parts table. Don't defend the old plan. Changing the plan is what a spike is for.

Parts table shape:

| Part | Goal | Done when | Detail |
|---|---|---|---|
| 01 | Scaffold + probes | Every probe has a verdict | Tasks 1–3 |
| 02 | Thin slice | One real cell filled and checked | Tasks 4–8 |
| 03 | ... | ... | backlog |

## Verdicts and findings

Every question and every probe ends with a verdict:

- **VALIDATED**: it works as hoped, with evidence.
- **PARTIAL**: it works under constraints. Name the constraints.
- **INVALIDATED**: it doesn't work. Say why and what that rules out.

Each part closes with a **Findings** section, in the PR description if the work goes through PRs, otherwise in the plan:

```markdown
## Findings
**Verdicts**
- Q2: PARTIAL. Runs on GPU only; 14 of 312 ops fall back to CPU (log: <where>).
**Surprises**
- ...
**Plan changes**
- Part 04 now ... because ...
**Playbook additions**
- <problem> → <fix> (why)
```

Evidence means a pointer to something the user can look at: a log, a table cell, a command and its output. A bare claim is not evidence.

If the repo uses an umbrella branch with numbered part branches, each part's PR carries its Findings, so the merged PRs read as the story of the spike.

## Check-ins

Fix them in the question doc, so stopping to talk is planned rather than ad hoc. Typical ones:

- after the probes
- after the thin slice
- after each key readout (the first answer to the deciding metric)
- after a sweep, when the user picks what goes forward
- after the recommendation

At a check-in, present the verdicts and the proposed next part, then wait. The user steers; don't carry on into the next part on your own.

## Things that go wrong

- **Time-boxing the learning.** When a goal of the spike is to learn how to do something hard (exports, ports, graph rewrites), keep going until it is done and write down what it took. "Gave up after N hours" answers nothing. Time-box probes, not learning.
- **Gates that stop the spike.** A failed question is a finding. Record INVALIDATED and continue with what's still open, unless the user decides otherwise at a check-in.
- **Measuring without a cell.** If a number won't land in the report skeleton, ask whether it should be added to the skeleton before measuring it.
- **The 30-task plan up front.** It goes stale after the probes. Detail the next part only.
- **Quietly dropping a question.** If scope shrinks, say so at a check-in and update the question doc.
