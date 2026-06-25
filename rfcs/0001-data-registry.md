# RFC 0001: DataRegistry

## Status

Draft

## Goal

DataRegistry provides a single place to load JSON data and expose runtime lookup APIs. Core code must not hard-code project content. Content data comes from `game/data/`.

## Non-goals

- Define all future data types.
- Implement editor tooling.
- Implement full save, inventory, interaction, map, or combat systems.

## API

```gdscript
DataRegistry.load_all() -> bool
DataRegistry.get_item(id: String) -> Dictionary
DataRegistry.has_item(id: String) -> bool
DataRegistry.get_creature(id: String) -> Dictionary
DataRegistry.has_creature(id: String) -> bool
```

## Data Format

Initial data is loaded from:

- `game/data/items/items.json`
- `game/data/creatures/creatures.json`

Each top-level file includes a `version` field and an array for its record type.

## Error Handling

DataRegistry should report errors for:

- missing files
- JSON parse failures
- missing top-level fields
- duplicate ids
- missing required fields

## Relationship With Other Modules

DataRegistry is an autoload singleton registered by the addon. Other systems may query it at runtime, but content definitions remain outside the addon.

## Validation Criteria

- It can load `test_item`.
- It can query `test_item`.
- Duplicate ids produce an error.
- Missing fields are detected by the validation script.
- Core contains no project-specific content.

## Notes

Future RFCs should define additional data collections before implementation.
