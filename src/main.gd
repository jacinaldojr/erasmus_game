extends Node
## Entry point: owns the UI layer and the current World. Menu -> world -> menu.
## Run headless checks with:  godot --headless --path . -- --smoke

const WorldScene := preload("res://scenes/world.tscn")

var world: Node2D
var ui: GameUI


func _ready() -> void:
	ui = GameUI.new()
	add_child(ui)
	ui.new_game_requested.connect(_new_game)
	ui.continue_requested.connect(_continue_game)
	ui.quit_to_menu_requested.connect(_to_menu)
	var args := OS.get_cmdline_user_args()
	if "--smoke" in args:
		add_child(load("res://tools/smoke_test.gd").new())
	elif "--screenshots" in args:
		add_child(load("res://tools/screenshots.gd").new())
	else:
		ui.show_main_menu(SaveManager.has_save())


func _new_game() -> void:
	GameState.new_game()
	_start_world()


func _continue_game() -> void:
	if not SaveManager.load_game():
		GameState.new_game()
	_start_world()


func _start_world() -> void:
	_free_world()
	world = WorldScene.instantiate()
	add_child(world)
	move_child(world, 0)
	GameState.clock_running = true
	ui.show_hud()


func _to_menu() -> void:
	_free_world()
	GameState.clock_running = false
	ui.show_main_menu(SaveManager.has_save())


func _free_world() -> void:
	if world != null:
		remove_child(world)
		world.queue_free()
		world = null
