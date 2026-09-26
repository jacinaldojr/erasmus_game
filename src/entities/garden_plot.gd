extends Area2D
## One square of the school eco-garden. Plant cress seeds; it sprouts tomorrow and is ready the day after.
## Map entity: {"type": "plot", "id": "garden_1", "x": 11, "y": 14}

const CROP := "cress"
const SEED_ITEM := "seeds"

var plot_id := ""


func setup(d: Dictionary) -> void:
	plot_id = str(d.get("id", "plot_%d_%d" % [int(d.get("x", 0)), int(d.get("y", 0))]))
	Events.plot_changed.connect(_on_plot_changed)
	queue_redraw()


func _on_plot_changed(id: String) -> void:
	if id == plot_id:
		queue_redraw()


func interact(_player: Node) -> void:
	match GameState.plot_stage(plot_id):
		0:
			if GameState.item_count(SEED_ITEM) <= 0:
				DialogueRunner.start_line("", "Bare soil. You need seeds. Rafael is by the garden with a pocketful.")
				return
			GameState.remove_item(SEED_ITEM, 1)
			GameState.plant(plot_id, CROP)
			GameState.advance_time(10)
			if not GameState.has_flag("planted_first"):
				GameState.set_flag("planted_first")
				GameState.log_event("Planted cress in the IES Sarriguren eco-garden.")
			DialogueRunner.start_line("", "You plant the cress. Rafael says it sprouts tomorrow and is ready the day after. (Seeds left: %d)" % GameState.item_count(SEED_ITEM))
		1:
			DialogueRunner.start_line("", "Freshly planted. Nothing to see yet. Rafael says that is normal, and that you should stop staring at it.")
		2:
			DialogueRunner.start_line("", "Tiny green sprouts! Tomorrow they will be ready.")
		3:
			GameState.harvest(plot_id)
			GameState.add_item(CROP, 1)
			GameState.log_event("Harvested cress from the eco-garden.")
			DialogueRunner.start_line("", "You harvest a handful of cress. Arantxa will put it on the tortilla. (Cress: %d)" % GameState.item_count(CROP))


func _draw() -> void:
	draw_rect(Rect2(-7, -7, 14, 14), Color(0, 0, 0, 0.12))
	match GameState.plot_stage(plot_id):
		1:
			for p in [Vector2(-4, -3), Vector2(2, -4), Vector2(-2, 3), Vector2(4, 2)]:
				draw_rect(Rect2(p, Vector2(1, 1)), Color.html("#e9dca4"))
		2:
			for p in [Vector2(-4, -3), Vector2(2, -4), Vector2(-2, 3), Vector2(4, 2)]:
				draw_rect(Rect2(p, Vector2(2, 3)), Color.html("#7ed957"))
		3:
			for p in [Vector2(-5, -5), Vector2(1, -5), Vector2(-3, 1), Vector2(3, 1)]:
				draw_rect(Rect2(p, Vector2(4, 5)), Color.html("#3fa34d"))
				draw_rect(Rect2(p + Vector2(1, -1), Vector2(2, 2)), Color.html("#9ef07a"))
