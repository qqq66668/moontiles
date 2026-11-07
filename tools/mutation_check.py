#!/usr/bin/env python3
"""对关键判据做变异测试：把实现改错，确认测试会变红。

每处变异都在临时副本上执行，不修改工作区。若某处片段找不到，
记为存活变异（未通过），而不是通过。
"""
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKIP = {".git", "_build", "target", ".mooncakes", ".moonagent", "__pycache__"}

MUTATIONS = [
    ("tilemath/tilemath.mbt", "  1 << z", "  1 << (z + 1)", "tile count off by one level"),
    ("pmtiles/pmtiles.mbt", "read_byte(data, 0) == 0x50", "read_byte(data, 0) == 0x51", "wrong magic byte"),
    ("sqlite/record.mbt", "(serial_type - 12) / 2", "(serial_type - 12) / 3", "wrong blob length"),
    ("sqlite/table.mbt", "    let mut left = usable - 4", "    let mut left = usable - 5", "wrong overflow page payload size"),
]


def copy_project(dest: pathlib.Path) -> None:
    def ignore(_dir, names):
        return [n for n in names if n in SKIP]
    shutil.copytree(ROOT, dest, ignore=ignore)


def run_tests(workdir: pathlib.Path) -> int:
    proc = subprocess.run(
        ["moon", "test", "--target", "wasm-gc"],
        cwd=workdir,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return proc.returncode


def main() -> int:
    failures = []
    for rel, old, new, label in MUTATIONS:
        target = ROOT / rel
        text = target.read_text(encoding="utf-8")
        hits = text.count(old)
        if hits != 1:
            print(f"FAIL {rel}: fragment found {hits} times, expected 1 ({label})")
            failures.append(rel)
            continue
        with tempfile.TemporaryDirectory() as tmp:
            work = pathlib.Path(tmp) / "repo"
            copy_project(work)
            mutated = work / rel
            mutated.write_text(text.replace(old, new, 1), encoding="utf-8")
            code = run_tests(work)
            if code == 0:
                print(f"FAIL {rel}: tests stayed green after mutation ({label})")
                failures.append(rel)
            else:
                print(f"ok   {rel}: tests failed as expected ({label})")
    if failures:
        print(f"{len(failures)} mutation(s) survived")
        return 1
    print(f"all {len(MUTATIONS)} mutations were detected")
    return 0


if __name__ == "__main__":
    sys.exit(main())
