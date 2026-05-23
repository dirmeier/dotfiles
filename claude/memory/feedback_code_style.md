---
name: Python coding conventions
description: Style rules for all Python code written in this project — readability, naming, structure
type: feedback
originSessionId: 4c5297e6-f7f5-43df-bb8b-e2cbf0ae4837
---
One instruction per line. No nested function calls — every intermediate result gets its own named variable.

**Why:** User has asked for this repeatedly and finds it non-negotiable for readability.

Bad:
```python
decoded = codec.decode(codec.encode(audio, sr), sr)
parsed = codec.parse_codec_to_list(codec.encode(audio, sr))
assert all(d.dtype == np.float32 for d in codec.decode(codec.encode(audio, sr), sr))
```

Good:
```python
encoded = codec.encode(audio, sr)
decoded = codec.decode(encoded, sr)

encoded = codec.encode(audio, sr)
parsed = codec.parse_codec_to_list(encoded)

encoded = codec.encode(audio, sr)
decoded = codec.decode(encoded, sr)
assert all(d.dtype == np.float32 for d in decoded)
```

## General conventions

- **Naming**: `snake_case` for variables and functions, `PascalCase` for classes. Names should be descriptive — `encoded_audio` beats `enc`, `sample_rate` beats `sr` in non-obvious contexts.
- **Type hints**: Always annotate function signatures (args and return type). Use `list[T]` and `tuple[T, ...]` (lowercase, Python 3.9+), not `List`/`Tuple` from `typing`.
- **No magic numbers**: Extract constants at module level with a descriptive name (e.g. `_SNR_FLOOR_DB = 15.0`).
- **Comprehensions**: Flat list comprehensions are fine. Avoid nested comprehensions — split into a loop instead.
- **Imports**: Standard library → third-party → local, each group separated by a blank line. No wildcard imports.
- **f-strings**: Prefer f-strings over `.format()` or `%` formatting.
- **Truthiness**: Use `if x:` not `if x is not None:` / `if len(x) > 0:` where appropriate.
- **Early returns**: Prefer early returns over deeply nested `if`/`else`.
- **No unused variables**: Don't assign results that aren't used. Use `_` only for genuinely throwaway loop vars.
- **`enumerate` and `zip`**: Use instead of index-based loops. Always pass `strict=True` to `zip` when lengths should match.
