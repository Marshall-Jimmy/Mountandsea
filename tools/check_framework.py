#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Snowhuman Framework 基础验证脚本。

从仓库根目录运行：

    python tools/check_framework.py

检查内容：
1. Snowhuman Framework 目录存在
2. 旧 addon 名称无残留
3. Framework 内无项目专属内容
4. 关键文件存在
5. plugin.gd 路径正确
6. Framework README 包含中文
7. RFC 文件包含中文
"""

import re
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent

FRAMEWORK_DIR = REPO_ROOT / "game" / "addons" / "snowhuman_framework"

OLD_ADDON_NAMES = [
    "mo_game_core",
    "Mo Game Core",
    "res://addons/mo_game_core",
    "game/addons/mo_game_core",
]

OLD_ADDON_SCAN_DIRS = [
    REPO_ROOT / "game",
    REPO_ROOT / "docs",
    REPO_ROOT / "rfcs",
]

PROJECT_SPECIFIC_KEYWORDS = [
    "zhuyu",
    "shensheng",
    "zaoyaoshan",
    "祝余",
    "狌狌",
    "招摇山",
]

REQUIRED_FILES = [
    "game/addons/snowhuman_framework/plugin.cfg",
    "game/addons/snowhuman_framework/plugin.gd",
    "game/addons/snowhuman_framework/README.md",
    "game/addons/snowhuman_framework/autoload/game_core.gd",
    "game/addons/snowhuman_framework/autoload/data_registry.gd",
    "game/addons/snowhuman_framework/autoload/event_bus.gd",
    "game/addons/snowhuman_framework/autoload/save_service.gd",
    "game/addons/snowhuman_framework/systems/inventory_service.gd",
    "rfcs/0001-data-registry.md",
    "rfcs/0002-inventory-service.md",
    "rfcs/0003-save-service.md",
    "tools/validate_data.py",
]

PLUGIN_GD_PATH = "game/addons/snowhuman_framework/plugin.gd"
PLUGIN_GD_MUST_CONTAIN = "res://addons/snowhuman_framework/"
PLUGIN_GD_MUST_NOT_CONTAIN = "res://addons/mo_game_core/"

FRAMEWORK_README_PATH = "game/addons/snowhuman_framework/README.md"

RFC_FILES = [
    "rfcs/0001-data-registry.md",
    "rfcs/0002-inventory-service.md",
    "rfcs/0003-save-service.md",
]

CHINESE_CHAR_RE = re.compile(r"[\u4e00-\u9fff]")


def collect_errors():
    """运行全部检查，收集所有错误后返回。"""
    errors = []

    # 1. 检查 Snowhuman Framework 目录存在
    if not FRAMEWORK_DIR.is_dir():
        errors.append(
            f"目录不存在: {FRAMEWORK_DIR.relative_to(REPO_ROOT)}"
        )

    # 2. 检查旧 addon 名称没有残留
    for scan_dir in OLD_ADDON_SCAN_DIRS:
        if not scan_dir.exists():
            continue
        for file_path in scan_dir.rglob("*"):
            if not file_path.is_file():
                continue
            if ".git" in file_path.parts:
                continue
            try:
                text = file_path.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            for old_name in OLD_ADDON_NAMES:
                if old_name in text:
                    rel = file_path.relative_to(REPO_ROOT)
                    errors.append(
                        f"旧 addon 名称残留: '{old_name}' 出现在 {rel}"
                    )

    # 3. 检查 framework 内没有项目专属内容
    if FRAMEWORK_DIR.is_dir():
        for file_path in FRAMEWORK_DIR.rglob("*"):
            if not file_path.is_file():
                continue
            try:
                text = file_path.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            for keyword in PROJECT_SPECIFIC_KEYWORDS:
                if keyword in text:
                    rel = file_path.relative_to(REPO_ROOT)
                    errors.append(
                        f"Framework 内出现项目专属内容: '{keyword}' 出现在 {rel}"
                    )

    # 4. 检查关键文件存在
    for rel_path in REQUIRED_FILES:
        abs_path = REPO_ROOT / rel_path
        if not abs_path.exists():
            errors.append(f"关键文件缺失: {rel_path}")

    # 5. 检查 plugin.gd 路径
    plugin_gd = REPO_ROOT / PLUGIN_GD_PATH
    if plugin_gd.exists():
        try:
            content = plugin_gd.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            content = ""
        if PLUGIN_GD_MUST_CONTAIN not in content:
            errors.append(
                f"{PLUGIN_GD_PATH} 缺少 '{PLUGIN_GD_MUST_CONTAIN}'"
            )
        if PLUGIN_GD_MUST_NOT_CONTAIN in content:
            errors.append(
                f"{PLUGIN_GD_PATH} 仍包含旧路径 '{PLUGIN_GD_MUST_NOT_CONTAIN}'"
            )

    # 6. 检查 README 有中文内容
    readme_path = REPO_ROOT / FRAMEWORK_README_PATH
    if readme_path.exists():
        try:
            readme_text = readme_path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            readme_text = ""
        if not CHINESE_CHAR_RE.search(readme_text):
            errors.append(
                f"{FRAMEWORK_README_PATH} 未包含任何中文字符"
            )

    # 7. 检查 RFC 有中文内容
    for rfc_rel in RFC_FILES:
        rfc_path = REPO_ROOT / rfc_rel
        if rfc_path.exists():
            try:
                rfc_text = rfc_path.read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                rfc_text = ""
            if not CHINESE_CHAR_RE.search(rfc_text):
                errors.append(
                    f"{rfc_rel} 未包含任何中文字符"
                )

    return errors


def main():
    errors = collect_errors()

    if errors:
        for err in errors:
            print(f"  [FAIL] {err}", file=sys.stderr)
        print(f"\n框架检查失败: {len(errors)} 个问题", file=sys.stderr)
        sys.exit(1)

    print("framework checks passed")
    sys.exit(0)


if __name__ == "__main__":
    main()
