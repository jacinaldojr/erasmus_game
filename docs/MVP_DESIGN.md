# Erasmus Game — MVP design (Godot 4)

*26 September 2026. Companion to `STORY.md`, which holds the full week and cast.*

## 1. What the MVP proves

One question: **is "Stardew Valley for one school-exchange week" fun for a 14-year-old for fifteen minutes?**

The MVP is a vertical slice of the first two days. It has every core system of the full game at small scale, and none of the set pieces. If Sunday dinner and Monday at school hold up, the other five days are content, not engineering.

| | |
|---|---|
| **Playable** | Sunday evening (arrival, host family, the 21:30 dinner) and Monday (IES Sarriguren, canteen, eco-garden, Basque lessons). Tuesday onward reuses the same maps with a placeholder diary until content lands. |
| **Session length** | 10–15 minutes for the two days. A game day is about 10 real minutes when the clock runs, plus time spent in dialogue (the clock pauses). |
| **Stamps reachable** | 5 of 12: survive a 21:30 dinner, have almuerzo, learn 5 Basque words, make a Spanish classmate laugh, go a day without the translator. |
| **Target** | Windows desktop, keyboard. Godot 4.7, GL Compatibility renderer, so it runs on school laptops and exports to web later. |

## 2. Core loop

```
wake up 07:00 at Unai's house
  -> talk to the family (breakfast, energy)
  -> walk to IES Sarriguren
  -> spend the day: talk, learn words, eat at the right times, plant/harvest, play basketball
  -> back home for dinner at 21:30 (energy, friendship)
  -> bed -> diary page "Viagens na Terra dos Outros" -> autosave -> next day
```

Three pressures shape the day, all from the story:

- **Clock and meals.** Energy drains one point every 15 game-minutes. Meals only exist in Spanish windows: almuerzo 10:30–11:30, lunch 14:00–15:30, dinner 21:30. Miss them and you're slow (speed drops at 10 energy).
- **Phone battery.** Spanish and Basque lines carry a hidden translation. Reading it through the phone costs 15% battery. Every Basque word learned gives 5% back. A day without the translator is a stamp.
- **The passport.** Twelve stamps in four goals (People, Cultures, Lifestyle, Architecture), the game's "community centre bundles". The HUD shows the count; Tab opens the passport.

## 3. What is in, what is out

| System | MVP | Later |
|---|---|---|
| Top-down movement, collision, doors between maps | yes | more maps (Pamplona, town hall, wind farm) |
| Data-driven dialogue with choices, conditions, effects, translation | yes | portraits, typewriter text, localisation to PT |
| Day clock, energy, meal windows, Mom's 20:00 text, Dad's 22:00 puzzle | yes | weather (Wednesday rain, Thursday cierzo) |
| Passport with 12 stamps | yes (5 earnable) | all 12 |
| Basque words, false friends (esquisito, embarazado) | yes | more scenes per word |
| Eco-garden: plant, sprout, harvest over days | yes | seed swap, harvest photos via eTwinning |
| Friendship points per character | tracked | hearts UI, per-character "secret card" scenes |
| Diary page, save/load (one slot) | yes | multiple slots |
| Character creation from the "Getting to know each other" form | no | prologue |
| Basketball, chess, Brawl Stars minigames | dialogue stubs | real minigames |
| Arcana Club mystery | first card only | riddles, viewpoints, the reveal |
| *El Cierzo* boss fight | no | Thursday |
| Art, music, sound | placeholder tiles and code-drawn figures | pixel art, nu-metal for the storm |

## 4. Architecture

Everything is plain GDScript and JSON. No editor-only state: maps, dialogues and UI are built in code or data so diffs are readable and content can be written without opening Godot.

```
project.godot            Godot 4.7, 640x360 viewport scaled 2x, GL Compatibility
scenes/                  minimal .tscn shells (main, world, player, npc, spot, door, garden_plot, bed)
src/
  autoload/events.gd         signal bus + input map (WASD/arrows, E, Tab, P, Esc, T)
  autoload/content.gd        loads data/*.json, answers "what is stamp X called"
  autoload/game_state.gd     clock, energy, battery, flags, stamps, words, plots, inventory, save dict
  autoload/dialogue_runner.gd plays a dialogue graph, applies effects, exposes translate_current()
  autoload/save_manager.gd   one JSON slot in user://, autosaves at day end and day start
  core/conditions.gd         the {"flag": ..., "time_between": [...]} condition language
  world/map_builder.gd       ASCII rows -> TileMapLayer; TileSet built at runtime from one PNG
  world/world.gd             loads a map, spawns entities, moves the player and camera
  player/player.gd           movement + facing probe that calls interact() on what is in front
  entities/                  npc, spot (examinable place), door, garden_plot, bed
  ui/                        hud, dialogue_box, passport_panel, phone_panel, diary_panel, menu_panel, game_ui
data/
  maps/*.json              rows (ASCII), spawns, entities with dialogue routing
  dialogues/*.json         dialogue graphs
  passport.json            4 goals x 3 stamps, "mvp" flag marks what this build can award
  words.json               Basque word list
  texts.json               Mom/Dad texts per day, diary intro/outro per day
tools/
  make_tileset.py          regenerates assets/tiles/tileset.png (stdlib only)
  smoke_test.gd            headless content lint + gameplay run (377 checks)
  screenshots.gd           windowed run that saves PNGs of menu, home, dialogue, passport, school, diary
```

### Flow of one interaction

1. Player presses E. `player.gd` finds the nearest node with `interact()` inside its facing probe.
2. An NPC or spot walks its `dialogues` list and starts the first whose `if` passes (see `Conditions`).
3. `DialogueRunner` enters the start node, applies its `effects`, emits `line_changed`. `GameState.lock_ui()` pauses the clock and the player.
4. `DialogueBox` shows the line, numbered choices, and a phone-translate button if the node has a `translation`.
5. Choices apply their effects (stamp, flag, energy, time, word, item, friendship, log) and jump to the next node. A node with no `text` is a router: effects plus `next`/`branch`.
6. The last node finishes, the UI unlocks, the clock resumes.

### Dialogue and map data, in one glance

```json
"iker_joke": {
  "start": "n1",
  "nodes": {
    "n1": {"speaker": "Iker", "text": "A ver, di algo en euskera.",
           "translation": "Go on, say something in Basque.",
           "choices": [
             {"text": "\"Egun on, eskerrik asko, agur!\"", "if": {"has_words": ["egun_on", "eskerrik_asko", "agur"]}, "next": "laugh"},
             {"text": "\"Kaixo.\"", "next": "meh"}]},
    "laugh": {"speaker": "Iker", "text": "¡JAJAJA!", "effects": [{"stamp": "make_laugh"}, {"friendship": {"who": "iker", "value": 2}}]},
    "meh":   {"speaker": "Iker", "text": "Sí, ya. Otro día."}
  }
}
```

```json
{"type": "npc", "id": "iker", "name": "Iker", "color": "#2a9d8f", "x": 20, "y": 8,
 "dialogues": [
   {"id": "iker_1", "if": {"not_flag": "iker_1"}},
   {"id": "iker_joke", "if": {"flag": "iker_3", "not_stamp": "make_laugh"}},
   {"id": "iker_default"}]}
```

Maps are ASCII: `#` wall, `.` floor, `,` grass, `=` path, `~` soil, `w` water, `T` tree, `c` carpet. Walls, water and trees collide. Adding a room is editing a string.

## 5. Content in this build

**Sunday, Unai's house (19:00 start).** Arantxa (welcome, then the menestra dinner at 21:30 with the pea choice and the *esquisito/exquisito* false friend), Unai ("Kaixo." and the tarot card the next morning), Nahia (Roblox), Iñaki (Linkin Park), Aitona Joxemari (the Ruy López rematch, teaches *aitona*), Txuri (teaches *txuri*). Bed only works after dinner. Diary mentions The Fool under the pillow.

**Monday, IES Sarriguren (07:00 start, breakfast at home first).** Maite (welcome, false-friends warning that reacts to Sunday), Iker (five free Basque lessons, and a joke that needs three of them), the Basque classroom (translation shows what the class was actually about), the canteen (almuerzo and lunch windows), the basketball hoop with Duarte and Leonor, Rafael and the eco-garden (three seed packets, five plots), Gonçalo ("muy embarazado"), Tiago (homesick), Unai (pelota-for-basketball deal), the lake.

**Every day.** Mom texts "Já jantaste?" at 20:00. Dad sends a chess puzzle at 22:00. Dinner at 21:30 restores energy. The diary lists what happened.

## 6. Controls

| Key | Action |
|---|---|
| WASD / arrows | move |
| E / Space / Enter | talk, examine, continue dialogue |
| 1–4 or click | pick a dialogue choice |
| T | phone-translate the current line (costs battery) |
| Tab | passport |
| P | phone: battery, messages, Basque words, pocket |
| Esc | close panel / pause menu (save, quit to menu) |

## 7. Milestones after the MVP

1. **Playtest with the target player.** One 9.º ano student, fifteen minutes, no help. Watch: do they find almuerzo, do they use the translator, does the pea joke land.
2. **Tuesday: Pamplona.** New map, viewpoints that reveal the map, the gilda argument, the second riddle. First real stamp outside the school.
3. **Art pass.** Replace the runtime tileset and code-drawn figures with 16x16 pixel art. The `MapBuilder` legend and the entity `color` fields are the only places to touch.
4. **Prologue and character creation** from the "Getting to know each other" form, so any of the 15 students can play their own version.
5. **Wednesday to Saturday**, then the *El Cierzo* fight as the one combat set piece.
6. **Portuguese localisation.** Narration and UI are English in the MVP; NPCs already speak Spanish, Basque and Portuguese. Move UI strings to Godot's translation CSV.

## 8. Open questions (unchanged from STORY.md)

Trip dates, the real daily programme, host families vs hostel, and whether the Spanish group visits Gaia. None of them block the next milestone.
