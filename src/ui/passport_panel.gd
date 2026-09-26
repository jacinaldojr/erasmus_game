class_name PassportPanel
extends PanelContainer
## The Erasmus+ passport: 4 goals x 3 stamps = 12, like the stars on the flag.

var body: VBoxContainer


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(380, 0)
	add_theme_stylebox_override("panel", UiStyle.panel_box(Color(0.10, 0.16, 0.36, 0.96), UiStyle.ACCENT, 12))
	body = VBoxContainer.new()
	add_child(body)


func open() -> void:
	_refresh()
	visible = true


func close() -> void:
	visible = false


func _refresh() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	body.add_child(UiStyle.label("PASSAPORTE ERASMUS+   %d / 12" % GameState.stamps.size(), 13, UiStyle.ACCENT))
	body.add_child(UiStyle.label("Vinícius Medeiros, ESAG, Vila Nova de Gaia  ->  IES Sarriguren, Navarra", 7, UiStyle.MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 6)
	body.add_child(grid)
	for goal in Content.passport.get("goals", []):
		var v := VBoxContainer.new()
		v.add_child(UiStyle.label(str(goal.get("name", "")).to_upper(), 10, UiStyle.ACCENT))
		for stamp in goal.get("stamps", []):
			var id := str(stamp.get("id", ""))
			var earned := GameState.has_stamp(id)
			var mvp := bool(stamp.get("mvp", false))
			var mark := "[*]" if earned else ("[ ]" if mvp else "[-]")
			var color := UiStyle.GOOD if earned else (UiStyle.TEXT if mvp else UiStyle.MUTED)
			var l := UiStyle.label("%s %s" % [mark, str(stamp.get("name", id))], 8, color)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(170, 0)
			v.add_child(l)
		grid.add_child(v)
	body.add_child(UiStyle.label("[-] not in this build.   Tab / Esc: close", 7, UiStyle.MUTED))
