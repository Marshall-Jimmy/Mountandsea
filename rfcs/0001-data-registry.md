# RFC 0001: DataRegistry

## Status

Draft

## Goal

DataRegistry provides a single place to load JSON data and expose runtime lookup APIs. Snowhuman Framework code must not hard-code project content. Content data comes from `game/data/`.

## Non-goals

- Define all future data types.
- Implement editor tooling.
- Implement UI.
- Implement inventory systems.
- Implement save or persistence systems.
- Implement interaction systems.
- Implement map systems.
- Implement combat systems.
- Implement project-specific 山海经 logic.

## API

```gdscript
DataRegistry.load_all() -> bool
DataRegistry.reload_all() -> bool
DataRegistry.get_item(id: String) -> Dictionary
DataRegistry.has_item(id: String) -> bool
DataRegistry.get_all_items() -> Array
DataRegistry.get_creature(id: String) -> Dictionary
DataRegistry.has_creature(id: String) -> bool
DataRegistry.get_all_creatures() -> Array
DataRegistry.clear() -> void
```

`load_all()` loads item and creature data from JSON files. `reload_all()` clears the current cache and then calls `load_all()`. `clear()` removes cached items and creatures.

Lookup methods return deep duplicates of stored dictionaries so callers cannot mutate the registry cache. Missing records return `{}` from `get_item()` and `get_creature()`.

When loading succeeds and `EventBus` exists, DataRegistry emits `data_loaded`.

## Data Format

Initial data is loaded from:

- `game/data/items/items.json`
- `game/data/creatures/creatures.json`

Each top-level file includes a `version` field and an array for its record type.

`items.json` must contain an `items` array. Each item must be an object with:

- `id`
- `name`
- `type`
- `stack_size`

`creatures.json` must contain a `creatures` array. Each creature must be an object with:

- `id`
- `name`
- `type`

Record ids must be non-empty strings and must be unique within each collection. Item `stack_size` must be a positive integer.

## Error Handling

DataRegistry and `tools/validate_data.py` report clear errors for:

- missing files
- JSON parse failures
- missing top-level fields
- collection fields that are not arrays
- collection entries that are not objects
- missing required fields
- invalid ids
- duplicate ids
- invalid item `stack_size`

Runtime loading returns `false` on failure and logs an error with `push_error()`. The validation script exits with a non-zero status on failure and prints errors with an `ERROR:` prefix.

## Relationship With Other Modules

DataRegistry is an autoload singleton registered by Snowhuman Framework. Other systems may query it at runtime, but content definitions remain outside the addon.

## Validation Criteria

- It can load `test_item`.
- It can query `test_item`.
- Duplicate ids produce an error.
- Missing fields are detected by the validation script.
- Snowhuman Framework contains no project-specific content.

## Notes

Future RFCs should define additional data collections before implementation.
