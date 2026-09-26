extends Node
## Headless smoke test + content lint. Run:  godot --headless --path . -- --smoke
## Exits 0 when everything passes, 1 otherwise. Prints one line per check.

var _failures := 0
var _passes := 0


func _ready() -> void:
	await get_tree().process_frame
	await _run()


func _check(cond: bool, msg: String) -> void:
	if cond:
		_passes += 1
		print("  ok   " + msg)
	else:
		_failures += 1
		printerr("  FAIL " + msg)


func _run_dialogue(id: String, pick: int = 0) -> void:
	## Runs a dialogue to the end, always taking choice `pick` (or the last one if fewer).
	DialogueRunner.start(id)
	_check(DialogueRunner.active, "dialogue '%s' started" % id)
	var guard := 0
	while DialogueRunner.active and guard < 60:
		guard += 1
		await get_tree().process_frame
		var n: int = DialogueRunner._visible_choices.size()
		if n > 0:
			DialogueRunner.choose(mini(pick, n - 1))
		else:
			DialogueRunner.advance()
	_check(not DialogueRunner.active, "dialogue '%s' finished" % id)


func _lint_content() -> void:
	_check(Content.all_stamps().size() == 12, "passport defines 12 stamps")
	for map_id in Content.maps:
		var m: Dictionary = Content.maps[map_id]
		var rows: Array = m.get("rows", [])
		var width: int = str(rows[0]).length() if rows.size() > 0 else 0
		var uniform := true
		for r in rows:
			if str(r).length() != width:
				uniform = false
		_check(uniform, "map '%s' rows all %d wide" % [map_id, width])
		var decor_rows: Array = m.get("decor", [])
		if not decor_rows.is_empty():
			var decor_ok := decor_rows.size() == rows.size()
			for r in decor_rows:
				if str(r).length() != width:
					decor_ok = false
			_check(decor_ok, "map '%s' decor layer matches ground size" % map_id)
		for e in m.get("entities", []):
			if e.get("type") == "prop":
				_check(Prop.SPECS.has(str(e.get("sprite", ""))), "map '%s' prop '%s' is known" % [map_id, e.get("sprite", "")])
			if e.get("type") == "npc" and str(e.get("shape", "person")) == "person":
				var cast_id := str(e.get("sprite", e.get("id", "")))
				_check(not Content.cast_entry(cast_id).is_empty(), "map '%s' npc '%s' has a cast entry" % [map_id, cast_id])
			var ex := int(e.get("x", -1))
			var ey := int(e.get("y", -1))
			_check(ex >= 0 and ey >= 0 and ey < rows.size() and ex < width, "map '%s' entity %s inside bounds" % [map_id, e.get("name", e.get("type", "?"))])
			if e.get("type") == "door":
				var to := str(e.get("to", ""))
				_check(Content.maps.has(to), "door in '%s' targets known map '%s'" % [map_id, to])
				_check(Content.maps.get(to, {}).get("spawns", {}).has(str(e.get("spawn", ""))), "door in '%s' targets known spawn '%s' in '%s'" % [map_id, e.get("spawn", ""), to])
			for d in e.get("dialogues", []):
				_check(Content.dialogues.has(str(d.get("id", ""))), "map '%s' references dialogue '%s'" % [map_id, d.get("id", "")])
	for cast_id in Content.cast:
		if str(cast_id).begins_with("_"):
			continue
		var sheet := str(Content.cast[cast_id].get("sheet", ""))
		_check(ResourceLoader.exists(sheet), "cast '%s' sheet exists" % cast_id)
	var known_effects := ["energy", "battery", "time", "flag", "unflag", "flag_today", "stamp", "word", "friendship", "item", "remove_item", "count", "notify", "log", "message", "end_day"]
	for id in Content.dialogues:
		var d: Dictionary = Content.dialogues[id]
		var nodes: Dictionary = d.get("nodes", {})
		_check(nodes.has(str(d.get("start", "start"))), "dialogue '%s' start node exists" % id)
		for nid in nodes:
			var node: Dictionary = nodes[nid]
			var targets := []
			if node.has("next"):
				targets.append(node["next"])
			for b in node.get("branch", []):
				targets.append(b.get("next", ""))
			for c in node.get("choices", []):
				targets.append(c.get("next", ""))
				for e in c.get("effects", []):
					for k in e:
						_check(k in known_effects, "dialogue '%s' node '%s' choice effect '%s' is known" % [id, nid, k])
			for t in targets:
				if str(t) != "":
					_check(nodes.has(str(t)), "dialogue '%s' node '%s' -> '%s' exists" % [id, nid, t])
			for e in node.get("effects", []):
				for k in e:
					_check(k in known_effects, "dialogue '%s' node '%s' effect '%s' is known" % [id, nid, k])
				if e.has("stamp"):
					_check(Content.stamp_name(str(e["stamp"])) != str(e["stamp"]), "dialogue '%s' awards known stamp '%s'" % [id, e["stamp"]])
				if e.has("word"):
					_check(Content.words.has(str(e["word"])), "dialogue '%s' teaches known word '%s'" % [id, e["word"]])


func _run() -> void:
	print("== content lint ==")
	_lint_content()

	print("== Sunday ==")
	var main := get_parent()
	GameState.new_game()
	main._start_world()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(main.world != null, "world created")
	_check(main.world.map_id == "home", "home map loaded")
	_check(main.world.entities.get_child_count() > 5, "home entities spawned (%d)" % main.world.entities.get_child_count())
	_check(main.ui.hud.visible, "HUD visible")

	await _run_dialogue("arantxa_welcome", 0)
	_check(GameState.has_flag("met_arantxa"), "met Arantxa")
	await _run_dialogue("unai_sunday", 0)
	_check(GameState.knows_word("kaixo"), "learned kaixo from Unai")
	_check(not GameState.can_sleep(), "cannot sleep before dinner on Sunday")

	GameState.minutes = 21 * 60 + 30
	await _run_dialogue("arantxa_dinner_day0", 0)
	_check(GameState.has_stamp("dinner_2130"), "stamp: survived 21:30 dinner")
	_check(GameState.has_flag_today("dinner_done"), "dinner flag set for today")
	_check(GameState.has_flag("ff_esquisito"), "false friend 'esquisito' collected")
	_check(GameState.can_sleep(), "can sleep after dinner")

	GameState.end_day("test: went to bed")
	await get_tree().process_frame
	_check(not GameState.clock_running, "clock stopped at day end")
	_check(main.ui.diary.visible, "diary shown")
	_check(SaveManager.has_save(), "autosaved at day end")
	main.ui.diary.confirm()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(GameState.day == 1, "advanced to Monday")
	_check(GameState.clock_running, "clock running on Monday")
	_check(main.world.map_id == "home", "woke up at home")
	_check(GameState.minutes == GameState.DAY_START_MINUTES, "Monday starts at 07:00")

	print("== Monday ==")
	Events.map_change_requested.emit("street", "from_home")
	await get_tree().process_frame
	await get_tree().process_frame
	_check(main.world.map_id == "street", "street map loaded")
	_check(main.world.entities.get_child_count() > 10, "street props and entities spawned (%d)" % main.world.entities.get_child_count())
	_check(main.world.decor.get_used_cells().size() > 20, "street decor tiles placed (%d)" % main.world.decor.get_used_cells().size())
	Events.map_change_requested.emit("school", "from_street")
	await get_tree().process_frame
	await get_tree().process_frame
	_check(main.world.map_id == "school", "school map loaded")
	_check(main.world.player.sprite.texture != null, "player has a character sheet")
	_check(main.world.entities.get_child_count() > 10, "school entities spawned (%d)" % main.world.entities.get_child_count())

	for id in ["iker_1", "iker_2", "iker_3"]:
		await _run_dialogue(id, 0)
	await _run_dialogue("iker_joke", 0)
	_check(GameState.has_stamp("make_laugh"), "stamp: made Iker laugh")
	for id in ["iker_4", "iker_5"]:
		await _run_dialogue(id, 0)
	_check(GameState.words.size() >= 5, "knows %d Basque words" % GameState.words.size())
	_check(GameState.has_stamp("basque_5"), "stamp: 5 Basque words")

	GameState.minutes = 10 * 60 + 45
	await _run_dialogue("canteen_almuerzo", 0)
	_check(GameState.has_stamp("almuerzo"), "stamp: almuerzo")

	await _run_dialogue("rafael_seeds", 0)
	_check(GameState.item_count("seeds") == 3, "got 3 seed packets")
	GameState.remove_item("seeds", 1)
	GameState.plant("garden_1", "cress")
	_check(GameState.plot_stage("garden_1") == 1, "plot planted today")

	var battery_before := GameState.battery
	DialogueRunner.start("goncalo_embarazado")
	await get_tree().process_frame
	var tr := DialogueRunner.translate_current()
	_check(tr != "", "translator returned text")
	_check(GameState.battery == battery_before - GameState.TRANSLATOR_BATTERY_COST, "translator cost battery")
	_check(GameState.used_translator_today, "translator use recorded")
	while DialogueRunner.active:
		await get_tree().process_frame
		if DialogueRunner._visible_choices.size() > 0:
			DialogueRunner.choose(0)
		else:
			DialogueRunner.advance()

	print("== save / load ==")
	SaveManager.save_game()
	var day_before := GameState.day
	var stamps_before := GameState.stamps.size()
	GameState.new_game()
	_check(SaveManager.load_game(), "save loaded")
	_check(GameState.day == day_before and GameState.stamps.size() == stamps_before, "state restored (day %d, %d stamps)" % [GameState.day, GameState.stamps.size()])
	_check(GameState.plot_stage("garden_1") == 1, "plot survived save/load")
	SaveManager.delete_save()

	print("== pause / passport ==")
	var ev := InputEventAction.new()
	ev.action = "passport"
	ev.pressed = true
	main.ui._unhandled_input(ev)
	_check(main.ui.passport.visible, "passport opens on Tab")
	_check(GameState.is_ui_locked(), "passport locks the clock")
	main.ui._unhandled_input(ev)
	_check(not main.ui.passport.visible and not GameState.is_ui_locked(), "passport closes and unlocks")

	print("SMOKE RESULT: %d passed, %d failed" % [_passes, _failures])
	get_tree().quit(1 if _failures > 0 else 0)
