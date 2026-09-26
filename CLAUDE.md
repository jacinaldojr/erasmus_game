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
- `src/world/` builds maps from ASCII `rows` (ground) and `decor` layers in `data/maps/*.json`. One TileSet is created at runtime from three atlases: the generated interior `assets/tiles/tileset.png`, and Lakiiah's `Ground Tiles.png` and `House Tiles.png`. Paths, tilled soil and fences are autotiled from their neighbours; the legends are documented at the top of `map_builder.gd`.
- `src/entities/` npc, spot, door, garden_plot, bed, prop (y-sorted scenery with collider) and `character_sprite.gd` (animated 8-direction 32x32 sheet with recolouring). Each entity has `setup(dict)` and, if interactive, `interact(player)`.
- `data/cast.json` maps a character id to a sprite sheet and a recolour map (exact hex -> hex). NPCs use `sprite` or fall back to their `id`; the player is `vinicius`.
- `src/ui/` every panel is built in code (no .tscn) and styled through `UiStyle`. `GameUI` routes keyboard input between panels and locks the clock with `GameState.lock_ui()`.
- `scenes/` are thin shells that only attach scripts and collision shapes.
- `data/` is the content: maps, dialogues, passport, words, texts. Adding a scene usually means editing JSON only.
- `tools/` smoke test, screenshot script, tileset generator.

## Conventions

- GDScript with tabs, typed where cheap, `##` doc comments at the top of each file.
- No editor-only state: build UI and maps in code or JSON so diffs stay reviewable.
- Player-facing text (narration, choices, logs, translations, UI) is European Portuguese (pt-PT: "telemóvel", "autocarro", "tu" forms). Spanish and Basque NPC lines stay in their language, with a Portuguese `translation`. Ids, code and comments stay in English.
- Dialogue and map ids are snake_case; per-day flags use `GameState.set_flag_today`.
- Awarding a stamp goes through `GameState.earn_stamp` (or a `{"stamp": id}` effect) so the HUD, log and toast stay in sync.
- New effect or condition keys must be added to `DialogueRunner.apply_effects` / `Conditions.check` and to the `known_effects` list in `tools/smoke_test.gd`.
- Do not commit `.godot/`. Do commit `*.import` and `*.uid` files that Godot generates.

## Assets

- Exterior tiles: "Cozy RPG Tileset" by Lakiiah (credit in its README; https://lakiah.itch.io/). No water or interior tiles in the pack, so interiors use the generated atlas and the lake is off-screen.
- Characters: `assets/characters/{kids,adults}/*_32x32_idle-run.png`, 6 columns x 16 rows: rows 0-7 idle, 8-15 run, directions S, SW, W, NW, N, NE, E, SE. No licence file was supplied with them; check before distributing.
- To add a character, add a `data/cast.json` entry. To recolour, list the sheet's exact outfit colours (the `_note` in cast.json has the kid sheets') and map them to new ones.
