extends Node
## Saves a few PNGs of the running game (needs a window, not --headless) and quits.
## Run:  godot --path . -- --screenshots [out_dir]      (default: user://screenshots)

var out_dir := "user://screenshots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--screenshots")
	if i >= 0 and i + 1 < args.size() and not args[i + 1].begins_with("--"):
		out_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	await _run()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := out_dir.path_join(name + ".png")
	img.save_png(path)
	print("saved ", ProjectSettings.globalize_path(path))


func _wait(frames: int) -> void:
	for _f in frames:
		await get_tree().process_frame


func _run() -> void:
	var main := get_parent()
	main.ui.show_main_menu(false)
	await _wait(5)
	await _shot("01_menu")

	GameState.new_game()
	main._start_world()
	await _wait(15)
	await _shot("02_home_sunday")

	GameState.minutes = 21 * 60 + 30
	DialogueRunner.start("arantxa_dinner_day0")
	await _wait(3)
	await _shot("03_dialogue")
	DialogueRunner.advance()
	await _wait(2)
	await _shot("04_choices")
	while DialogueRunner.active:
		await get_tree().process_frame
		if DialogueRunner._visible_choices.size() > 0:
			DialogueRunner.choose(0)
		else:
			DialogueRunner.advance()

	main.ui._toggle(main.ui.passport)
	await _wait(3)
	await _shot("05_passport")
	main.ui._toggle(main.ui.passport)

	Events.map_change_requested.emit("street", "from_home")
	await _wait(20)
	await _shot("06_street")

	Events.map_change_requested.emit("school", "from_street")
	await _wait(20)
	await _shot("07_school")
	main.world.player.global_position = MapBuilder.cell_to_world(Vector2i(14, 8))
	main.world.camera.reset_smoothing()
	await _wait(5)
	await _shot("08_school_inside")

	GameState.end_day("Fui para a cama.")
	await _wait(3)
	await _shot("09_diary")
	SaveManager.delete_save()
	get_tree().quit()
