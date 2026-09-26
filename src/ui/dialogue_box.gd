class_name DialogueBox
extends PanelContainer
## Bottom panel driven by DialogueRunner: speaker, line, numbered choices, phone-translate button.

var speaker_label: Label
var text_label: RichTextLabel
var choices_box: VBoxContainer
var translate_button: Button
var hint_label: Label
var _choice_count := 0


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 16
	offset_right = -16
	offset_top = -128
	offset_bottom = -20
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_theme_stylebox_override("panel", UiStyle.panel_box(UiStyle.BG, UiStyle.ACCENT, 10))

	var v := VBoxContainer.new()
	add_child(v)
	speaker_label = UiStyle.label("", 11, UiStyle.ACCENT)
	v.add_child(speaker_label)
	text_label = UiStyle.rich(10)
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(text_label)
	choices_box = VBoxContainer.new()
	v.add_child(choices_box)
	var bottom := HBoxContainer.new()
	v.add_child(bottom)
	hint_label = UiStyle.label("E / Enter: continue", 7, UiStyle.MUTED)
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hint_label)
	translate_button = UiStyle.button("", 8)
	translate_button.focus_mode = Control.FOCUS_NONE
	translate_button.pressed.connect(translate)
	bottom.add_child(translate_button)

	DialogueRunner.line_changed.connect(_on_line)
	DialogueRunner.finished.connect(_on_finished)


func _on_line(speaker: String, text: String, choices: Array, translation: String) -> void:
	visible = true
	speaker_label.text = speaker
	speaker_label.visible = speaker != ""
	text_label.text = text
	for c in choices_box.get_children():
		choices_box.remove_child(c)
		c.queue_free()
	_choice_count = choices.size()
	for i in choices.size():
		var b := UiStyle.button("%d.  %s" % [i + 1, str(choices[i].get("text", "..."))], 9)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(DialogueRunner.choose.bind(i))
		choices_box.add_child(b)
	if _choice_count > 0:
		(choices_box.get_child(0) as Button).grab_focus()
	translate_button.visible = translation != ""
	translate_button.text = "[T] Phone translate  (-%d%% battery)" % GameState.TRANSLATOR_BATTERY_COST
	translate_button.disabled = not GameState.can_use_translator()
	hint_label.text = "E / Enter: continue" if _choice_count == 0 else "1-%d or click to choose" % _choice_count


func on_interact() -> void:
	DialogueRunner.advance()


func choose(index: int) -> void:
	if index < _choice_count:
		DialogueRunner.choose(index)


func translate() -> void:
	if not translate_button.visible:
		return
	var tr := DialogueRunner.translate_current()
	if tr != "":
		text_label.text += "\n[color=#9ad0ff][i]Phone: %s[/i][/color]" % tr
		translate_button.visible = false


func _on_finished(_id: String) -> void:
	visible = false
