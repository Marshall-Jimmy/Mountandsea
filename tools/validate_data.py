#!/usr/bin/env python3
"""Validate project JSON data without third-party dependencies."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
GAME_ROOT = ROOT / "game"

WORLD_MAP_PATH = "game/data/world/world_map.json"
SPAWN_RULES_PATH = "game/data/world/spawn_rules.json"
RESOURCE_RULES_PATH = "game/data/world/resource_rules.json"
ENCOUNTER_RULES_PATH = "game/data/world/encounter_rules.json"


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


def validate_world_data(errors: list[str]) -> None:
    world_map = load_json(WORLD_MAP_PATH, errors)
    if not isinstance(world_map, dict):
        if world_map is not None:
            errors.append(f"{WORLD_MAP_PATH}: top-level JSON value must be object")
        return

    validate_positive_version(world_map.get("version"), WORLD_MAP_PATH, "world map", errors)
    default_seed = world_map.get("default_seed")
    if isinstance(default_seed, bool) or not isinstance(default_seed, int):
        errors.append(f"{WORLD_MAP_PATH}: default_seed must be an integer")

    region_references = world_map.get("regions")
    if not isinstance(region_references, list) or not region_references:
        errors.append(f"{WORLD_MAP_PATH}: regions must be a non-empty array")
        return

    region_data_by_id: dict[str, dict[str, Any]] = {}
    mountains_by_region: dict[str, dict[str, dict[str, Any]]] = {}
    seen_region_ids: set[str] = set()
    for index, reference in enumerate(region_references):
        location = f"regions[{index}]"
        if not isinstance(reference, dict):
            errors.append(f"{WORLD_MAP_PATH}: {location} must be object")
            continue

        require_non_empty_strings(
            reference,
            ["id", "name", "display_name", "region_file"],
            WORLD_MAP_PATH,
            location,
            errors,
        )
        if not isinstance(reference.get("mvp"), bool):
            errors.append(f"{WORLD_MAP_PATH}: {location} field mvp must be boolean")

        region_id = reference.get("id")
        if not isinstance(region_id, str) or not region_id:
            continue
        if region_id in seen_region_ids:
            errors.append(f"{WORLD_MAP_PATH}: duplicate region id: {region_id}")
            continue
        seen_region_ids.add(region_id)

        region_relative_path = res_path_to_relative(reference.get("region_file"), WORLD_MAP_PATH, location, errors)
        if region_relative_path is None:
            continue
        region_data = load_json(region_relative_path, errors)
        if not isinstance(region_data, dict):
            if region_data is not None:
                errors.append(f"{region_relative_path}: top-level JSON value must be object")
            continue

        region_data_by_id[region_id] = region_data
        mountains_by_region[region_id] = validate_region_data(
            region_data,
            region_relative_path,
            region_id,
            errors,
        )

    starting_regions = world_map.get("starting_regions")
    if not isinstance(starting_regions, list) or not starting_regions:
        errors.append(f"{WORLD_MAP_PATH}: starting_regions must be a non-empty array")
    else:
        for index, region_id in enumerate(starting_regions):
            if not isinstance(region_id, str) or not region_id:
                errors.append(
                    f"{WORLD_MAP_PATH}: starting_regions[{index}] must be a non-empty string"
                )
            elif region_id not in region_data_by_id:
                errors.append(
                    f"{WORLD_MAP_PATH}: starting_regions[{index}] references unknown region: {region_id}"
                )

    spawn_rules = validate_world_rules(
        load_json(SPAWN_RULES_PATH, errors),
        SPAWN_RULES_PATH,
        "spawn_id",
        requires_count_range=False,
        errors=errors,
    )
    resource_rules = validate_world_rules(
        load_json(RESOURCE_RULES_PATH, errors),
        RESOURCE_RULES_PATH,
        "resource_id",
        requires_count_range=True,
        errors=errors,
    )
    encounter_rules = validate_world_rules(
        load_json(ENCOUNTER_RULES_PATH, errors),
        ENCOUNTER_RULES_PATH,
        "creature_id",
        requires_count_range=True,
        errors=errors,
    )

    validate_rule_references(spawn_rules, SPAWN_RULES_PATH, "spawn_id", mountains_by_region, None, errors)
    validate_rule_references(
        resource_rules,
        RESOURCE_RULES_PATH,
        "resource_id",
        mountains_by_region,
        "resources",
        errors,
    )
    validate_rule_references(
        encounter_rules,
        ENCOUNTER_RULES_PATH,
        "creature_id",
        mountains_by_region,
        "creatures",
        errors,
    )


def validate_region_data(
    data: dict[str, Any],
    relative_path: str,
    expected_region_id: str,
    errors: list[str],
) -> dict[str, dict[str, Any]]:
    validate_positive_version(data.get("version"), relative_path, "region", errors)
    require_non_empty_strings(data, ["id", "name"], relative_path, "region", errors)
    if data.get("id") != expected_region_id:
        errors.append(
            f"{relative_path}: region id {data.get('id')!r} does not match world map id {expected_region_id!r}"
        )

    mountains = data.get("mvp_mountains")
    if not isinstance(mountains, list) or not mountains:
        errors.append(f"{relative_path}: mvp_mountains must be a non-empty array")
        return {}

    result: dict[str, dict[str, Any]] = {}
    for index, mountain in enumerate(mountains):
        location = f"mvp_mountains[{index}]"
        if not isinstance(mountain, dict):
            errors.append(f"{relative_path}: {location} must be object")
            continue

        require_non_empty_strings(mountain, ["id", "name"], relative_path, location, errors)
        for field in ("biomes", "resources", "creatures"):
            validate_non_empty_string_array(mountain.get(field), relative_path, f"{location}.{field}", errors)
        validate_non_negative_number(
            mountain.get("spawn_weight"),
            relative_path,
            f"{location}.spawn_weight",
            errors,
        )

        mountain_id = mountain.get("id")
        if not isinstance(mountain_id, str) or not mountain_id:
            continue
        if mountain_id in result:
            errors.append(f"{relative_path}: duplicate mountain id: {mountain_id}")
            continue
        result[mountain_id] = mountain
    return result


def validate_world_rules(
    data: Any,
    relative_path: str,
    id_field: str,
    requires_count_range: bool,
    errors: list[str],
) -> list[dict[str, Any]]:
    if data is None:
        return []
    if not isinstance(data, dict):
        errors.append(f"{relative_path}: top-level JSON value must be object")
        return []

    validate_positive_version(data.get("version"), relative_path, "rules", errors)
    rules = data.get("rules")
    if not isinstance(rules, list) or not rules:
        errors.append(f"{relative_path}: rules must be a non-empty array")
        return []

    valid_rules: list[dict[str, Any]] = []
    seen_keys: set[tuple[str, str, str]] = set()
    for index, rule in enumerate(rules):
        location = f"rules[{index}]"
        if not isinstance(rule, dict):
            errors.append(f"{relative_path}: {location} must be object")
            continue

        require_non_empty_strings(
            rule,
            [id_field, "region_id", "mountain_id"],
            relative_path,
            location,
            errors,
        )
        validate_non_negative_number(
            rule.get("spawn_weight"),
            relative_path,
            f"{location}.spawn_weight",
            errors,
        )

        if requires_count_range:
            min_count = rule.get("min_count")
            max_count = rule.get("max_count")
            validate_positive_integer(min_count, relative_path, f"{location}.min_count", errors)
            validate_positive_integer(max_count, relative_path, f"{location}.max_count", errors)
            if is_positive_integer(min_count) and is_positive_integer(max_count) and min_count > max_count:
                errors.append(f"{relative_path}: {location} min_count must be <= max_count")

        if id_field == "spawn_id":
            validate_non_empty_string_array(
                rule.get("tags"),
                relative_path,
                f"{location}.tags",
                errors,
            )
        if id_field == "creature_id" and "behavior_hint" in rule:
            behavior_hint = rule["behavior_hint"]
            if not isinstance(behavior_hint, str) or not behavior_hint:
                errors.append(f"{relative_path}: {location}.behavior_hint must be a non-empty string")

        rule_id = rule.get(id_field)
        region_id = rule.get("region_id")
        mountain_id = rule.get("mountain_id")
        if all(isinstance(value, str) and value for value in (rule_id, region_id, mountain_id)):
            unique_key = (region_id, mountain_id, rule_id)
            if unique_key in seen_keys:
                errors.append(
                    f"{relative_path}: duplicate rule for {region_id}/{mountain_id}/{rule_id}"
                )
            seen_keys.add(unique_key)
        valid_rules.append(rule)
    return valid_rules


def validate_rule_references(
    rules: list[dict[str, Any]],
    relative_path: str,
    id_field: str,
    mountains_by_region: dict[str, dict[str, dict[str, Any]]],
    declaration_field: str | None,
    errors: list[str],
) -> None:
    for index, rule in enumerate(rules):
        location = f"rules[{index}]"
        region_id = rule.get("region_id")
        mountain_id = rule.get("mountain_id")
        rule_id = rule.get(id_field)
        if not all(isinstance(value, str) and value for value in (region_id, mountain_id, rule_id)):
            continue
        if region_id not in mountains_by_region:
            errors.append(f"{relative_path}: {location} references unknown region: {region_id}")
            continue
        if mountain_id not in mountains_by_region[region_id]:
            errors.append(
                f"{relative_path}: {location} references unknown mountain: {region_id}/{mountain_id}"
            )
            continue
        if declaration_field is not None:
            declared_ids = mountains_by_region[region_id][mountain_id].get(declaration_field, [])
            if rule_id not in declared_ids:
                errors.append(
                    f"{relative_path}: {location} {id_field} is not declared by "
                    f"{region_id}/{mountain_id}: {rule_id}"
                )


def res_path_to_relative(
    value: Any,
    relative_path: str,
    location: str,
    errors: list[str],
) -> str | None:
    if not isinstance(value, str) or not value:
        return None
    if not value.startswith("res://"):
        errors.append(f"{relative_path}: {location} region_file must use a res:// path")
        return None

    candidate = (GAME_ROOT / value.removeprefix("res://")).resolve()
    try:
        candidate.relative_to(GAME_ROOT.resolve())
    except ValueError:
        errors.append(f"{relative_path}: {location} region_file escapes game root")
        return None
    return candidate.relative_to(ROOT).as_posix()


def require_non_empty_strings(
    data: dict[str, Any],
    fields: list[str],
    relative_path: str,
    location: str,
    errors: list[str],
) -> None:
    for field in fields:
        value = data.get(field)
        if not isinstance(value, str) or not value:
            errors.append(f"{relative_path}: {location} field {field} must be a non-empty string")


def validate_non_empty_string_array(
    value: Any,
    relative_path: str,
    location: str,
    errors: list[str],
) -> None:
    if not isinstance(value, list) or not value:
        errors.append(f"{relative_path}: {location} must be a non-empty array")
        return
    for index, entry in enumerate(value):
        if not isinstance(entry, str) or not entry:
            errors.append(f"{relative_path}: {location}[{index}] must be a non-empty string")


def validate_positive_version(value: Any, relative_path: str, location: str, errors: list[str]) -> None:
    if not is_positive_integer(value):
        errors.append(f"{relative_path}: {location} version must be a positive integer")


def validate_positive_integer(value: Any, relative_path: str, location: str, errors: list[str]) -> None:
    if not is_positive_integer(value):
        errors.append(f"{relative_path}: {location} must be a positive integer")


def validate_non_negative_number(value: Any, relative_path: str, location: str, errors: list[str]) -> None:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or value < 0:
        errors.append(f"{relative_path}: {location} must be a non-negative number")


def is_positive_integer(value: Any) -> bool:
    return not isinstance(value, bool) and isinstance(value, int) and value > 0


def main() -> int:
    errors: list[str] = []

    items_path = "game/data/items/items.json"
    creatures_path = "game/data/creatures/creatures.json"

    items_data = load_json(items_path, errors)
    creatures_data = load_json(creatures_path, errors)

    validate_collection(items_data, items_path, "items", "item", ["id", "name", "type", "stack_size"], errors)
    validate_collection(creatures_data, creatures_path, "creatures", "creature", ["id", "name", "type"], errors)
    validate_world_data(errors)

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
