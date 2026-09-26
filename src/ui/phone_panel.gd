class_name PhonePanel
extends PanelContainer
## Vinícius's phone: battery, inbox (Mom's "Já jantaste?", Dad's chess puzzle), Basque word list, pocket.

const ITEM_NAMES := {"seeds": "sementes de agrião", "cress": "agrião"}

var body: VBoxContainer


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(300, 0)
	add_theme_stylebox_override("panel", UiStyle.panel_box(Color(0.05, 0.05, 0.07, 0.97), UiStyle.INFO, 12))
	body = VBoxContainer.new()
	add_child(body)


func open() -> void:
	_refresh()
	visible = true


func close() -> void:
	visible = false


func _refresh() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	body.add_child(UiStyle.label("TELEMÓVEL   bateria %d%%   %s" % [GameState.battery, GameState.time_string()], 11, UiStyle.INFO))
	var translator_note := "App de tradução: -%d%% por uso. Cada palavra em basco que aprendes dá +%d%%." % [GameState.TRANSLATOR_BATTERY_COST, GameState.WORD_BATTERY_BONUS]
	body.add_child(UiStyle.label(translator_note, 7, UiStyle.MUTED))
	body.add_child(UiStyle.label("Usaste o tradutor hoje: %s" % ("sim" if GameState.used_translator_today else "não"), 7, UiStyle.MUTED))

	body.add_child(UiStyle.label("MENSAGENS", 9, UiStyle.ACCENT))
	var inbox := UiStyle.rich(8)
	if GameState.messages.is_empty():
		inbox.text = "[color=#9aa3b2]Ainda não há mensagens. A mãe escreve às 20:00.[/color]"
	else:
		var lines := PackedStringArray()
		var recent: Array = GameState.messages.slice(maxi(0, GameState.messages.size() - 6))
		for m in recent:
			lines.append("[b]%s[/b] (%s %02d:%02d): %s" % [
				str(m.get("from", "?")),
				GameState.DAY_NAMES[clampi(int(m.get("day", 0)), 0, 6)].left(3),
				floori(int(m.get("minutes", 0)) / 60.0), int(m.get("minutes", 0)) % 60,
				str(m.get("text", "")),
			])
		inbox.text = "\n".join(lines)
	body.add_child(inbox)

	body.add_child(UiStyle.label("EUSKERA  (%d/%d para o carimbo)" % [GameState.words.size(), GameState.WORDS_FOR_STAMP], 9, UiStyle.ACCENT))
	var words := UiStyle.rich(8)
	if GameState.words.is_empty():
		words.text = "[color=#9aa3b2]Ainda nada. O Iker ensina de graça.[/color]"
	else:
		var parts := PackedStringArray()
		for w in GameState.words:
			parts.append("[b]%s[/b] = %s" % [Content.word_display(str(w)), Content.word_meaning(str(w))])
		words.text = "   ".join(parts)
	body.add_child(words)

	body.add_child(UiStyle.label("BOLSO", 9, UiStyle.ACCENT))
	var pocket := PackedStringArray()
	for item in GameState.inventory:
		pocket.append("%s x%d" % [ITEM_NAMES.get(str(item), str(item)), GameState.item_count(str(item))])
	body.add_child(UiStyle.label("(vazio)" if pocket.is_empty() else ", ".join(pocket), 8))
	body.add_child(UiStyle.label("P / Esc: fechar", 7, UiStyle.MUTED))
