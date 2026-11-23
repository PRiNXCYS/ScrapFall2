"""Run the Godot tests without a shell (AJAX's coding agent uses this; tools/test.sh does the same).

    python tools/test.py            every test (slow: 5-10 min, longer when the PC is busy)
    python tools/test.py traps      only tests/test_*.gd files whose name contains "traps"

Exit 0 only if at least one test ran, none failed and Godot printed no script or parse errors.
"""
import os
import re
import subprocess
import sys
from pathlib import Path

GODOT = os.environ.get("GODOT", "C:/Users/User/Tools/godot/Godot_v4.7.2-stable_win64_console.exe")
ROOT = Path(__file__).resolve().parent.parent
NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)


def main(argv: list[str]) -> int:
    only = argv[0] if argv else ""
    if only and not re.fullmatch(r"[\w-]+", only):
        print("Give a plain test name like 'traps' (matches tests/test_*traps*.gd).")
        return 2
    if not Path(GODOT).exists():
        print(f"Godot not found at {GODOT}")
        return 2
    subprocess.run([GODOT, "--headless", "--path", ".", "--import"], cwd=ROOT, capture_output=True,
                   creationflags=NO_WINDOW)
    env = dict(os.environ, TEST_ONLY=only)
    proc = subprocess.run([GODOT, "--headless", "--fixed-fps", "60", "--path", ".", "-s", "res://tests/run_tests.gd"],
                          cwd=ROOT, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace",
                          creationflags=NO_WINDOW)
    out = (proc.stdout or "") + (proc.stderr or "")
    lines = out.splitlines()
    # errors and their "at: res://..." location; Godot's exit-time leak notices are left out
    keep = re.compile(r"^(PASS|FAIL)|passed|SCRIPT ERROR|Parse Error|at: res://|\.gd:\d+")
    shown = [l for l in lines if keep.search(l)]
    # passing lines are noise for a long run; keep failures, errors and the summary
    if len(shown) > 60:
        shown = [l for l in shown if not l.startswith("PASS")]
    print("\n".join(shown))
    ran = sum(1 for l in lines if l.startswith(("PASS", "FAIL")))
    if ran == 0:
        print(f"No tests ran (filter '{only}' matched no tests/test_*.gd file?)." if only else "No tests ran.")
        return 1
    if any("SCRIPT ERROR" in l or "Parse Error" in l for l in lines):
        print("script errors were printed: treating as failure")
        return 1
    return proc.returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
