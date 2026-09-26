class_name Prop
extends Node2D
## A y-sorted scenery sprite cut from the Lakiiah atlases (tree, house, bush...) with an optional
## static collider. The sprite's bottom edge sits on the bottom of the anchor cell, so a tree at
## cell (x, y) has its trunk in that cell and its canopy over the cells above.
## Map entity: {"type": "prop", "sprite": "house_red", "x": 7.5, "y": 6}   (fractional x/y allowed)

const GROUND_TEX := MapBuilder.GROUND_TEX
const HOUSE_TEX := MapBuilder.HOUSE_TEX

const SPECS := {
	"tree": {"tex": GROUND_TEX, "region": Rect2(208, 64, 32, 48), "solid": Rect2(-5, -2, 10, 9)},
	"bush": {"tex": GROUND_TEX, "region": Rect2(160, 64, 16, 16), "solid": Rect2(-7, -6, 14, 12)},
	"rock": {"tex": GROUND_TEX, "region": Rect2(176, 80, 16, 16), "solid": Rect2(-7, -5, 14, 10)},
	"house_red": {"tex": HOUSE_TEX, "region": Rect2(128, 48, 64, 64), "solid": Rect2(-32, -54, 64, 60)},
	"house_teal": {"tex": HOUSE_TEX, "region": Rect2(48, 16, 64, 96), "solid": Rect2(-32, -86, 64, 92)},
	"signpost": {"tex": HOUSE_TEX, "region": Rect2(128, 16, 16, 16), "solid": Rect2(-4, -2, 8, 8)},
	"barrel": {"tex": HOUSE_TEX, "region": Rect2(160, 16, 16, 16), "solid": Rect2(-6, -6, 12, 12)},
}

var sprite_id := ""


func setup(d: Dictionary) -> void:
	sprite_id = str(d.get("sprite", ""))
	if not SPECS.has(sprite_id):
		push_warning("Unknown prop sprite: " + sprite_id)
		return
	var spec: Dictionary = SPECS[sprite_id]
	var region: Rect2 = spec["region"]
	var s := Sprite2D.new()
	s.texture = load(spec["tex"])
	s.region_enabled = true
	s.region_rect = region
	s.centered = true
	s.offset = Vector2(0, MapBuilder.TILE / 2.0 - region.size.y / 2.0)
	add_child(s)
	if spec.has("solid"):
		var rect: Rect2 = spec["solid"]
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.position + rect.size / 2.0
		body.add_child(shape)
		add_child(body)
