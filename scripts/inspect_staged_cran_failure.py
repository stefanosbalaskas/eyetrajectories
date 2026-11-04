#!/usr/bin/env python3
"""Inspect an EXISTING local staged R CMD check; never build, check or publish.

Run from the eyetrajectories checkout root:
  python scripts/inspect_staged_cran_failure.py
Or point at a specific existing candidate directory:
  python scripts/inspect_staged_cran_failure.py --candidate PATH

The diagnostic is written alongside the staged check, not inside Git.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys


PHASE = re.compile(r"^\* checking\b.*\.\.\.[ \t]*(ERROR|WARNING|NOTE)s?[ \t]*$", re.I)
START = re.compile(r"^\* (?:checking\b|DONE\b)", re.I)
STATUS = re.compile(r"^Status:[ \t]*(.+?)[ \t]*$", re.M)


def latest_candidate(root: Path) -> Path:
    staging = root.parent / "eyetrajectories_release_staging"
    candidates = list(staging.glob("*/eyetrajectories_*_from_*"))
    existing = [p for p in candidates
                if p.is_dir() and (p / "eyetrajectories.Rcheck" / "00check.log").is_file()]
    if not existing:
        raise FileNotFoundError(
            "No existing staged 00check.log under " + str(staging) +
            ". Specify --candidate with a previously staged candidate directory.")
    return max(existing, key=lambda p: (p.stat().st_mtime_ns, str(p)))


def warning_sections(content: str) -> list[dict[str, object]]:
    lines = content.splitlines()
    result = []
    for i, line in enumerate(lines):
        match = PHASE.match(line)
        if match is None:
            continue
        end = i + 1
        while end < len(lines) and not START.match(lines[end]) and not STATUS.match(lines[end]):
            end += 1
        result.append({
            "kind": match.group(1).upper(),
            "start_line": i + 1,
            "lines": lines[i:end],
        })
    return result


def diagnose(candidate: Path) -> tuple[dict[str, object], str]:
    log = candidate / "eyetrajectories.Rcheck" / "00check.log"
    if not log.is_file():
        raise FileNotFoundError("Missing existing check log: " + str(log))
    source = log.read_text(encoding="utf-8", errors="replace")
    statuses = STATUS.findall(source)
    if len(statuses) != 1:
        raise ValueError("Expected exactly one R CMD check Status; found " +
                         str(len(statuses)) + " in " + str(log))
    manifest_path = candidate / "STAGING_MANIFEST.json"
    manifest = (json.loads(manifest_path.read_text(encoding="utf-8"))
                if manifest_path.is_file() else {})
    sections = warning_sections(source)
    summary = {
        "diagnostic_only": True,
        "candidate_release_status": "HOLD - original staged R CMD check result unchanged",
        "candidate_directory": str(candidate),
        "check_log": str(log),
        "source_git_head": manifest.get("source_git_head", "UNKNOWN"),
        "source_version": manifest.get("source_version", "UNKNOWN"),
        "candidate_version": manifest.get("candidate_version", "UNKNOWN"),
        "original_check_status": statuses[0].strip(),
        "sections": sections,
    }
    report = [
        "STAGED_CRAN_EXISTING_CHECK_DIAGNOSTIC",
        "This reads the ORIGINAL staged check log: NO new R build/check performed.",
        "No package has been submitted, tagged or released.",
        "CANDIDATE_SOURCE_HEAD=" + str(summary["source_git_head"]),
        "CANDIDATE_SOURCE_VERSION=" + str(summary["source_version"]),
        "CANDIDATE_VERSION=" + str(summary["candidate_version"]),
        "CHECK_STATUS=" + str(summary["original_check_status"]),
        "WARNING_SECTIONS=" + str(sum(s["kind"] == "WARNING" for s in sections)),
        "NOTE_SECTIONS=" + str(sum(s["kind"] == "NOTE" for s in sections)),
        "ERROR_SECTIONS=" + str(sum(s["kind"] == "ERROR" for s in sections)),
        "ORIGINAL_00CHECK_LOG=" + str(log),
    ]
    for index, section in enumerate(sections, 1):
        report.extend(["", "=== SECTION " + str(index) + ": " +
                       str(section["kind"]) + " at 00check.log line " +
                       str(section["start_line"]) + " ==="])
        report.extend(section["lines"])
    if not sections:
        report.extend(["",
            "No individual phase sections matched the standard '* checking ... WARNING/NOTE' syntax.",
            "Inspect ORIGINAL_00CHECK_LOG directly. Do not interpret the status as passing."])
    report.extend(["", "CRAN_STATUS=HOLD - resolve WARNING and review all NOTEs",
                   "INDEPENDENT_PYTHON_CERTIFICATION=NOT IMPLIED"])
    return summary, "\n".join(report) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="Repository checkout root")
    parser.add_argument("--candidate", help="Exact existing staged candidate directory")
    args = parser.parse_args(argv)
    try:
        candidate = (Path(args.candidate).resolve() if args.candidate else
                     latest_candidate(Path(args.root).resolve()))
        summary, report = diagnose(candidate)
        text_path = candidate / "STAGED_CRAN_DIAGNOSTICS.txt"
        json_path = candidate / "STAGED_CRAN_DIAGNOSTICS.json"
        text_path.write_text(report, encoding="utf-8")
        json_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2) +
                             "\n", encoding="utf-8")
        print(report, end="")
        print("STAGED_CRAN_DIAGNOSTICS_FILE=" + str(text_path))
        print("STAGED_CRAN_DIAGNOSTICS_JSON=" + str(json_path))
        return 0
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print("STAGED_CRAN_DIAGNOSTICS_ERROR=" + str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
