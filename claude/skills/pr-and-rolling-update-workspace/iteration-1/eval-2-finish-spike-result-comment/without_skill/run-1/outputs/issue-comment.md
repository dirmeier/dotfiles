<!-- pr-and-rolling-update -->
Draft PR #485 holds the final results. Last update: 2026-11-13 (spike finished).
Results are written to https://github.com/Logitech/vnv-nexo-benchmark/blob/baf0e381/experiments/334-typed-artefact-routing/RECOMMENDATION.md.

**Recommendation:** use a separate extraction pass with one second call per chunk.

- **Round 1** (90 planted moments): routing 57% to 72%, fields 50% to 66%. Cloud ceiling: 89% and 97%.
- **Round 2** (192 planted moments, three difficulty levels): found with the right type 45% to 64%. Cloud ceiling: 80%.
- **Cost:** 2.0 times the calls of the baseline (at most 2 per chunk), 1.2 times the prompt tokens, 1.4 times the time.
- **Watch:** false alarms on `none` moments rise from 8% to 19%. Follow-up items stay weak at 15%.
- **Open items:** the next steps are listed in the RECOMMENDATION.md and in PR #485.
