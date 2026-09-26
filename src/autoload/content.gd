extends Node
## Loads every JSON under res://data and answers content questions (stamps, words, maps, dialogues).

var passport: Dictionary = {}
var words: Dictionary = {}
var texts: Dictionary = {}
var dialogues: Dictionary = {}
var maps: Dictionary = {}
var cast: Dictionary = {}


func _ready() -> void:
	passport = _load_json("res://data/passport.json")
	words = _load_json("res://data/words.json")
	texts = _load_json("res://data/texts.json")
	cast = _load_json("res://data/cast.json")
	_load_dir("res://data/dialogues", dialogues)
	_load_dir("res://data/maps", maps)


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing content file: " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_error("Invalid JSON in " + path)
		return {}
	return parsed


func _load_dir(dir_path: String, into: Dictionary) -> void:
	for file in DirAccess.get_files_at(dir_path):
		if not file.ends_with(".json"):
			continue
		var data := _load_json(dir_path.path_join(file))
		for key in data:
			if into.has(key):
				push_warning("Duplicate content id '%s' in %s" % [key, file])
			into[key] = data[key]


func get_dialogue(id: String) -> Dictionary:
	return dialogues.get(id, {})


func get_map(id: String) -> Dictionary:
	return maps.get(id, {})


func cast_entry(id: String) -> Dictionary:
	## Sprite sheet + recolour map for a character id (see data/cast.json). {} if unknown.
	var entry = cast.get(id, {})
	return entry if entry is Dictionary else {}


func all_stamps() -> Array:
	var out := []
	for goal in passport.get("goals", []):
		for stamp in goal.get("stamps", []):
			out.append(stamp)
	return out


func stamp_name(stamp_id: String) -> String:
	for stamp in all_stamps():
		if stamp.get("id", "") == stamp_id:
			return stamp.get("name", stamp_id)
	return stamp_id


func word_display(word_id: String) -> String:
	return words.get(word_id, {}).get("basque", word_id)


func word_meaning(word_id: String) -> String:
	return words.get(word_id, {}).get("meaning", "?")


static func parse_time(value) -> int:
	## Accepts minutes since midnight (int) or "HH:MM".
	if value is String:
		var parts: PackedStringArray = value.split(":")
		if parts.size() == 2:
			return int(parts[0]) * 60 + int(parts[1])
		return int(value)
	return int(value)


func mom_text_for_day(day: int) -> String:
	var list: Array = texts.get("mom_texts", [])
	if list.is_empty():
		return "Já jantaste?"
	return list[mini(day, list.size() - 1)]


func dad_text_for_day(day: int) -> String:
	var list: Array = texts.get("dad_texts", [])
	if list.is_empty():
		return "Puzzle de hoje: mate em 2."
	return list[mini(day, list.size() - 1)]


func diary_for_day(day: int, log: Array, reason: String) -> String:
	var entries: Dictionary = texts.get("diary", {})
	var key := str(day)
	var entry: Dictionary = entries.get(key, entries.get("default", {}))
	var out := ""
	out += entry.get("intro", "") + "\n\n"
	if reason != "":
		out += reason + "\n\n"
	if log.is_empty():
		out += "Não aconteceu grande coisa. Também é uma espécie de dia.\n"
	else:
		for line in log:
			out += "• " + str(line) + "\n"
	out += "\n" + entry.get("outro", "")
	out += "\n\nPalavras em basco até agora: %d.  Carimbos no passaporte: %d / 12." % [GameState.words.size(), GameState.stamps.size()]
	return out.strip_edges()
