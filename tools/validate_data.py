#!/usr/bin/env python3
"""Validate project JSON data without third-party dependencies."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]


def display_path(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def load_json(relative_path: str, errors: list[str]) -> Any:
    path = ROOT / relative_path
    try:
        with path.open("r", encoding="utf-8") as file:
            return json.load(file)
    except FileNotFoundError:
        errors.append(f"{relative_path}: file not found")
    except json.JSONDecodeError as exc:
        errors.append(f"{relative_path}: JSON parse error at line {exc.lineno}, column {exc.colno}: {exc.msg}")
    except OSError as exc:
        errors.append(f"{relative_path}: failed to read file: {exc}")
    return None


def validate_collection(
    data: Any,
    relative_path: str,
    collection_key: str,
    required_fields: list[str],
    errors: list[str],
) -> None:
    if data is None:
        return

    if not isinstance(data, dict):
        errors.append(f"{relative_path}: root: expected object")
        return

    if collection_key not in data:
        errors.append(f"{relative_path}: field={collection_key}: missing required top-level field")
        return

    records = data[collection_key]
    if not isinstance(records, list):
        errors.append(f"{relative_path}: field={collection_key}: expected array")
        return

    seen_ids: set[str] = set()
    for index, record in enumerate(records):
        location = f"{collection_key}[{index}]"
        if not isinstance(record, dict):
            errors.append(f"{relative_path}: {location}: expected object")
            continue

        record_id = record.get("id", "<missing>")
        for field in required_fields:
            if field not in record:
                errors.append(
                    f"{relative_path}: {location}: id={record_id}: field={field}: missing required field"
                )

        if "id" not in record:
            continue

        if not isinstance(record["id"], str):
            errors.append(f"{relative_path}: {location}: field=id: expected string")
            continue

        record_id = record["id"]
        if record_id == "":
            errors.append(f"{relative_path}: {location}: field=id: must not be empty")
            continue

        if record_id in seen_ids:
            errors.append(f"{relative_path}: {location}: id={record_id}: duplicate id")
            continue

        seen_ids.add(record_id)


def main() -> int:
    errors: list[str] = []

    items_path = "game/data/items/items.json"
    creatures_path = "game/data/creatures/creatures.json"

    items_data = load_json(items_path, errors)
    creatures_data = load_json(creatures_path, errors)

    validate_collection(items_data, items_path, "items", ["id", "name", "type", "stack_size"], errors)
    validate_collection(creatures_data, creatures_path, "creatures", ["id", "name", "type"], errors)

    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print("validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
