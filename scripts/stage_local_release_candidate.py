#!/usr/bin/env python3
"""Stage a candidate source tree at a proposed version; never tag or publish.

A candidate is a modified ARCHIVE of Git HEAD (not the qualified exact-head
source). Its actual build/check must be executed again before release review.
"""
from __future__ import annotations
import argparse
import datetime as dt
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def prepare(root: Path, out: Path, version: str) -> Path:
    if not re.fullmatch(r"0\.(?:[0-9]+)\.(?:[0-9]+)", version):
        raise ValueError("Candidate version must be an explicit three-component experimental 0.x.y version")
    if not (root / "DESCRIPTION").is_file() or not (root / "scripts/qualify_experimental_candidate.R").is_file():
        raise ValueError("Run from the eyetrajectories checkout root")
    if git(root, "status", "--porcelain", "--untracked-files=normal"):
        raise ValueError("Exact-head release staging requires a clean checkout")
    sha = git(root, "rev-parse", "HEAD")
    if not re.fullmatch("[0-9a-f]{40}", sha):
        raise ValueError("Missing exact HEAD")
    src = (root / "DESCRIPTION").read_text(encoding="utf-8")
    if not re.search(r"^Package:\s*eyetrajectories\s*$", src, re.M):
        raise ValueError("Not eyetrajectories")
    old_match = re.search(r"^Version:\s*(\S+)\s*$", src, re.M)
    if old_match is None:
        raise ValueError("Version missing")
    old = old_match.group(1)
    if version == old:
        raise ValueError("Candidate version must differ from development checkout")
    folder = out / ("eyetrajectories_" + version + "_from_" + sha[:12])
    package = folder / "eyetrajectories"
    if folder.exists():
        raise FileExistsError("Refusing to overwrite existing candidate " + str(folder))
    folder.mkdir(parents=True)
    data = subprocess.check_output(["git", "-C", str(root), "archive", "--format=tar", sha])
    try:
        with tarfile.open(fileobj=io.BytesIO(data), mode="r:") as archive:
            for member in archive.getmembers():
                # Never unpack paths/symlinks escaping the staging tree.
                p = Path(member.name)
                if p.is_absolute() or ".." in p.parts or member.issym() or member.islnk() or member.isdev():
                    raise ValueError("Unsafe git archive entry " + member.name)
            archive.extractall(package, filter="data")
        desc = package / "DESCRIPTION"
        desc.write_text(re.sub(r"^Version:[ \t]*[^\r\n]+$", "Version: " + version,
            desc.read_text(encoding="utf-8"), count=1, flags=re.M), encoding="utf-8")
        # Correct only stage documentation; leave research README/NEWS untouched.
        news = package / "NEWS.md"
        if news.exists():
            content = news.read_text(encoding="utf-8")
            news.write_text("# eyetrajectories " + version + " (candidate, not published)\n\n"
                + "Local source candidate derived from " + sha + ".\n"
                + "No 508-export parity or independent certification is asserted.\n\n"
                + content, encoding="utf-8")
        readme = package / "README.md"
        if readme.exists():
            content = readme.read_text(encoding="utf-8")
            content = content.replace("currently\n" + chr(96) + old + chr(96), "staged as release candidate\n" + chr(96) + version + chr(96) + " (not published)", 1)
            readme.write_text(content, encoding="utf-8")
        changes = {}
        for rel in ("DESCRIPTION", "NEWS.md", "README.md"):
            f = package / rel
            if f.is_file():
                changes[rel] = hashlib.sha256(f.read_bytes()).hexdigest()
        manifest = {"package": "eyetrajectories", "source_git_head": sha,
            "source_version": old, "candidate_version": version,
            "created_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "stage_dir": str(package), "modified_staged_files_sha256": changes,
            "candidate_check": "NOT EXECUTED", "candidate_release_status": "HOLD",
            "scope": "limited experimental R API; Python bridge optional",
            "macos": "NOT VERIFIED", "github_actions": "NOT VERIFIED",
            "python_contracts": "NOT INDEPENDENTLY CERTIFIED",
            "publish_tag_or_upload": "NEVER PERFORMED"}
        (folder / "STAGING_MANIFEST.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")
        (folder / "NEXT_STEPS.txt").write_text(
            "Candidate is NOT verified. From a local R environment with dependencies:\n"
            "  cd " + str(folder) + "\n"
            "  R CMD build eyetrajectories\n"
            "  R CMD check --as-cran eyetrajectories_" + version + ".tar.gz\n"
            "Review the output and all NOTEs, rerun the scientific suites against\n"
            "the candidate content, verify additional R/platform versions, and\n"
            "obtain maintainer approval BEFORE any tag, GitHub release or CRAN submission.\n",
            encoding="utf-8")
        return folder
    except Exception:
        shutil.rmtree(folder, ignore_errors=True)
        raise


def check_candidate(folder: Path, version: str, r_command: str) -> str:
    """Build and check the staged source TARBALL; never approve publication."""
    tar_name = "eyetrajectories_" + version + ".tar.gz"
    report = folder / "STAGED_R_CMD_CHECK.log"
    with report.open("w", encoding="utf-8", errors="replace") as output:
        for cmd in ([r_command, "CMD", "build", "eyetrajectories"],
                    [r_command, "CMD", "check", "--as-cran", tar_name]):
            output.write("COMMAND=" + repr(cmd) + "\n")
            output.flush()
            try:
                run = subprocess.run(cmd, cwd=folder, stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")
            except OSError as err:
                output.write("EXECUTION ERROR: " + str(err) + "\n")
                raise RuntimeError("R executable unavailable; check NOT completed") from err
            output.write(run.stdout + "\n")
            output.flush()
            if run.returncode:
                # Surface the actual R error in RStudio; retain full transcript.
                tail = "\n".join(run.stdout.splitlines()[-50:])
                print("STAGED_R_CHILD_FAILURE_PHASE=" + cmd[2], file=sys.stderr)
                print("STAGED_R_CHILD_EXIT_STATUS=" + str(run.returncode),
                      file=sys.stderr)
                print("STAGED_R_CHILD_OUTPUT_TAIL_BEGIN\n" + tail +
                      "\nSTAGED_R_CHILD_OUTPUT_TAIL_END", file=sys.stderr)
                raise RuntimeError("R CMD " + cmd[2] + " exited " +
                    str(run.returncode) + "; full log: " + str(report))
            if cmd[2] == "build" and not (folder / tar_name).is_file():
                raise RuntimeError("R CMD build did not create " + tar_name)
    log_path = folder / "eyetrajectories.Rcheck" / "00check.log"
    if not log_path.is_file():
        raise RuntimeError("R CMD check did not create 00check.log")
    lines = log_path.read_text(encoding="utf-8", errors="replace")
    statuses = re.findall(r"^Status:[ \t]*(.+?)\s*$", lines, re.M)
    if not statuses or "* DONE" not in lines:
        raise RuntimeError("Missing final R CMD check verdict")
    status = statuses[-1].strip()
    if "ERROR" in status or "WARNING" in status or (status != "OK" and not re.fullmatch(r"[0-9]+ NOTE(?:s)?", status)):
        raise RuntimeError("Candidate check is not clean: " + status)
    evidence = json.loads((folder / "STAGING_MANIFEST.json").read_text(encoding="utf-8"))
    evidence["candidate_check"] = "PASS_WITH_NOTE_REVIEW" if "NOTE" in status else "PASS"
    evidence["candidate_check_verdict"] = status
    evidence["candidate_check_log"] = str(report)
    evidence["candidate_check_tarball_sha256"] = hashlib.sha256((folder / tar_name).read_bytes()).hexdigest()
    evidence["candidate_release_status"] = "HOLD: platform and NOTE review required"
    (folder / "STAGING_MANIFEST.json").write_text(json.dumps(evidence,indent=2)+"\n", encoding="utf-8")
    return evidence["candidate_check"]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--version", default="0.4.2")
    parser.add_argument("--output-dir")
    parser.add_argument("--build-check", action="store_true", help="Run real R CMD build and --as-cran check on staged tarball")
    parser.add_argument("--r-command", default="R", help="R executable, or explicit path to R.exe on Windows")
    args = parser.parse_args(argv)
    root = Path(args.root).resolve()
    # Each default invocation gets a fresh isolated attempt; never overwrite
    # an earlier failed candidate or its diagnostic logs.
    dest = (Path(args.output_dir).resolve() if args.output_dir else
        root.parent / "eyetrajectories_release_staging" /
        dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ"))
    try:
        folder = prepare(root, dest, args.version)
    except Exception as err:
        print("STAGING_FAIL: " + str(err), file=sys.stderr)
        return 1
    print("STAGED_CANDIDATE_PATH=" + str(folder), flush=True)
    if args.build_check:
        try:
            outcome = check_candidate(folder, args.version, args.r_command)
            print("STAGED_CANDIDATE_R_CHECK=" + outcome)
        except Exception as err:
            print("STAGED_CANDIDATE_CHECK_FAIL: " + str(err), file=sys.stderr)
            return 1
    print("STAGED_UNVERIFIED_RELEASE_CANDIDATE=" + str(folder))
    print("NO TAG, MERGE, CRAN UPLOAD OR PUBLICATION WAS PERFORMED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
