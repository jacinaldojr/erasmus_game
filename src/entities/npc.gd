extends StaticBody2D
## A person (or dog). Blocks movement; talking runs the first dialogue whose "if" passes.
## People use an animated sheet from data/cast.json (key = "sprite", default = "id") and turn to
## face the player when spoken to. The dog is still drawn in code: the packs have no dog.
## Map entity: {"type": "npc", "id": "iker", "name": "Iker", "sprite": "iker", "x": 3, "y": 4,
##              "dialogues": [{"id": "iker_1", "if": {...}}, {"id": "iker_default"}],
##              "say": "fallback line", "shape": "person" | "dog", "facing": [0, 1]}

var data: Dictionary = {}
var color := Color.WHITE
var shape := "person"
var sprite: CharacterSprite
@onready var name_label: Label = $NameLabel


func setup(d: Dictionary) -> void:
	data = d
	color = Color.html(str(d.get("color", "#cccccc")))
	shape = str(d.get("shape", "person"))
	name_label.text = str(d.get("name", ""))
	if shape == "person":
		var cast := Content.cast_entry(str(d.get("sprite", d.get("id", ""))))
		if not cast.is_empty():
			sprite = CharacterSprite.new()
			sprite.setup(str(cast.get("sheet", "")), cast.get("recolor", {}))
			var f: Array = d.get("facing", [0, 1])
			sprite.facing = Vector2(float(f[0]), float(f[1]))
			add_child(sprite)
			move_child(sprite, 0)
			name_label.position.y = -36
	queue_redraw()


func _ready() -> void:
	name_label.position = Vector2(-32, -26)
	name_label.size = Vector2(64, 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 7)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 2)


func interact(player: Node) -> void:
	if sprite != null and player is Node2D:
		sprite.facing = (player as Node2D).global_position - global_position
	var opt := Conditions.first_match(data.get("dialogues", []))
	if not opt.is_empty():
		DialogueRunner.start(str(opt["id"]))
	elif data.has("say"):
		DialogueRunner.start_line(str(data.get("name", "")), str(data["say"]), str(data.get("translation", "")))


func _draw() -> void:
	if sprite != null:
		return
	draw_circle(Vector2(0, 8), 5.0, Color(0, 0, 0, 0.25))
	if shape == "dog":
		var outline := Color.html("#3a2a2a")
		draw_rect(Rect2(-7, -1, 14, 8), outline)
		draw_rect(Rect2(-6, 0, 12, 6), color)
		draw_rect(Rect2(3, -6, 7, 7), outline)
		draw_rect(Rect2(4, -5, 5, 5), color)
		draw_rect(Rect2(3, -7, 2, 3), outline)   # ear
		draw_rect(Rect2(-8, -3, 2, 4), outline)  # tail
		draw_rect(Rect2(-5, 6, 2, 3), outline)
		draw_rect(Rect2(3, 6, 2, 3), outline)
		draw_rect(Rect2(7, -3, 1, 1), Color.BLACK)
		draw_rect(Rect2(8, -2, 1, 1), Color.html("#c8433f"))  # nose
		return
	draw_rect(Rect2(-5, -4, 10, 12), color)
	draw_rect(Rect2(-3, 6, 2, 3), Color.html("#333333"))
	draw_rect(Rect2(1, 6, 2, 3), Color.html("#333333"))
	draw_circle(Vector2(0, -8), 5.0, Color.html("#e8b894"))
	draw_rect(Rect2(-5, -13, 10, 4), color.darkened(0.5))
	draw_rect(Rect2(-2, -8, 1, 1), Color.BLACK)
	draw_rect(Rect2(1, -8, 1, 1), Color.BLACK)
