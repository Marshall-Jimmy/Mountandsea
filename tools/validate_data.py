#!/usr/bin/env python3
"""Validate project JSON data without third-party dependencies."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]


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
    record_label: str,
    required_fields: list[str],
    errors: list[str],
) -> None:
    if data is None:
        return

    if not isinstance(data, dict):
        errors.append(f"{relative_path}: top-level JSON value must be object")
        return

    if collection_key not in data:
        errors.append(f"{relative_path}: missing top-level field: {collection_key}")
        return

    records = data[collection_key]
    if not isinstance(records, list):
        errors.append(f"{relative_path}: field {collection_key} must be array")
        return

    seen_ids: set[str] = set()
    for index, record in enumerate(records):
        location = f"{record_label}[{index}]"
        if not isinstance(record, dict):
            errors.append(f"{relative_path}: {location} must be object")
            continue

        for field in required_fields:
            if field not in record:
                errors.append(f"{relative_path}: {location} missing required field: {field}")

        if record_label == "item" and "stack_size" in record:
            validate_stack_size(record["stack_size"], relative_path, location, errors)

        if "id" not in record:
            continue

        if not isinstance(record["id"], str):
            errors.append(f"{relative_path}: {location} field id must be non-empty string")
            continue

        record_id = record["id"]
        if record_id == "":
            errors.append(f"{relative_path}: {location} field id must be non-empty string")
            continue

        if record_id in seen_ids:
            errors.append(f"{relative_path}: duplicate {record_label} id: {record_id}")
            continue

        seen_ids.add(record_id)


def validate_stack_size(value: Any, relative_path: str, location: str, errors: list[str]) -> None:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        errors.append(f"{relative_path}: {location} field stack_size must be a positive integer")


def main() -> int:
    errors: list[str] = []

    items_path = "game/data/items/items.json"
    creatures_path = "game/data/creatures/creatures.json"

    items_data = load_json(items_path, errors)
    creatures_data = load_json(creatures_path, errors)

    validate_collection(items_data, items_path, "items", "item", ["id", "name", "type", "stack_size"], errors)
    validate_collection(creatures_data, creatures_path, "creatures", "creature", ["id", "name", "type"], errors)

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
