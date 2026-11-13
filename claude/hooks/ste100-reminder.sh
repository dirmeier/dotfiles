#!/bin/sh
# Adds a plain-English rule (ASD-STE100) to every user message.
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"WRITING RULE (ASD-STE100 Simplified Technical English) for every reply to the user: Use short sentences (at most 20 words for instructions, 25 for descriptions). Use active voice. Use one word for one meaning, and use common words. Write one topic per paragraph. Do not use jargon, method words or skill words (for example: thin slice, probe, cell, SDD, widen, readout, harness) unless the user used them first. Explain every technical term in plain words the first time you use it. Write out abbreviations the first time. Before you send, read the reply again and replace any word the user may not know."}}
JSON
