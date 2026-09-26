extends Area2D
## A walk-over-able place you can examine: canteen counter, classroom, basketball hoop, kitchen.
## Same dialogue routing as an NPC, drawn as a labelled marker.
## Map entity: {"type": "spot", "name": "Canteen", "color": "#hex", "x": 3, "y": 4, "dialogues": [...]}

var data: Dictionary = {}
var color := Color.WHITE
@onready var name_label: Label = $NameLabel


func setup(d: Dictionary) -> void:
	data = d
	color = Color.html(str(d.get("color", "#ffd617")))
	name_label.text = str(d.get("name", ""))
	queue_redraw()


func _ready() -> void:
	name_label.position = Vector2(-32, -22)
	name_label.size = Vector2(64, 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 7)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 2)


func interact(_player: Node) -> void:
	var opt := Conditions.first_match(data.get("dialogues", []))
	if not opt.is_empty():
		DialogueRunner.start(str(opt["id"]))
	elif data.has("say"):
		DialogueRunner.start_line(str(data.get("name", "")), str(data["say"]), str(data.get("translation", "")))


func _draw() -> void:
	draw_rect(Rect2(-7, -7, 14, 14), color.darkened(0.3))
	draw_rect(Rect2(-5, -5, 10, 10), color)
	draw_rect(Rect2(-1, -3, 2, 4), Color.BLACK)
	draw_rect(Rect2(-1, 2, 2, 1), Color.BLACK)
