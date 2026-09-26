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
	draw_rect(Rect2(-8, -8, 16, 16), Color(1, 1, 1, 0.15))
	draw_rect(Rect2(-6, -6, 12, 12), Color.html("#ffd617"), false, 1.0)
	if label != "":
		draw_string(ThemeDB.fallback_font, Vector2(-30, -10), label, HORIZONTAL_ALIGNMENT_CENTER, 60, 6, Color.WHITE)
