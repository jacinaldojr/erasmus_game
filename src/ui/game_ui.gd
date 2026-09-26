class_name GameUI
extends CanvasLayer
## Owns every panel and routes keyboard input between them. Panels that cover the game lock the
## clock and the player through GameState.lock_ui / unlock_ui.

signal new_game_requested
signal continue_requested
signal quit_to_menu_requested

var hud: Hud
var dialogue_box: DialogueBox
var passport: PassportPanel
var phone: PhonePanel
var diary: DiaryPanel
var menu: MenuPanel
var _pause_locked := false
var _diary_locked := false


func _ready() -> void:
	layer = 10
	hud = Hud.new()
	add_child(hud)
	dialogue_box = DialogueBox.new()
	add_child(dialogue_box)
	passport = PassportPanel.new()
	add_child(passport)
	phone = PhonePanel.new()
	add_child(phone)
	diary = DiaryPanel.new()
	add_child(diary)
	menu = MenuPanel.new()
	add_child(menu)

	Events.day_ended.connect(_on_day_ended)
	diary.confirmed.connect(_on_diary_confirmed)
	menu.new_game.connect(func() -> void: menu.hide(); new_game_requested.emit())
	menu.continue_game.connect(func() -> void: menu.hide(); continue_requested.emit())
	menu.resume.connect(_close_pause)
	menu.save.connect(func() -> void: SaveManager.save_game())
	menu.quit_to_menu.connect(_on_quit_to_menu)
	menu.quit_app.connect(func() -> void: get_tree().quit())


func show_main_menu(can_continue: bool) -> void:
	_close_overlays()
	hud.visible = false
	menu.show_main(can_continue)


func show_hud() -> void:
	menu.hide()
	hud.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if menu.visible:
		if menu.mode == "pause" and event.is_action_pressed("menu"):
			_close_pause()
			get_viewport().set_input_as_handled()
		return
	if diary.visible:
		if event.is_action_pressed("interact"):
			diary.confirm()
			get_viewport().set_input_as_handled()
		return
	if dialogue_box.visible:
		if event.is_action_pressed("interact"):
			dialogue_box.on_interact()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("translate"):
			dialogue_box.translate()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo:
			var index := _digit_index(event.keycode)
			if index >= 0:
				dialogue_box.choose(index)
				get_viewport().set_input_as_handled()
		return
	if not hud.visible:
		return
	if event.is_action_pressed("passport"):
		_toggle(passport)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("phone"):
		_toggle(phone)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu"):
		if passport.visible:
			_toggle(passport)
		elif phone.visible:
			_toggle(phone)
		else:
			_open_pause()
		get_viewport().set_input_as_handled()


static func _digit_index(keycode: int) -> int:
	match keycode:
		KEY_1, KEY_KP_1:
			return 0
		KEY_2, KEY_KP_2:
			return 1
		KEY_3, KEY_KP_3:
			return 2
		KEY_4, KEY_KP_4:
			return 3
	return -1


func _toggle(panel: Control) -> void:
	if panel.visible:
		panel.close()
		GameState.unlock_ui()
		return
	if passport.visible and panel != passport:
		_toggle(passport)
	if phone.visible and panel != phone:
		_toggle(phone)
	panel.open()
	GameState.lock_ui()


func _close_overlays() -> void:
	if passport.visible:
		_toggle(passport)
	if phone.visible:
		_toggle(phone)
	if _pause_locked:
		_close_pause()


func _open_pause() -> void:
	if _pause_locked:
		return
	_pause_locked = true
	GameState.lock_ui()
	menu.show_pause()


func _close_pause() -> void:
	if not _pause_locked:
		return
	_pause_locked = false
	menu.hide()
	GameState.unlock_ui()


func _on_quit_to_menu() -> void:
	if menu.mode == "pause":
		SaveManager.save_game()
		_close_pause()
	else:
		menu.hide()
	quit_to_menu_requested.emit()


func _on_day_ended(day: int, diary_text: String) -> void:
	_close_overlays()
	_diary_locked = true
	GameState.lock_ui()
	diary.open(day, diary_text)


func _on_diary_confirmed() -> void:
	if _diary_locked:
		_diary_locked = false
		GameState.unlock_ui()
	if GameState.day >= GameState.LAST_DAY:
		SaveManager.delete_save()
		hud.visible = false
		menu.show_end("Sábado. O autocarro parte de madrugada e agora é de Sarriguren que tens saudades. O Unai diz que em basco isso se diz 'herrimina'.\n\nJuntaste %d de 12 carimbos no passaporte. É o fim do MVP." % GameState.stamps.size())
	else:
		GameState.start_next_day()
