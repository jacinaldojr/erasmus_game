class_name UiStyle
extends RefCounted
## Tiny helpers so every code-built panel looks the same. Swap for a Theme resource later.

const BG := Color(0.07, 0.08, 0.12, 0.92)
const ACCENT := Color("#ffd617")
const TEXT := Color("#f2f2f2")
const MUTED := Color("#9aa3b2")
const GOOD := Color("#7ed957")
const INFO := Color("#5ac8fa")


static func panel_box(bg: Color = BG, border: Color = ACCENT, margin: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(margin)
	return sb


static func label(text: String, size: int = 10, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func rich(size: int = 10) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", TEXT)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r


static func button(text: String, size: int = 10) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	return b


static func bar(color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0
	b.max_value = 100
	b.value = 100
	b.show_percentage = false
	b.custom_minimum_size = Vector2(70, 8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	b.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	b.add_theme_stylebox_override("background", bg)
	return b
