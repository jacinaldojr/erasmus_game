class_name MenuPanel
extends PanelContainer
## Main menu, pause menu and end screen share one centred panel.

signal new_game
signal continue_game
signal resume
signal save
signal quit_to_menu
signal quit_app

var mode := "main"
var title_label: Label
var subtitle_label: Label
var buttons_box: VBoxContainer


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(300, 0)
	add_theme_stylebox_override("panel", UiStyle.panel_box(Color(0.10, 0.16, 0.36, 0.97), UiStyle.ACCENT, 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	title_label = UiStyle.label("", 18, UiStyle.ACCENT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title_label)
	subtitle_label = UiStyle.label("", 8, UiStyle.TEXT)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.custom_minimum_size = Vector2(270, 0)
	v.add_child(subtitle_label)
	buttons_box = VBoxContainer.new()
	v.add_child(buttons_box)


func show_main(can_continue: bool) -> void:
	mode = "main"
	title_label.text = "Kaixo!"
	subtitle_label.text = "Uma semana em Sarriguren.\nUm intercâmbio escolar Erasmus+, ao estilo Stardew.  Versão MVP."
	var items := []
	if can_continue:
		items.append(["Continuar a semana", continue_game])
	items.append(["Nova semana", new_game])
	items.append(["Sair", quit_app])
	_build(items)


func show_pause() -> void:
	mode = "pause"
	title_label.text = "%s, %s" % [GameState.day_name(), GameState.time_string()]
	subtitle_label.text = "Em pausa. O relógio espera por ti. A Arantxa não."
	_build([["Retomar", resume], ["Guardar", save], ["Guardar e voltar ao menu", quit_to_menu]])


func show_end(text: String) -> void:
	mode = "end"
	title_label.text = "Agur."
	subtitle_label.text = text
	_build([["Voltar ao menu", quit_to_menu]])


func _build(items: Array) -> void:
	for c in buttons_box.get_children():
		buttons_box.remove_child(c)
		c.queue_free()
	var first: Button = null
	for item in items:
		var b := UiStyle.button(str(item[0]), 10)
		var sig: Signal = item[1]
		b.pressed.connect(func() -> void: sig.emit())
		buttons_box.add_child(b)
		if first == null:
			first = b
	visible = true
	if first != null:
		first.grab_focus()
