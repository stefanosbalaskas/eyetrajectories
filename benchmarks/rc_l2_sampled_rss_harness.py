#!/usr/bin/env python3
"""Benchmark exact installed v0.4.3 versus v0.4.3.9000 on matched RDS.

Poll each R process with psutil. Report sampled peak RSS rather than an
unmeasured kernel high-water mark. No raw gaze data or Python algorithms.
"""
from __future__ import annotations
import argparse
import csv
from hashlib import sha256
import json
import platform
from pathlib import Path
import statistics
import subprocess
import sys
import time

import psutil


def get_args():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--baseline-library",required=True,type=Path)
    p.add_argument("--candidate-library",required=True,type=Path)
    p.add_argument("--inputs",required=True,type=Path)
    p.add_argument("--work",required=True,type=Path)
    p.add_argument("--runner",required=True,type=Path)
    p.add_argument("--repetitions",type=int,default=2)
    p.add_argument("--data-source",choices=("synthetic","real_onestop_fixation"),
                   default="synthetic")
    return p.parse_args()


def execute(run_script,lib,version,source,out):
    argv=["Rscript",str(run_script),str(lib),version,str(source),str(out)]
    proc=subprocess.Popen(argv,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                          text=True,errors="replace")
    sample_peak=0
    samples=0
    begin=time.perf_counter()
    while proc.poll() is None:
        try:
            root=psutil.Process(proc.pid)
            # Windows Rscript.exe can be a small launcher whose R interpreter
            # runs in a child process; measuring only the launcher would
            # falsely report a nearly fixed ~7 MB for every dataset.
            processes=[root]+root.children(recursive=True)
            rss=sum(p.memory_info().rss for p in processes if p.is_running())
            sample_peak=max(sample_peak,rss)
            samples+=1
        except (psutil.NoSuchProcess,psutil.AccessDenied,psutil.ZombieProcess):
            pass
        if time.perf_counter()-begin>600:
            proc.kill()
            raise RuntimeError(f"Isolated benchmark timeout: {source.name}, {version}")
        time.sleep(.035)
    stdout,stderr=proc.communicate()
    wall=time.perf_counter()-begin
    if proc.returncode:
        raise RuntimeError(f"Isolated R benchmark failed: {source.name}, "
                           f"{version}, exit={proc.returncode}\n{stdout[-2000:]}\n"
                           f"{stderr[-3000:]}")
    results=Path(str(out)+".csv")
    with results.open(encoding="utf-8-sig",newline="") as handle:
        records=list(csv.DictReader(handle))
    if len(records)!=1 or records[0]["version"]!=version:
        raise AssertionError(f"Installed version mismatch or invalid R result: {results}")
    return {
      "package_version":version,
      "n_curves":int(records[0]["n_curves"]),
      "grid_points":int(records[0]["grid_points"]),
      "channels":int(records[0]["channels"]),
      "r_elapsed_seconds":float(records[0]["elapsed_seconds"]),
      "process_wall_seconds":wall,
      "sampled_peak_process_rss_bytes":sample_peak,
      "rss_sample_count":samples,
      "input_sha256":sha256(source.read_bytes()).hexdigest(),
    }


def main():
    a=get_args()
    if not 1<=a.repetitions<=5:
        raise ValueError("repetitions must be 1..5")
    root=a.work.resolve()
    root.mkdir(parents=True,exist_ok=True)
    lib={"baseline":a.baseline_library.resolve(strict=True),
         "candidate":a.candidate_library.resolve(strict=True)}
    versions={"baseline":"0.4.3","candidate":"0.4.3.9000"}
    runner=a.runner.resolve(strict=True)
    case_path=a.inputs/"benchmark_cases.csv"
    if not case_path.exists():
        case_path=a.inputs/"synthetic_cases.csv"
    cases=list(csv.DictReader(case_path.open(newline="")))
    if len(cases)!=6:
        raise AssertionError("Exactly six pre-registered combinations required")
    allrows=[]
    for case in cases:
        n=int(case["n_curves"]);g=int(case["grid_points"])
        source=(a.inputs/f"n{n:04d}_g{g:03d}.rds").resolve(strict=True)
        for rep in range(1,a.repetitions+1):
            order=("baseline","candidate") if rep%2 else ("candidate","baseline")
            for mode in order:
                prefix=root/"matrices"/f"n{n:04d}_g{g:03d}_rep{rep}_{mode}"
                one=execute(runner,lib[mode],versions[mode],source,prefix)
                one.update({"mode":mode,"repeat":rep,"input_file":source.name,
                            "result_prefix":prefix.name})
                allrows.append(one)
                print("L2_INSTALLED_BENCHMARK_ROW",n,g,rep,mode,
                      f"{one['r_elapsed_seconds']:.5f}",
                      "sampled_rss",one["sampled_peak_process_rss_bytes"],
                      flush=True)
    header=list(allrows[0])
    with (root/"raw_benchmark_runs.csv").open("w",encoding="utf-8",newline="") as fh:
        w=csv.DictWriter(fh,fieldnames=header);w.writeheader();w.writerows(allrows)

    output=[]
    for case in cases:
        n=int(case["n_curves"]);g=int(case["grid_points"])
        rows=[r for r in allrows if r["n_curves"]==n and r["grid_points"]==g]
        b=[r for r in rows if r["mode"]=="baseline"]
        c=[r for r in rows if r["mode"]=="candidate"]
        bt=statistics.median(r["r_elapsed_seconds"] for r in b)
        ct=statistics.median(r["r_elapsed_seconds"] for r in c)
        if bt<=0 or ct<=0:
            raise ValueError("Elapsed timings must be positive")
        output.append({
            "n_curves":n,"grid_points":g,"channels":2,
            "baseline_median_r_elapsed_s":bt,
            "candidate_median_r_elapsed_s":ct,
            "median_speedup_ratio":bt/ct,
            "baseline_max_sampled_rss_bytes":max(r["sampled_peak_process_rss_bytes"] for r in b),
            "candidate_max_sampled_rss_bytes":max(r["sampled_peak_process_rss_bytes"] for r in c),
            "repetitions_per_version":a.repetitions,
        })
    with (root/"performance_summary.csv").open("w",encoding="utf-8",newline="") as fh:
        w=csv.DictWriter(fh,fieldnames=list(output[0]));w.writeheader();w.writerows(output)
    metadata={
      "schema":"eyetrajectories-exact-installed-l2-benchmark/v1",
      "baseline":"v0.4.3, immutable source",
      "candidate":"v0.4.3-derived development v0.4.3.9000",
      "data":("entirely synthetic, nonhuman, deterministic within this R/OS"
              if a.data_source=="synthetic" else
              "published OneStop repeated-reading fixation-level data; 0-1 time and declared interpolation"),
      "data_source":a.data_source,
      "python_role":"process harness and sampled RSS monitoring only; no estimator in Python",
      "peak_memory":"maximum sampled R launcher+descendant process-tree RSS approximately every 35 ms; not true kernel HWM or peak allocation",
      "repetitions_per_version":a.repetitions,
      "platform":platform.platform(),
      "python":sys.version,
      "psutil":psutil.__version__,
      "rss_aggregation":"sampled sum of active Rscript launcher and child R process RSS; may transiently miss short processes",
      "hardware_is_runner_specific":True,
      "not_a_real_onestop_benchmark":a.data_source!="real_onestop_fixation",
      "source_archive_provenance_file":str(a.inputs/"source_provenance.csv")
              if (a.inputs/"source_provenance.csv").exists() else None,
      "results":output,
    }
    (root/"benchmark_metadata.json").write_text(
      json.dumps(metadata,indent=2)+"\n",encoding="utf-8")
    if any(r["median_speedup_ratio"]<1.0 for r in output):
        print("WARNING: candidate not faster in at least one configuration")
    print("EXACT_INSTALLED_L2_"+a.data_source.upper()+"_SCALING_MEASURED",
          len(output),"cases, independently timed + sampled process RSS")


if __name__=="__main__":
    main()
