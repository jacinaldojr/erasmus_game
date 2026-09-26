extends Node
## One save slot as JSON in user://. Autosaves at the end of every day.

const SAVE_PATH := "user://erasmus_save.json"


func _ready() -> void:
	Events.day_ended.connect(func(_day: int, _text: String) -> void: save_game())


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not write save: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	f.close()
	Events.notify.emit("Jogo guardado.")


func load_game() -> bool:
	if not has_save():
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed == null or not (parsed is Dictionary):
		push_error("Save file is corrupt.")
		return false
	GameState.from_dict(parsed)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
