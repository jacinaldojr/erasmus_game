# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

A Godot 4.7 proof-of-concept: a cozy Stardew-style game about Vinícius, a 9.º ano student from ESAG (Vila Nova de Gaia), on a one-week Erasmus+ school exchange to Sarriguren, Navarre. The story lives in `STORY.md`; the MVP scope, architecture and content formats are in `docs/MVP_DESIGN.md`. Read both before changing gameplay or content.

Audience is 14-15-year-olds and their school. Keep content school-safe, friendship only, first names only. Never put the real student's contact details (from the PDF profile in the repo root) into game content.

## Running

Godot is not on PATH on this machine. Point `GODOT` at a Godot 4.7+ console executable (Windows: `Godot_v4.x-stable_win64_console.exe`).

```
# first time after a clone: import assets and compile scripts
$GODOT --headless --path . --import

# play (or open the project in the Godot editor and press F5)
$GODOT --path .

# headless smoke test + content lint; exit code 1 on any failure
$GODOT --headless --path . -- --smoke

# save PNGs of the menu, home, dialogue, passport, school and diary to a folder
$GODOT --path . -- --screenshots C:/some/folder

# regenerate the placeholder tile atlas (stdlib Python only)
python tools/make_tileset.py
```

Run the smoke test after every change to `src/` or `data/`. It runs Sunday and Monday end to end and checks every dialogue link, map row width, door target and effect key.

## Layout

- `src/autoload/` singletons in load order: `Events` (signal bus, also registers input actions in code), `Content` (loads all JSON), `GameState` (clock, stats, flags, stamps, save dict), `DialogueRunner`, `SaveManager`.
- `src/core/conditions.gd` is the `{"flag": ..}` condition language shared by dialogues and map entities.
- `src/world/` builds maps from ASCII rows in `data/maps/*.json`; the TileSet is created at runtime from `assets/tiles/tileset.png`.
- `src/entities/` npc, spot, door, garden_plot, bed. Each has `setup(dict)` and, if interactive, `interact(player)`.
- `src/ui/` every panel is built in code (no .tscn) and styled through `UiStyle`. `GameUI` routes keyboard input between panels and locks the clock with `GameState.lock_ui()`.
- `scenes/` are thin shells that only attach scripts and collision shapes.
- `data/` is the content: maps, dialogues, passport, words, texts. Adding a scene usually means editing JSON only.
- `tools/` smoke test, screenshot script, tileset generator.

## Conventions

- GDScript with tabs, typed where cheap, `##` doc comments at the top of each file.
- No editor-only state: build UI and maps in code or JSON so diffs stay reviewable.
- Dialogue and map ids are snake_case; per-day flags use `GameState.set_flag_today`.
- Awarding a stamp goes through `GameState.earn_stamp` (or a `{"stamp": id}` effect) so the HUD, log and toast stay in sync.
- New effect or condition keys must be added to `DialogueRunner.apply_effects` / `Conditions.check` and to the `known_effects` list in `tools/smoke_test.gd`.
- Do not commit `.godot/`. Do commit `*.import` and `*.uid` files that Godot generates.
