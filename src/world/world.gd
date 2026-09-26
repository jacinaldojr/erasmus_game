extends Node2D
## Owns the current map: builds tiles, spawns props and entities from data/maps/*.json, places the player.

const PlayerScene := preload("res://scenes/player.tscn")
const NpcScene := preload("res://scenes/npc.tscn")
const SpotScene := preload("res://scenes/spot.tscn")
const DoorScene := preload("res://scenes/door.tscn")
const PlotScene := preload("res://scenes/garden_plot.tscn")
const BedScene := preload("res://scenes/bed.tscn")

var ground: TileMapLayer
var decor: TileMapLayer
var entities: Node2D
var player: CharacterBody2D
var camera: Camera2D
var map_id := ""
var map_size := Vector2i.ZERO


func _ready() -> void:
	ground = TileMapLayer.new()
	ground.name = "Ground"
	add_child(ground)
	decor = TileMapLayer.new()
	decor.name = "Decor"
	add_child(decor)
	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)
	player = PlayerScene.instantiate()
	player.name = "Player"
	entities.add_child(player)
	camera = Camera2D.new()
	camera.zoom = Vector2(2, 2)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	camera.make_current()

	Events.map_change_requested.connect(_on_map_change_requested)
	Events.day_started.connect(_on_day_started)
	load_map(GameState.current_map, GameState.current_spawn)


func _on_map_change_requested(id: String, spawn: String) -> void:
	# Deferred: the request usually comes from a door's body_entered callback.
	load_map.call_deferred(id, spawn)


func _on_day_started(_day: int) -> void:
	load_map.call_deferred(GameState.current_map, GameState.current_spawn)


func load_map(id: String, spawn: String) -> void:
	var data := Content.get_map(id)
	if data.is_empty():
		push_warning("Unknown map: " + id)
		return
	map_id = id
	GameState.current_map = id
	GameState.current_spawn = spawn
	for child in entities.get_children():
		if child != player:
			entities.remove_child(child)
			child.queue_free()
	var built := MapBuilder.build(ground, decor, data)
	map_size = built["size"]
	for p in built["props"]:
		_spawn_prop(p)
	for e in data.get("entities", []):
		_spawn_entity(e)
	var spawns: Dictionary = data.get("spawns", {})
	var cell: Array = spawns.get(spawn, spawns.get("start", [1, 1]))
	player.global_position = MapBuilder.cell_to_world(Vector2i(int(cell[0]), int(cell[1])))
	player.velocity = Vector2.ZERO
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map_size.x * MapBuilder.TILE
	camera.limit_bottom = map_size.y * MapBuilder.TILE
	camera.reset_smoothing()
	Events.location_changed.emit(str(data.get("name", id)))


func _spawn_prop(p: Dictionary) -> void:
	var node := Prop.new()
	node.position = MapBuilder.point_to_world(Vector2(float(p.get("x", 0)), float(p.get("y", 0))))
	entities.add_child(node)
	node.setup(p)


func _spawn_entity(e: Dictionary) -> void:
	if not Conditions.check(e.get("if", {})):
		return
	var node: Node2D
	match str(e.get("type", "")):
		"prop":
			_spawn_prop(e)
			return
		"npc":
			node = NpcScene.instantiate()
		"spot":
			node = SpotScene.instantiate()
		"door":
			node = DoorScene.instantiate()
		"plot":
			node = PlotScene.instantiate()
		"bed":
			node = BedScene.instantiate()
		_:
			push_warning("Unknown entity type in map %s: %s" % [map_id, e])
			return
	node.position = MapBuilder.cell_to_world(Vector2i(int(e.get("x", 0)), int(e.get("y", 0))))
	entities.add_child(node)
	if node.has_method("setup"):
		node.setup(e)
