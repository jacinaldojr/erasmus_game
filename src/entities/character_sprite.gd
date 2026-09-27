class_name CharacterSprite
extends Sprite2D
## Animated character from a 32x32 "idle-run" sheet: 6 columns x 16 rows.
## Rows 0-7 idle, rows 8-15 run; direction order S, SW, W, NW, N, NE, E, SE.
## Optional recolouring (exact hex -> hex) lets one sheet serve several characters.

const COLS := 6
const ROWS := 16
const RUN_FPS := 9.0
const IDLE_FPS := 4.0
const FEET_OFFSET := Vector2(0, -7)   # sprite bottom lands on the body's feet (y = +9)

static var _cache: Dictionary = {}

var moving := false
var facing := Vector2.DOWN
var _time := 0.0


func setup(sheet: String, recolor: Dictionary = {}) -> void:
	texture = load_sheet(sheet, recolor)
	hframes = COLS
	vframes = ROWS
	centered = true
	offset = FEET_OFFSET
	_time = randf() * 10.0
	_apply()


func _process(delta: float) -> void:
	_time += delta
	_apply()


func _apply() -> void:
	if texture == null:
		return
	var row := direction_row(facing) + (8 if moving else 0)
	var fps := RUN_FPS if moving else IDLE_FPS
	var col := int(_time * fps) % COLS
	frame = row * COLS + col


static func direction_row(v: Vector2) -> int:
	if v == Vector2.ZERO:
		return 0
	var a := atan2(v.x, v.y)  # 0 = down, clockwise negative
	var idx := roundi(a / (PI / 4.0)) % 8
	if idx < 0:
		idx += 8
	return idx


static func load_sheet(path: String, recolor: Dictionary) -> Texture2D:
	var key := path + JSON.stringify(recolor)
	if _cache.has(key):
		return _cache[key]
	var base: Texture2D = load(path)
	if base == null:
		push_error("Missing character sheet: " + path)
		return null
	if recolor.is_empty():
		_cache[key] = base
		return base
	var img: Image = base.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var map := {}
	for k in recolor:
		map[Color.html(str(k)).to_html(false)] = Color.html(str(recolor[k]))
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				var h := c.to_html(false)
				if map.has(h):
					img.set_pixel(x, y, Color(map[h], c.a))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex
