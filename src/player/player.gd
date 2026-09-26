extends CharacterBody2D
## Vinícius. Top-down 8-direction movement plus a facing-side interaction probe.

const SPEED := 90.0
const TIRED_SPEED_FACTOR := 0.6
const PROBE_DISTANCE := 13.0

var facing := Vector2.DOWN
@onready var interact_area: Area2D = $InteractArea


func _physics_process(_delta: float) -> void:
	if GameState.is_ui_locked():
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		facing = _snap4(dir)
		interact_area.position = facing * PROBE_DISTANCE
		queue_redraw()
	var speed := SPEED * (TIRED_SPEED_FACTOR if GameState.energy <= 10 else 1.0)
	velocity = dir * speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not GameState.is_ui_locked():
		if try_interact():
			get_viewport().set_input_as_handled()


func try_interact() -> bool:
	var best: Node = null
	var best_distance := INF
	for area in interact_area.get_overlapping_areas():
		var target: Node = area if area.has_method("interact") else area.get_parent()
		if target == null or not target.has_method("interact"):
			continue
		var d := global_position.distance_to((target as Node2D).global_position)
		if d < best_distance:
			best = target
			best_distance = d
	if best == null:
		return false
	best.interact(self)
	return true


static func _snap4(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2.RIGHT if v.x > 0 else Vector2.LEFT
	return Vector2.DOWN if v.y > 0 else Vector2.UP


func _draw() -> void:
	draw_circle(Vector2(0, 8), 5.0, Color(0, 0, 0, 0.25))
	draw_rect(Rect2(-5, -4, 10, 12), Color.html("#2f5fbf"))          # hoodie
	draw_rect(Rect2(-3, 6, 2, 3), Color.html("#333333"))              # legs
	draw_rect(Rect2(1, 6, 2, 3), Color.html("#333333"))
	draw_circle(Vector2(0, -8), 5.0, Color.html("#e8b894"))           # head
	draw_rect(Rect2(-5, -13, 10, 4), Color.html("#2b1d12"))           # hair
	if facing == Vector2.DOWN or facing == Vector2.LEFT or facing == Vector2.RIGHT:
		var dx := 0.0 if facing == Vector2.DOWN else (2.0 if facing == Vector2.RIGHT else -2.0)
		draw_rect(Rect2(-2 + dx, -8, 1, 1), Color.BLACK)
		draw_rect(Rect2(1 + dx, -8, 1, 1), Color.BLACK)
	draw_string(ThemeDB.fallback_font, Vector2(-4, 4), "25", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color.WHITE)
