extends StaticBody2D
## A person (or dog). Blocks movement; talking runs the first dialogue whose "if" passes.
## Map entity: {"type": "npc", "id": "iker", "name": "Iker", "color": "#hex", "x": 3, "y": 4,
##              "dialogues": [{"id": "iker_1", "if": {...}}, {"id": "iker_default"}],
##              "say": "fallback line", "shape": "person" | "dog"}

var data: Dictionary = {}
var color := Color.WHITE
var shape := "person"
@onready var name_label: Label = $NameLabel


func setup(d: Dictionary) -> void:
	data = d
	color = Color.html(str(d.get("color", "#cccccc")))
	shape = str(d.get("shape", "person"))
	name_label.text = str(d.get("name", ""))
	queue_redraw()


func _ready() -> void:
	name_label.position = Vector2(-32, -26)
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
	draw_circle(Vector2(0, 8), 5.0, Color(0, 0, 0, 0.25))
	if shape == "dog":
		draw_rect(Rect2(-6, 0, 12, 6), color)
		draw_rect(Rect2(4, -4, 5, 5), color)
		draw_rect(Rect2(-5, 6, 2, 3), color)
		draw_rect(Rect2(3, 6, 2, 3), color)
		draw_rect(Rect2(6, -3, 1, 1), Color.BLACK)
		return
	draw_rect(Rect2(-5, -4, 10, 12), color)
	draw_rect(Rect2(-3, 6, 2, 3), Color.html("#333333"))
	draw_rect(Rect2(1, 6, 2, 3), Color.html("#333333"))
	draw_circle(Vector2(0, -8), 5.0, Color.html("#e8b894"))
	draw_rect(Rect2(-5, -13, 10, 4), color.darkened(0.5))
	draw_rect(Rect2(-2, -8, 1, 1), Color.BLACK)
	draw_rect(Rect2(1, -8, 1, 1), Color.BLACK)
