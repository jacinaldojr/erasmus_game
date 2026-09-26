class_name Hud
extends Control
## Always-on overlay: day + clock, location, energy and battery bars, key hints, toast queue.

const TOAST_SECONDS := 3.0

var time_label: Label
var location_label: Label
var energy_bar: ProgressBar
var battery_bar: ProgressBar
var stamps_label: Label
var toast_label: Label
var _toasts: Array = []
var _toast_timer: Timer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var top_left := PanelContainer.new()
	top_left.add_theme_stylebox_override("panel", UiStyle.panel_box())
	top_left.position = Vector2(8, 8)
	var v := VBoxContainer.new()
	time_label = UiStyle.label("", 12, UiStyle.ACCENT)
	location_label = UiStyle.label("", 8, UiStyle.MUTED)
	v.add_child(time_label)
	v.add_child(location_label)
	top_left.add_child(v)
	add_child(top_left)

	var top_right := PanelContainer.new()
	top_right.add_theme_stylebox_override("panel", UiStyle.panel_box())
	top_right.position = Vector2(640 - 8 - 150, 8)
	top_right.custom_minimum_size = Vector2(150, 0)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_child(UiStyle.label("Energia", 8))
	energy_bar = UiStyle.bar(UiStyle.GOOD)
	grid.add_child(energy_bar)
	grid.add_child(UiStyle.label("Bateria", 8))
	battery_bar = UiStyle.bar(UiStyle.INFO)
	grid.add_child(battery_bar)
	grid.add_child(UiStyle.label("Carimbos", 8))
	stamps_label = UiStyle.label("0/12", 8, UiStyle.ACCENT)
	grid.add_child(stamps_label)
	top_right.add_child(grid)
	add_child(top_right)

	var hint := UiStyle.label("WASD mover   E falar   Tab passaporte   P telemóvel   Esc menu", 7, UiStyle.MUTED)
	hint.position = Vector2(8, 360 - 16)
	add_child(hint)

	toast_label = UiStyle.label("", 9, Color.WHITE)
	toast_label.position = Vector2(80, 300)
	toast_label.size = Vector2(480, 20)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_color_override("font_outline_color", Color.BLACK)
	toast_label.add_theme_constant_override("outline_size", 3)
	add_child(toast_label)

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(_next_toast)
	add_child(_toast_timer)

	Events.time_changed.connect(_on_time_changed)
	Events.location_changed.connect(func(n: String) -> void: location_label.text = n)
	Events.energy_changed.connect(func(v: int) -> void: energy_bar.value = v)
	Events.battery_changed.connect(func(v: int) -> void: battery_bar.value = v)
	Events.stamp_earned.connect(func(_id: String) -> void: _refresh_stamps())
	Events.notify.connect(notify)
	_on_time_changed(GameState.day, GameState.minutes)
	_refresh_stamps()


func _on_time_changed(_day: int, _minutes: int) -> void:
	time_label.text = "%s  %s" % [GameState.day_name(), GameState.time_string()]


func _refresh_stamps() -> void:
	stamps_label.text = "%d/12" % GameState.stamps.size()


func notify(text: String) -> void:
	_toasts.append(text)
	if _toast_timer.is_stopped():
		_next_toast()


func _next_toast() -> void:
	if _toasts.is_empty():
		toast_label.text = ""
		return
	toast_label.text = str(_toasts.pop_front())
	_toast_timer.start(TOAST_SECONDS)
