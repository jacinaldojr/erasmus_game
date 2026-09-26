extends CharacterBody2D
## Vinícius. Top-down 8-direction movement plus a facing-side interaction probe.

const SPEED := 90.0
const TIRED_SPEED_FACTOR := 0.6
const PROBE_DISTANCE := 13.0
const CAST_ID := "vinicius"

var facing := Vector2.DOWN
var sprite: CharacterSprite
@onready var interact_area: Area2D = $InteractArea


func _ready() -> void:
	sprite = CharacterSprite.new()
	var cast := Content.cast_entry(CAST_ID)
	sprite.setup(str(cast.get("sheet", "")), cast.get("recolor", {}))
	add_child(sprite)
	move_child(sprite, 0)


func _physics_process(_delta: float) -> void:
	if GameState.is_ui_locked():
		velocity = Vector2.ZERO
		sprite.moving = false
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		facing = _snap4(dir)
		interact_area.position = facing * PROBE_DISTANCE
		sprite.facing = dir
	sprite.moving = dir != Vector2.ZERO
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
