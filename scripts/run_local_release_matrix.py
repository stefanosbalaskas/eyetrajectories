#!/usr/bin/env python3
"""Reproducible local eyetrajectories qualification without GitHub Actions.

Only an actual child R process can pass a platform. This orchestrator has no
publish/tag/merge operations, and never upgrades independent certifications.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import time

QUALIFY = "source('scripts/qualify_experimental_candidate.R')"
PY312_GUARD = (
    "cfg<-reticulate::py_config(); "
    "if(!grepl('^3\\\\.12(\\\\.|$)',cfg$version)) "
    "stop(paste('Expected reticulate Python 3.12, found', cfg$version, cfg$python)); "
    "cat('RETICULATE_PYTHON_312_CONFIRMED=',cfg$python,'\\n',sep=''); "
)
SHA_RE = re.compile(r"^[0-9a-f]{40}$")


def git_output(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args],
                                   text=True, stderr=subprocess.STDOUT).strip()


def validate_root(root: Path) -> tuple[str, str]:
    d = root / "DESCRIPTION"
    if not d.is_file() or not (root / "scripts/qualify_experimental_candidate.R").is_file():
        raise ValueError("Require the eyetrajectories repository checkout root")
    content = d.read_text(encoding="utf-8")
    if not re.search(r"^Package: eyetrajectories\s*$", content, re.M):
        raise ValueError("Incorrect DESCRIPTION Package field")
    version = re.search(r"^Version:\s*(\S+)\s*$", content, re.M)
    if not version:
        raise ValueError("Missing DESCRIPTION version")
    sha = git_output(root, "rev-parse", "HEAD")
    if not SHA_RE.fullmatch(sha):
        raise ValueError("Cannot pin Git HEAD")
    # Include untracked source files. .gitignore excludes generated artifacts.
    dirty = git_output(root, "status", "--porcelain", "--untracked-files=normal")
    if dirty:
        raise ValueError("Refuse exact-head qualification with dirty checkout:\n" + dirty[:3000])
    return sha, version.group(1)


def interpret_log(log: str, returncode: int, sha: str, require_py312: bool) -> tuple[str, str]:
    if returncode != 0:
        return "FAIL", f"Child process exit code {returncode}"
    expected = [
        f"EXPERIMENTAL_R_CANDIDATE_HEAD={sha}",
        "R_CMD_CHECK_FINALITY=VERIFIED:",
        "CRAN_VERDICT_CONFIRMED=PASS",
        "R CMD check errors: 0",
        "R CMD check warnings: 0",
        "Native source example: PASS",
        "native_r_offline: QUALIFICATION COMPLETED WITHOUT TEST FAILURES",
        "python_1_2_direct_source: QUALIFICATION COMPLETED WITHOUT TEST FAILURES",
        "NO PACKAGE HAS BEEN PUBLISHED OR TAGGED.",
    ]
    if require_py312:
        expected.append("RETICULATE_PYTHON_312_CONFIRMED=")
    missing = [m for m in expected if m not in log]
    if missing:
        return "FAIL", "Missing mandatory proof: " + "; ".join(missing)
    found = re.search(r"R CMD check notes:\s*(\d+)", log)
    if found is None:
        return "FAIL", "Missing check NOTE count"
    return ("PASS_WITH_NOTE_REVIEW", f"Actual local R checks passed; {found.group(1)} NOTE(s) require review"
            ) if int(found.group(1)) else ("PASS", "Actual local R qualification passed with zero NOTES")


def run_logged(command: list[str], cwd: Path, logfile: Path,
               env: dict[str, str] | None = None) -> int:
    logfile.parent.mkdir(parents=True, exist_ok=True)
    with logfile.open("w", encoding="utf-8", errors="replace") as out:
        out.write("COMMAND: " + json.dumps(command) + "\n")
        out.write("CWD: " + str(cwd) + "\n")
        out.flush()
        try:
            process = subprocess.Popen(command, cwd=str(cwd), env=env,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                encoding="utf-8", errors="replace")
            assert process.stdout is not None
            for line in process.stdout:
                out.write(line)
                out.flush()
                print(line, end="", flush=True)
            return process.wait()
        except OSError as err:
            out.write("EXECUTION ERROR: " + str(err) + "\n")
            return 127


def wsl_prefix(distribution: str | None) -> list[str]:
    prefix = ["wsl.exe"]
    if distribution:
        prefix.extend(["--distribution", distribution])
    return prefix + ["--exec"]


def wsl_command(root: Path, distribution: str | None, expression: str) -> list[str]:
    prefix = wsl_prefix(distribution)
    translated = subprocess.check_output(prefix + ["wslpath", "-a", "-u", str(root)],
        text=True, stderr=subprocess.STDOUT).strip()
    if not translated.startswith("/"):
        raise ValueError("WSL did not return an absolute Linux path")
    script = "cd " + shlex.quote(translated) + " && Rscript --vanilla -e " + shlex.quote(expression)
    return prefix + ["/bin/sh", "-c", script]


def docker_command(root: Path, image: str, expression: str) -> list[str]:
    if not image or any(c.isspace() for c in image):
        raise ValueError("Docker image must be a prebuilt, explicitly named image")
    # Mount the parent so the existing qualification report directory is writable.
    return ["docker", "run", "--rm", "--network", "none", "--mount",
            "type=bind,source=" + str(root.parent) + ",target=/local-ci",
            "--workdir", "/local-ci/" + root.name, image,
            "Rscript", "--vanilla", "-e", expression]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="Repo root (default: current directory)")
    parser.add_argument("--targets", default="host", help="Comma-separated: host,wsl,docker")
    parser.add_argument("--rscript", action="append", help="Repeat for multiple locally installed R versions")
    parser.add_argument("--wsl-distribution", help="Optional installed WSL distribution")
    parser.add_argument("--docker-image", help="Prebuilt Docker image with R + package dependencies")
    parser.add_argument("--require-python312", action="store_true", help="Require reticulate Python 3.12 in each process")
    parser.add_argument("--output-dir", help="Evidence path, default: sibling eyetrajectories_local_matrix")
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()
    try:
        sha, version = validate_root(root)
    except (ValueError, OSError, subprocess.CalledProcessError) as err:
        print("PREFLIGHT FAIL:", err, file=sys.stderr)
        return 2
    targets = [t.strip() for t in args.targets.split(",") if t.strip()]
    if not targets or len(targets) != len(set(targets)) or set(targets) - {"host", "wsl", "docker"}:
        parser.error("Select distinct targets from host,wsl,docker")
    stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    out = Path(args.output_dir).resolve() if args.output_dir else root.parent / "eyetrajectories_local_matrix" / (stamp + "_" + sha[:12])
    if out.exists() and any(out.iterdir()):
        print("PREFLIGHT FAIL: evidence directory already populated", file=sys.stderr)
        return 2
    out.mkdir(parents=True, exist_ok=True)
    expression = (PY312_GUARD if args.require_python312 else "") + QUALIFY
    entries: list[dict[str, object]] = []
    commands: list[tuple[str, list[str]]] = []
    if "host" in targets:
        executables = args.rscript or [shutil.which("Rscript") or "Rscript"]
        for index, exe in enumerate(executables, 1):
            commands.append((f"host_r{index}", [exe, "--vanilla", "-e", expression]))
    for target in ["wsl", "docker"]:
        if target not in targets:
            continue
        try:
            command = (wsl_command(root, args.wsl_distribution, expression) if target == "wsl"
                else docker_command(root, args.docker_image or "", expression))
            commands.append((target, command))
        except (OSError, ValueError, subprocess.CalledProcessError) as err:
            diagnostic = str(err)
            if isinstance(err, subprocess.CalledProcessError) and err.output:
                diagnostic += ": " + (err.output.decode("utf-8", "replace") if isinstance(err.output, bytes) else err.output).strip()[:2000]
            entries.append({"target": target, "status": "BLOCKED_NOT_EXECUTED",
                "reason": diagnostic, "exit_code": None})
    for target, command in commands:
        log = out / (target + ".log")
        started = time.monotonic()
        env = dict(os.environ)
        env["ET_LOCAL_MATRIX_TARGET"] = target
        code = run_logged(command, root, log, env=env)
        content = log.read_text(encoding="utf-8", errors="replace")
        status, reason = interpret_log(content, code, sha, args.require_python312)
        item = {"target": target, "status": status, "reason": reason,
            "exit_code": code, "log": log.name,
            "log_sha256": hashlib.sha256(log.read_bytes()).hexdigest(),
            "duration_seconds": round(time.monotonic() - started, 2)}
        entries.append(item)
    audit = {"package": "eyetrajectories", "version": version,
        "git_head": sha, "timestamp_utc": stamp, "requested_targets": targets,
        "python312_required": args.require_python312, "results": entries,
        "publication": "NOT ATTEMPTED", "github_actions": "NOT EXECUTED",
        "macos": "NOT VERIFIED BY THIS RUNNER", "independent_508_certification": "NOT CLAIMED",
        "release_readiness": "HOLD: review platform coverage, NOTE(s), and publication version"}
    (out / "matrix_results.json").write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")
    with (out / "matrix_results.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["target", "status", "reason", "exit_code", "log", "log_sha256", "duration_seconds"])
        writer.writeheader()
        writer.writerows(entries)
    print("LOCAL_MATRIX_MANIFEST=" + str(out / "matrix_results.json"))
    for x in entries:
        print("LOCAL_MATRIX_RESULT=" + str(x["target"]) + ":" + str(x["status"]))
        if x["status"] == "BLOCKED_NOT_EXECUTED":
            print("LOCAL_MATRIX_BLOCKED_REASON=" + str(x["target"]) + ":" + str(x["reason"]).replace("\n", " ")[:1200])
    # Every requested target must have genuinely passed or passed-with-NOTEs.
    return 0 if entries and all(e["status"] in ("PASS", "PASS_WITH_NOTE_REVIEW") for e in entries) else 1


if __name__ == "__main__":
    raise SystemExit(main())
