"""Check the dry-run outputs of pr-and-rolling-update against the saved checks.

Usage: python3 -I grade.py <iteration dir>

Reads only the text files in <iteration dir>/eval-*/{with_skill,without_skill}/outputs/.
Writes grading.json next to each outputs folder.
Checks that need a human or model reading are in JUDGED below, filled in after reading the files.
"""
import json
import re
import sys
from pathlib import Path

MARKER = "<!-- pr-and-rolling-update -->"

# Filled in by hand after reading the outputs: {(eval_name, config): {check number: (passed, evidence)}}
JUDGED: dict = {}
if (Path(__file__).parent / "judged.json").exists():
    raw = json.loads((Path(__file__).parent / "judged.json").read_text())
    for key, checks in raw.items():
        ev, cfg = key.split("|")
        JUDGED[(ev, cfg)] = {int(n): (v[0], v[1]) for n, v in checks.items()}


def jkey(d: Path) -> tuple:
    """(eval folder name, config name) for an outputs folder at <eval>/<config>/run-1/outputs."""
    return (d.parent.parent.parent.name, d.parent.parent.name)


def read(d: Path, name: str) -> str:
    p = d / name
    return p.read_text() if p.exists() else ""


def nonempty_lines(text: str) -> list:
    return [ln for ln in text.splitlines() if ln.strip()]


def last_line(text: str) -> str:
    lines = nonempty_lines(text)
    return lines[-1].strip() if lines else ""


def edit_lines(body: str) -> list:
    return [(i, ln) for i, ln in enumerate(body.splitlines()) if re.match(r"^\s*EDIT \(\d{4}-\d{2}-\d{2}\):", ln)]


def line_index(body: str, pattern: str):
    for i, ln in enumerate(body.splitlines()):
        if re.search(pattern, ln):
            return i
    return None


def command_lines(commands_md: str) -> list:
    """Lines inside fenced code blocks, without comment lines. Skips prose such as 'left out' lists."""
    out, inside = [], False
    for ln in commands_md.splitlines():
        if ln.strip().startswith("```"):
            inside = not inside
            continue
        if inside and not ln.strip().startswith("#"):
            out.append(ln)
    return out


def status_table(body: str) -> str:
    m = re.search(r"## Status.*?(?=\n## )", body, re.S)
    return m.group(0) if m else ""


def check(text, passed, evidence):
    return {"text": text, "passed": bool(passed), "evidence": evidence}


def grade_eval0(d: Path, texts: list) -> list:
    body, cmt, cmds = read(d, "pr-body.md"), read(d, "issue-comment.md"), read(d, "commands.md")
    code = "\n".join(command_lines(cmds))
    res = []
    ll = last_line(body)
    res.append(check(texts[0], ll == "Closes #468", f"last line is {ll!r}"))
    edits = edit_lines(body)
    ok = len(edits) == 1 and edits[0][1].startswith("EDIT (2026-11-13)") and "part 04" in edits[0][1].lower()
    res.append(check(texts[1], ok, f"EDIT lines found: {[e[1].strip() for e in edits]}"))
    n, dt = line_index(body, r"^\*\*Next:\*\*"), line_index(body, r"^Details:")
    ok = bool(edits) and n is not None and dt is not None and n < edits[0][0] < dt
    res.append(check(texts[2], ok, f"Next at line {n}, EDIT at {edits[0][0] if edits else None}, Details at {dt}"))
    st = status_table(body)
    names = ["Back references", "LAGOM faithfulness", "Blocks", "Meeting type", "Title"]
    missing = [x for x in names if not re.search(rf"^\|\s*{x}\s*\|", st, re.M)]
    res.append(check(texts[3], not missing, f"missing rows: {missing}"))
    stale = re.search(r"\*\*Next:\*\*\s*part 04 is the full run", body)
    res.append(check(texts[4], not stale, "old Next line still present" if stale else "old Next line is gone"))
    for idx in (5, 6):  # judged
        j = JUDGED.get(jkey(d), {}).get(idx)
        res.append(check(texts[idx], j[0], j[1]) if j else check(texts[idx], False, "NOT YET JUDGED"))
    cl = nonempty_lines(cmt)
    ok = bool(cl) and cl[0].strip() == MARKER and len(cl) <= 4
    res.append(check(texts[7], ok, f"{len(cl)} lines, first line {cl[0].strip()!r}" if cl else "empty"))
    ok = bool(re.search(r"/(blob|tree)/spike/467-468-summary-layers/", cmt)) and not re.search(r"/(blob|tree)/[0-9a-f]{7,40}/", cmt)
    res.append(check(texts[8], ok, "branch URL found" if ok else "no branch URL, or a commit URL"))
    push = re.search(r"git push( -u)? origin spike/467-468-summary-layers\b", code)
    force = re.search(r"--force|--force-with-lease|\bgit push\b.*\s-f\b", code)
    edit = re.search(r"gh pr edit 488\b.*--body-file -", code)
    res.append(check(texts[9], push and not force and edit, f"push={bool(push)} force={bool(force)} edit_stdin={bool(edit)}"))
    n_c = len(re.findall(r"gh issue comment 468\b", code))
    patch = re.search(r"PATCH", code)
    res.append(check(texts[10], n_c == 1 and not patch, f"gh issue comment count={n_c}, PATCH={bool(patch)}"))
    bad = re.findall(r"gh pr ready|gh pr merge|--no-verify", code)
    res.append(check(texts[11], not bad, f"forbidden commands found: {bad}"))
    return res


def grade_eval1(d: Path, texts: list) -> list:
    body, cmt, cmds, title = read(d, "pr-body.md"), read(d, "issue-comment.md"), read(d, "commands.md"), read(d, "pr-title.md").strip()
    code_lines = command_lines(cmds)
    code = "\n".join(code_lines)
    res = []
    ok = re.match(r"^spike\(.+\): .+\(#334\)$", title) and "[DO NOT MERGE]" not in title and not title.startswith("feat")
    res.append(check(texts[0], ok, f"title: {title!r}"))
    ip = next((i for i, ln in enumerate(code_lines) if re.search(r"\bgit push\b", ln)), None)
    ic = next((i for i, ln in enumerate(code_lines) if re.search(r"gh pr create", ln)), None)
    res.append(check(texts[1], ip is not None and ic is not None and ip < ic, f"push at code line {ip}, create at {ic}"))
    ok = re.search(r"gh pr create[^\n]*--draft", code) and re.search(r"--base develop", code) and re.search(r"--head spike/334-typed-artefact-routing", code) and re.search(r"--body-file -", code)
    res.append(check(texts[2], ok, "draft/base/head/stdin flags " + ("all present" if ok else "not all present")))
    ok = not re.search(r"^##\s+Edits", body, re.M) and not edit_lines(body)
    res.append(check(texts[3], ok, "no Edits section or EDIT line" if ok else "has Edits section or EDIT line"))
    ll = last_line(body)
    ok = ll == "Closes #334" and "Generated with" not in body
    res.append(check(texts[4], ok, f"last line {ll!r}; Generated-with={'Generated with' in body}"))
    ok = bool(re.search(r"blob/spike/334-typed-artefact-routing/[^\s)]*RECOMMENDATION\.md", body)) and not re.search(r"blob/[0-9a-f]{7,40}/", body)
    res.append(check(texts[5], ok, "branch link to RECOMMENDATION.md" if ok else "no branch link, or a commit-pinned link"))
    found = re.findall(r"VALIDATED|PARTIAL|INVALIDATED", body)
    res.append(check(texts[6], found, f"verdict words: {sorted(set(found))}"))
    j = JUDGED.get(jkey(d), {}).get(7)
    res.append(check(texts[7], j[0], j[1]) if j else check(texts[7], False, "NOT YET JUDGED"))
    cl = nonempty_lines(cmt)
    ok = bool(cl) and cl[0].strip() == MARKER and "#NNN" in cmt and "blob/spike/334-typed-artefact-routing/" in cmt
    res.append(check(texts[8], ok, f"first line {cl[0].strip()!r}; #NNN={'#NNN' in cmt}" if cl else "empty or none"))
    n_c = len(re.findall(r"gh issue comment 334\b", code))
    edit = re.search(r"gh issue edit", code)
    res.append(check(texts[9], n_c == 1 and not edit, f"gh issue comment count={n_c}, issue edit={bool(edit)}"))
    return res


def grade_eval2(d: Path, texts: list) -> list:
    body, cmt, cmds = read(d, "pr-body.md"), read(d, "issue-comment.md"), read(d, "commands.md")
    code_lines = command_lines(cmds)
    code = "\n".join(code_lines)
    res = []
    ok = re.search(r"PATCH", code) and re.search(r"issues/comments/1111111113", code)
    res.append(check(texts[0], ok, "PATCH to 1111111113 " + ("found" if ok else "not found")))
    n_c = len(re.findall(r"gh issue comment\b", code))
    edit = re.search(r"gh issue edit", code)
    res.append(check(texts[1], n_c == 0 and not edit, f"gh issue comment count={n_c}, issue edit={bool(edit)}"))
    cl = nonempty_lines(cmt)
    ok = len(cl) >= 2 and cl[0].strip() == MARKER and cl[1].strip().startswith("Spike result:")
    res.append(check(texts[2], ok, f"line 2: {cl[1][:50]!r}" if len(cl) > 1 else "too short"))
    ok = "separate extraction pass" in cmt and "one second call per chunk" in cmt
    res.append(check(texts[3], ok, "both phrases present" if ok else "phrases missing"))
    ok = "#485" in cmt and re.search(r"blob/spike/334-typed-artefact-routing/[^\s)]*RECOMMENDATION\.md", cmt)
    res.append(check(texts[4], ok, "PR number and branch link " + ("present" if ok else "not both present")))
    ll = last_line(body)
    res.append(check(texts[5], ll == "Closes #334", f"last line {ll!r}"))
    edits = edit_lines(body)
    li = line_index(body, r"^Closes #334")
    ok = len(edits) == 1 and edits[0][1].startswith("EDIT (2026-11-13)") and li is not None and edits[0][0] < li
    res.append(check(texts[6], ok, f"EDIT lines: {[e[1].strip()[:60] for e in edits]}"))
    j = JUDGED.get(jkey(d), {}).get(7)
    res.append(check(texts[7], j[0], j[1]) if j else check(texts[7], False, "NOT YET JUDGED"))
    ready = re.search(r"gh pr ready", code)
    title_edit = [ln for ln in code_lines if "gh pr edit" in ln and "--title" in ln]
    res.append(check(texts[8], not ready and not title_edit, f"gh pr ready={bool(ready)}, --title in pr edit={bool(title_edit)}"))
    return res


GRADERS = {0: grade_eval0, 1: grade_eval1, 2: grade_eval2}


def main(iteration: Path) -> None:
    for ev_dir in sorted(iteration.glob("eval-*")):
        meta = json.loads((ev_dir / "eval_metadata.json").read_text())
        texts = meta["assertions"]
        for cfg in ("with_skill", "without_skill"):
            run = ev_dir / cfg / "run-1"
            out = run / "outputs"
            if not out.exists():
                continue
            exps = GRADERS[meta["eval_id"]](out, texts)
            passed = sum(e["passed"] for e in exps)
            grading = {
                "expectations": exps,
                "summary": {"passed": passed, "failed": len(exps) - passed, "total": len(exps), "pass_rate": round(passed / len(exps), 2)},
            }
            (run / "grading.json").write_text(json.dumps(grading, indent=2))
            print(f"{ev_dir.name:45s} {cfg:14s} {passed}/{len(exps)}")
            for e in exps:
                if not e["passed"]:
                    print(f"    FAIL: {e['text'][:90]}\n          {e['evidence'][:140]}")


if __name__ == "__main__":
    main(Path(sys.argv[1]))
