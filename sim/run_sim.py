#!/usr/bin/env python3
"""
Automated Verification Suite Runner for 5-Stage RV32I Processor
Compiles with iverilog and executes all self-checking testbenches.
"""

import os
import sys
import subprocess
import time

TESTS = [
    ("basic_tests.hex",   "Arithmetic, Logic, Shift, Immediate, LUI & AUIPC"),
    ("hazard_tests.hex",  "EX/MEM RAW Forwarding & Load-Use Hazard Stalling"),
    ("branch_tests.hex",  "Control Hazards, Branch Flush Validation & JAL/JALR"),
    ("fibonacci.hex",     "Fibonacci Iterative Benchmark (12 Memory Verifications)")
]

def run_command(cmd, desc):
    print(f"\n[EXEC] {desc}")
    print(f"       Command: {cmd}")
    start = time.time()
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    elapsed = time.time() - start
    return res.returncode, res.stdout, res.stderr, elapsed

def main():
    print("=" * 70)
    print("  5-STAGE PIPELINED RV32I PROCESSOR - AUTOMATED TEST SUITE RUNNER")
    print("=" * 70)

    # 1. Compile SystemVerilog Testbench
    compile_cmd = (
        "iverilog -g2012 "
        "-Irtl/pkg -Irtl/core -Irtl/memory -Itb/assertions "
        "-o sim/sim_rv32i tb/tb_rv32i_core.sv"
    )
    code, stdout, stderr, elapsed = run_command(compile_cmd, "Compiling SystemVerilog RTL & Testbench")
    if code != 0:
        print(f"[ERROR] Compilation Failed!\n{stderr}")
        sys.exit(1)
    print(f"[OK] Compiled successfully in {elapsed:.2f}s")

    results = []

    # 2. Run Test Suites
    for hex_file, description in TESTS:
        hex_path = os.path.join("tests", "hex", hex_file)
        sim_cmd = f"vvp sim/sim_rv32i +HEX={hex_path}"
        code, stdout, stderr, elapsed = run_command(sim_cmd, f"Running Test: {hex_file} ({description})")

        # Parse test outcomes
        passed = "ALL TESTS PASSED SUCCESSFULLY" in stdout
        checks_pass = 0
        checks_fail = 0
        cpi = "N/A"
        cycles = "N/A"

        for line in stdout.splitlines():
            if "Passed              :" in line:
                checks_pass = int(line.split(":")[-1].strip())
            elif "Failed              :" in line:
                checks_fail = int(line.split(":")[-1].strip())
            elif "Measured CPI        :" in line:
                cpi = line.split(":")[-1].strip()
            elif "Cycles Elapsed      :" in line:
                cycles = line.split(":")[-1].strip()

        status_str = "PASSED" if (passed and checks_fail == 0) else "FAILED"
        results.append({
            "test": hex_file,
            "desc": description,
            "status": status_str,
            "passed": checks_pass,
            "failed": checks_fail,
            "cycles": cycles,
            "cpi": cpi,
            "time": elapsed
        })

        # Print individual check items
        for line in stdout.splitlines():
            if "[PASS]" in line or "[FAIL]" in line or "HAZARD:" in line or "CONTROL:" in line:
                print(f"   {line.strip()}")

    # 3. Print Executive Summary Table
    print("\n" + "=" * 80)
    print("                         EXECUTIVE VERIFICATION SUMMARY")
    print("=" * 80)
    print(f"{'Test Suite':<20} | {'Status':<8} | {'Passed':<6} | {'Failed':<6} | {'Cycles':<7} | {'CPI':<6} | {'Time (s)'}")
    print("-" * 80)
    all_passed = True
    for r in results:
        if r["status"] != "PASSED":
            all_passed = False
        print(f"{r['test']:<20} | {r['status']:<8} | {r['passed']:<6} | {r['failed']:<6} | {r['cycles']:<7} | {r['cpi']:<6} | {r['time']:.2f}")
    print("=" * 80)

    if all_passed:
        print("\n>>> OVERALL RESULT: 100% OF TESTS PASSED! PROCESSOR HARDWARE VERIFIED! <<<\n")
        sys.exit(0)
    else:
        print("\n>>> OVERALL RESULT: SOME VERIFICATIONS FAILED! <<<\n")
        sys.exit(1)

if __name__ == '__main__':
    main()
