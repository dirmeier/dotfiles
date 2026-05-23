---
name: Always ask before committing or opening a PR
description: Never commit or create a PR without explicit user instruction in that moment
type: feedback
originSessionId: 4c5297e6-f7f5-43df-bb8b-e2cbf0ae4837
---
Never commit or open a PR unless the user explicitly asks for it in that message.

**Why:** Even if the user asked earlier in the conversation, circumstances change (tests fail, linter errors, work in progress). A prior request does not carry forward.

**How to apply:** Treat every commit and PR as requiring fresh, explicit confirmation. If in doubt, do not commit — ask first.

Before committing or opening a PR, always run the full linting suite in this order:
```
uv run ruff format src/ tests/
uv run ruff check --fix src/ tests/
uv run mypy src/
```
All checks must pass before committing.

Validate the commit message with gitlint before running `git commit`:
```
echo "<draft commit message>" | uv run gitlint
```
Fix any violations before proceeding.

Never add a `Co-Authored-By: Claude` trailer to any git commit message.

**Why:** User explicitly does not want Claude listed as co-author.

**How to apply:** Omit the Co-Authored-By line from all commit messages in every project.
