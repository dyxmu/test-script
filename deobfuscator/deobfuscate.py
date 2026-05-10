#!/usr/bin/env python3
"""
WeAreDevs/Prometheus Lua Deobfuscator
======================================
Deobfuscates scripts protected by the WeAreDevs/Prometheus obfuscator.

Usage:
    python3 deobfuscate.py <obfuscated.lua> [output.lua]

Requirements:
    - lua5.1 (apt install lua5.1)
    - Python 3.6+
"""

import subprocess
import sys
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TRACER_PATH = os.path.join(SCRIPT_DIR, "full_tracer.lua")


def run_deobfuscator(input_file, output_file=None):
    """Run the Lua deobfuscator on an input file"""
    if not os.path.exists(input_file):
        print(f"Error: {input_file} not found", file=sys.stderr)
        return 1

    if not os.path.exists(TRACER_PATH):
        print(f"Error: {TRACER_PATH} not found", file=sys.stderr)
        return 1

    # Build command
    cmd = ["lua5.1", TRACER_PATH, input_file]
    if output_file:
        cmd.append(output_file)

    # Run with timeout
    try:
        result = subprocess.run(
            cmd,
            timeout=120,
            capture_output=True,
            text=True
        )
        if result.stdout:
            print(result.stdout, end='')
        if result.stderr:
            print(result.stderr, end='', file=sys.stderr)
        return result.returncode
    except subprocess.TimeoutExpired:
        print("Error: execution timed out (120s)", file=sys.stderr)
        return 1
    except FileNotFoundError:
        print("Error: lua5.1 not found. Install with: apt install lua5.1", file=sys.stderr)
        return 1


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    sys.exit(run_deobfuscator(input_file, output_file))


if __name__ == '__main__':
    main()
