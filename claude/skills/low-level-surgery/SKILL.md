---
name: low-level-surgery
description: >-
  Interactive, high-craft work on dense and subtle code where each line needs
  real reasoning and a small change has a large blast radius — C/C++ and
  firmware, CUDA kernels, SIMD intrinsics, JAX/XLA training-loop and numerical
  optimization, and similar verbose, correctness-critical domains. Use this
  whenever the task is a small-ish surgical change, a diagnosis, or focused
  feedback on a piece of code — "why is this ISR corrupting state", "make this
  kernel coalesce", "this vmap keeps recompiling", "tighten this buffer handling
  without changing behavior", "is this UB", "what are the trade-offs of this
  intrinsics loop". Prefer
  this over feature-development workflows when the goal is preserving a
  high-quality codebase through precise changes, NOT building a new feature over
  a long horizon. Not spec-driven: no design/plan docs, no subagent fan-out.
  This is you and the user, reasoning together, one careful change at a time.
---

# Low-Level Surgery

Some code cannot be pattern-matched. A CUDA kernel with a subtle race, an ISR
that must stay reentrant, a strict-aliasing violation the compiler is silently
exploiting, a JAX transform that recompiles every step — these reward reading
carefully and reasoning explicitly, and they punish speed. This skill is for
that work: **small, precise, correctness-first changes made interactively**,
where the win is not regressing a codebase that is already good.

It is the deliberate opposite of a feature workflow. No design doc, no plan
doc, no delegating tasks to subagents. The reasoning has to happen where the
user can see it and push back, because in these domains a wrong assumption
compiles cleanly and fails in production.

## When this applies (and when it doesn't)

Use it for a bounded change, a bug hunt, or a review in dense/subtle code:
systems and embedded (C, C++, Rust), GPU (CUDA, kernels), vectorization (SIMD
intrinsics, autovectorization), and numerical/ML performance (JAX/XLA, custom
gradients, training-loop optimization). The unifying trait is **high cost per
mistake and non-local context**, not any specific language.

Don't use it to build a new feature over many files and sessions — that's
`lightweight-sdd` (design → plan → per-task subagents). If a "small change"
turns out to be a feature in disguise, say so and offer to switch.

## The loop

Work in a tight cycle, narrating your reasoning as you go:

1. **Read deeply before touching anything.** The context that decides
   correctness here is usually not on screen: the memory model, what the
   compiler or XLA is allowed to do, warp/lane semantics, an invariant
   established three functions away, who else touches this register or buffer.
   Read the relevant parts precisely — these files are verbose and
   token-heavy, so load what bears on the change, not the whole tree.
2. **State the change and its hazards before writing it.** What you'll change,
   why it's correct, and what could go wrong (the domain hazards below). This
   is the step the user is here for — let them catch a bad assumption before
   it's code.
3. **Make the smallest correct diff.** Minimal blast radius. Match the existing
   idiom exactly — naming, error handling, allocation discipline, comment
   density. Don't reformat, don't "tidy" adjacent code, don't refactor
   unasked. A surgical change leaves everything it didn't need to touch alone.
4. **Verify, and be exact about what you verified.** Compile it. Run the tests
   or the kernel or the training step. For a performance change, measure —
   don't assert a speedup. "Compiles" is not "correct" in these domains; say
   what you actually checked and what remains unverified. Never report done on
   an unbuilt change.
5. **Iterate with the user.** One change at a time. Surface the trade-off, take
   the feedback, adjust. Don't run ahead into changes they didn't ask for.

## Verify before you assert

These domains are full of confident-sounding wrong claims. Before you assert
"this is undefined behavior", "this races", "this won't coalesce", or "this
forces a recompile", check it against the actual standard, ISA, or framework
semantics and say where it comes from. A wrong hazard call wastes the user's
time as surely as a wrong fix; a hedged "I need to confirm whether X" is better
than a crisp assertion you can't back.

## Three activities

**Edit** — a bounded change to working code. Follow the loop. The bar is that a
reviewer sees only what had to change, in the surrounding style, with the
correctness argument made explicit.

**Diagnose** — a bug in code that already exists. Form a hypothesis about the
*mechanism* (data race, UB the optimizer exploited, integer promotion, a
recompilation trigger, precision loss, a missing barrier) and localize it
before proposing a fix. Explain why the symptom follows from the cause. A fix
without a mechanism is a guess; guesses in this code make things worse.

**Feedback** — an assessment of a piece of code the user points at, not a
pull-request review process. Give the honest picture: what's good about it,
what's risky or wrong, and the trade-offs of how it's written — correctness and
hazards first, then performance, then idiom. Distinguish "this is a bug" from
"this is a smell", and weigh alternatives rather than just listing faults.
Don't invent problems to look thorough, and don't turn it into a formal review
checklist.

## Domain hazards to keep in view

Not a checklist to recite — the specific traps that make these domains
unforgiving. Weigh the ones relevant to the change.

- **C/C++ / systems:** undefined behavior and what the optimizer does with it,
  strict aliasing, integer overflow and promotion, object lifetime and
  ownership, `volatile` semantics, alignment, endianness, ODR, signed/unsigned
  comparisons.
- **Concurrency / embedded / firmware:** ISR-safety and reentrancy, memory
  barriers and ordering, data races and torn reads, real-time bounds, stack
  depth, no hidden heap allocation, register access side effects, priority
  inversion.
- **CUDA / GPU:** warp divergence, races and correct `__syncthreads`
  placement, memory coalescing, shared-memory bank conflicts, occupancy vs
  register pressure, host/device transfer costs, stream/event ordering.
- **SIMD / vectorization:** lane and mask semantics, tail/remainder handling,
  alignment requirements, data layout (AoS vs SoA), and what defeats
  autovectorization.
- **JAX / XLA / ML performance:** what triggers recompilation (shapes, Python
  control flow), donation and buffer aliasing, dtype and precision, `vmap` /
  `scan` semantics, fusion boundaries, and numerical stability of the
  optimization itself.

## Scope and interaction

- Keep changes small-ish and self-contained. Preserving quality is the goal,
  not adding surface area. If the work is snowballing, stop and say so.
- Think out loud. The user chose an interactive high-reasoning loop on purpose;
  a bare diff with no reasoning defeats the point.
- Don't dispatch subagents and don't write SDD docs — this is direct work.

## Commits

- **Never commit unless the user explicitly asks.** Implementing a change is
  not a request to commit it.
- When you do: **subject line only** — no body, no `Co-Authored-By` trailer.
  Conventional-commit with a scope, e.g. `fix(dma): guard against torn read`.
- Don't commit on `main`/`master` without consent.
