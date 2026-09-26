class_name DiaryPanel
extends PanelContainer
## End-of-day page of "Viagens na Terra dos Outros". Confirming starts the next day.

signal confirmed

var title_label: Label
var text_label: RichTextLabel
var next_button: Button


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 40
	offset_right = -40
	offset_top = 24
	offset_bottom = -24
	add_theme_stylebox_override("panel", UiStyle.panel_box(Color("#f3ead6"), Color("#8a5a2b"), 16))
	var v := VBoxContainer.new()
	add_child(v)
	title_label = UiStyle.label("", 13, Color("#4a2e12"))
	v.add_child(title_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	text_label = UiStyle.rich(9)
	text_label.add_theme_color_override("default_color", Color("#2b1d12"))
	scroll.add_child(text_label)
	next_button = UiStyle.button("", 9)
	next_button.pressed.connect(confirm)
	v.add_child(next_button)


func open(day: int, text: String) -> void:
	title_label.text = "Viagens na Terra dos Outros  -  %s" % GameState.DAY_NAMES[clampi(day, 0, 6)]
	text_label.text = text
	next_button.text = "Sleep  (E / Enter)" if day < GameState.LAST_DAY else "Go home  (E / Enter)"
	visible = true
	next_button.grab_focus()


func confirm() -> void:
	if not visible:
		return
	visible = false
	confirmed.emit()
