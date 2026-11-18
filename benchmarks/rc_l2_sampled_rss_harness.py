#!/usr/bin/env python3
"""Benchmark exact installed v0.4.3 versus v0.4.3.9000 with matched synthetic RDS.

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
            rss=psutil.Process(proc.pid).memory_info().rss
            sample_peak=max(sample_peak,rss)
            samples+=1
        except (psutil.NoSuchProcess,psutil.AccessDenied):
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
    cases=list(csv.DictReader((a.inputs/"synthetic_cases.csv").open(newline="")))
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
      "data":"entirely synthetic, nonhuman, deterministic within this R/OS",
      "python_role":"process harness and sampled RSS monitoring only; no estimator in Python",
      "peak_memory":"maximum sampled process RSS every approximately 35 ms; not true kernel HWM or peak allocation",
      "repetitions_per_version":a.repetitions,
      "platform":platform.platform(),
      "python":sys.version,
      "psutil":psutil.__version__,
      "hardware_is_runner_specific":True,
      "not_a_real_onestop_benchmark":True,
      "results":output,
    }
    (root/"benchmark_metadata.json").write_text(
      json.dumps(metadata,indent=2)+"\n",encoding="utf-8")
    if any(r["median_speedup_ratio"]<1.0 for r in output):
        print("WARNING: candidate not faster in at least one configuration")
    print("EXACT_INSTALLED_L2_SYNTHETIC_SCALING_MEASURED",len(output),
          "cases, independently timed + sampled process RSS")


if __name__=="__main__":
    main()
