#!/usr/bin/env python3
"""Run local validation for the minimal playable demo."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path


FRAMEWORK_KEYWORDS = [
    "zhuyu",
    "shensheng",
    "zaoyaoshan",
    "\u795d\u4f59",
    "\u72cc\u72cc",
    "\u62db\u6447\u5c71",
]


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def format_command(args: list[str]) -> str:
    return subprocess.list2cmdline(args)


def run_command(label: str, args: list[str], cwd: Path) -> bool:
    print(f"[RUN] {label}", flush=True)
    print(f"      {format_command(args)}", flush=True)

    try:
        result = subprocess.run(args, cwd=cwd)
    except FileNotFoundError as exc:
        print(f"[FAIL] {label} failed to start: {exc}", file=sys.stderr, flush=True)
        return False
    except OSError as exc:
        print(f"[FAIL] {label} failed to run: {exc}", file=sys.stderr, flush=True)
        return False

    if result.returncode != 0:
        print(f"[FAIL] {label} exited with code {result.returncode}", file=sys.stderr, flush=True)
        return False

    print(f"[OK] {label}", flush=True)
    return True


def find_godot() -> tuple[str | None, bool]:
    configured = os.environ.get("GODOT_BIN")
    if configured is not None:
        configured = configured.strip().strip("\"'")
        if configured == "":
            print("[FAIL] GODOT_BIN is set but empty", file=sys.stderr)
            return None, True

        resolved = shutil.which(configured)
        if resolved is None:
            configured_path = Path(configured).expanduser()
            if configured_path.is_file():
                resolved = str(configured_path)

        if resolved is None:
            print(
                f"[FAIL] GODOT_BIN is set but executable was not found: {configured}",
                file=sys.stderr,
            )
            return None, True

        if not os.access(resolved, os.X_OK):
            print(
                f"[FAIL] GODOT_BIN is set but is not executable: {resolved}",
                file=sys.stderr,
            )
            return None, True

        return resolved, False

    for candidate in ("godot", "godot4", "godot.exe"):
        resolved = shutil.which(candidate)
        if resolved is not None:
            return resolved, False

    return None, False


def scan_framework_keywords(root: Path) -> bool:
    label = "framework keyword scan"
    repo = repo_root()

    if not root.is_dir():
        print(f"[FAIL] {label}: directory not found: {root}", file=sys.stderr)
        return False

    matches: list[tuple[Path, str, int]] = []
    for file_path in sorted(root.rglob("*")):
        if not file_path.is_file():
            continue

        try:
            content = file_path.read_bytes()
        except OSError:
            continue

        if b"\0" in content:
            continue

        try:
            text = content.decode("utf-8")
        except UnicodeDecodeError:
            continue

        for line_number, line in enumerate(text.splitlines(), start=1):
            for keyword in FRAMEWORK_KEYWORDS:
                if keyword in line:
                    matches.append((file_path, keyword, line_number))

    if matches:
        for file_path, keyword, line_number in matches:
            relative_path = file_path.relative_to(repo)
            print(
                f"[FAIL] {label}: {relative_path}: line {line_number}: found {keyword}",
                file=sys.stderr,
            )
        return False

    print(f"[OK] {label} passed")
    return True


def main() -> int:
    root = repo_root()
    success = True

    success &= run_command(
        "data validation",
        [sys.executable, "tools/validate_data.py"],
        root,
    )
    success &= run_command(
        "framework check",
        [sys.executable, "tools/check_framework.py"],
        root,
    )

    godot, godot_lookup_failed = find_godot()
    godot_missing = godot is None and not godot_lookup_failed
    if godot_missing:
        print("[SKIP] Godot checks: executable not found")
    elif godot is not None:
        success &= run_command(
            "Godot import",
            [godot, "--headless", "--path", "game", "--import"],
            root,
        )
        success &= run_command(
            "demo script check-only",
            [
                godot,
                "--headless",
                "--path",
                "game",
                "--check-only",
                "--script",
                "res://scenes/demo/minimal_playable_demo.gd",
            ],
            root,
        )
        success &= run_command(
            "demo save/load regression",
            [
                godot,
                "--headless",
                "--path",
                "game",
                "--script",
                "res://tests/minimal_playable_demo/minimal_playable_demo_save_load_regression.gd",
            ],
            root,
        )
    else:
        success = False

    success &= scan_framework_keywords(root / "game" / "addons" / "snowhuman_framework")

    if godot_missing:
        print("[FAIL] minimal demo validation incomplete: Godot CLI not found")
        return 1

    if success:
        print("[OK] minimal demo validation passed")
        return 0

    print("[FAIL] minimal demo validation failed")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
