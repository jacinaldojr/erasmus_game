extends Area2D
## Walking onto a door loads another map. Armed after a short delay so spawning next to it is safe.
## Map entity: {"type": "door", "x": 8, "y": 12, "to": "school", "spawn": "from_home", "label": "To school"}

var target_map := ""
var target_spawn := "start"
var label := ""
var _armed := false


func setup(d: Dictionary) -> void:
	target_map = str(d.get("to", ""))
	target_spawn = str(d.get("spawn", "start"))
	label = str(d.get("label", ""))
	queue_redraw()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(0.4).timeout.connect(func() -> void: _armed = true)


func _on_body_entered(body: Node) -> void:
	if not _armed or body.name != "Player" or target_map == "":
		return
	if GameState.is_ui_locked():
		return
	_armed = false
	Events.map_change_requested.emit(target_map, target_spawn)


func _draw() -> void:
	# Soft highlight only; the tiles underneath (door mat, path end, house door) do the talking.
	draw_rect(Rect2(-7, -7, 14, 14), Color(1, 1, 0.6, 0.12))
	if label != "":
		var font := ThemeDB.fallback_font
		var pos := Vector2(-50, -12)
		draw_string_outline(font, pos, label, HORIZONTAL_ALIGNMENT_CENTER, 100, 6, 2, Color(0, 0, 0, 0.85))
		draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_CENTER, 100, 6, Color.WHITE)
