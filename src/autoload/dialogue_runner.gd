extends Node
## Plays JSON dialogues from data/dialogues. The UI listens to line_changed / finished.
##
## Dialogue: {"start": "n1", "nodes": {"n1": {...}}}
## Node fields (all optional except text for spoken lines):
##   speaker, text, translation (Spanish->EN shown by the phone app, costs battery),
##   next, branch: [{"if": {...}, "next": "id"}], choices: [{"text", "if", "effects", "next"}],
##   effects: [{...}]  (applied when the node is entered; a node with effects but no text is a router)
## Effects: {"energy": -10} {"battery": -5} {"time": 30} {"flag": "x"} {"unflag": "x"}
##   {"flag_today": "x"} {"stamp": "id"} {"word": "id"} {"friendship": {"who": "x", "value": 1}}
##   {"item": "seeds", "count": 3} {"remove_item": "seeds", "count": 1}
##   {"notify": "..."} {"log": "..."} {"message": {"from": "...", "text": "..."}} {"end_day": "reason"}

signal line_changed(speaker: String, text: String, choices: Array, translation: String)
signal finished(dialogue_id: String)

var active := false
var current_id := ""
var _nodes: Dictionary = {}
var _node_id := ""
var _visible_choices: Array = []
var _translated := false
var _started_frame := -1


func start(dialogue_id: String) -> void:
	if active:
		return
	var d := Content.get_dialogue(dialogue_id)
	if d.is_empty():
		push_warning("Unknown dialogue: " + dialogue_id)
		return
	_begin(dialogue_id, d)


func start_line(speaker: String, text: String, translation: String = "") -> void:
	## One-off line without a JSON entry (used by simple map entities).
	if active:
		return
	var node := {"speaker": speaker, "text": text}
	if translation != "":
		node["translation"] = translation
	_begin("__inline__", {"start": "n", "nodes": {"n": node}})


func _begin(id: String, d: Dictionary) -> void:
	active = true
	current_id = id
	_nodes = d.get("nodes", {})
	_started_frame = Engine.get_process_frames()
	GameState.lock_ui()
	_enter(str(d.get("start", "start")))


func _enter(node_id: String) -> void:
	if node_id == "" or not _nodes.has(node_id):
		_finish()
		return
	_node_id = node_id
	_translated = false
	var node: Dictionary = _nodes[node_id]
	if node.has("effects"):
		apply_effects(node["effects"])
		if not active:
			return  # an effect (end_day) may have closed the dialogue
	if not node.has("text"):
		_enter(_resolve_next(node))
		return
	_visible_choices = []
	for c in node.get("choices", []):
		if Conditions.check(c.get("if", {})):
			_visible_choices.append(c)
	line_changed.emit(str(node.get("speaker", "")), str(node["text"]), _visible_choices, str(node.get("translation", "")))


func advance() -> void:
	## Player pressed "interact" on a line without choices.
	if not active or Engine.get_process_frames() == _started_frame:
		return
	if not _visible_choices.is_empty():
		return
	_enter(_resolve_next(_nodes[_node_id]))


func choose(index: int) -> void:
	if not active or index < 0 or index >= _visible_choices.size():
		return
	var c: Dictionary = _visible_choices[index]
	if c.has("effects"):
		apply_effects(c["effects"])
		if not active:
			return
	_enter(str(c.get("next", "")))


func has_translation() -> bool:
	return active and _nodes[_node_id].has("translation")


func translate_current() -> String:
	## Returns the translation (charging the battery once), or "" if unavailable.
	if not active:
		return ""
	var tr := str(_nodes[_node_id].get("translation", ""))
	if tr == "":
		return ""
	if _translated:
		return tr
	if GameState.use_translator():
		_translated = true
		GameState.log_event("Usei a app de tradução.")
		return tr
	return ""


func _resolve_next(node: Dictionary) -> String:
	if node.has("branch"):
		for b in node["branch"]:
			if Conditions.check(b.get("if", {})):
				return str(b.get("next", ""))
	return str(node.get("next", ""))


func _finish() -> void:
	if not active:
		return
	active = false
	var id := current_id
	current_id = ""
	_visible_choices = []
	GameState.unlock_ui()
	finished.emit(id)


func apply_effects(effects: Array) -> void:
	for e in effects:
		if not (e is Dictionary):
			continue
		for key in e:
			var v = e[key]
			match key:
				"energy":
					GameState.change_energy(int(v))
				"battery":
					GameState.change_battery(int(v))
				"time":
					GameState.advance_time(int(v))
				"flag":
					GameState.set_flag(str(v))
				"unflag":
					GameState.set_flag(str(v), false)
				"flag_today":
					GameState.set_flag_today(str(v))
				"stamp":
					GameState.earn_stamp(str(v))
				"word":
					GameState.learn_word(str(v))
				"friendship":
					GameState.change_friendship(str(v.get("who", "")), int(v.get("value", 1)))
				"item":
					GameState.add_item(str(v), int(e.get("count", 1)))
				"remove_item":
					GameState.remove_item(str(v), int(e.get("count", 1)))
				"count":
					pass
				"notify":
					Events.notify.emit(str(v))
				"log":
					GameState.log_event(str(v))
				"message":
					GameState.receive_message(str(v.get("from", "?")), str(v.get("text", "")))
				"end_day":
					_finish()
					GameState.end_day(str(v))
				_:
					push_warning("Unknown effect: " + str(key))
			if not active:
				return
