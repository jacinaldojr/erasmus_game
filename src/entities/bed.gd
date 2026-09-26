extends Area2D
## Vinícius's bed at Unai's house. Sleeping ends the day (after dinner, or after 22:00).
## Map entity: {"type": "bed", "x": 2, "y": 2}


func setup(_d: Dictionary) -> void:
	queue_redraw()


func interact(_player: Node) -> void:
	if GameState.can_sleep():
		if GameState.day == 0:
			GameState.set_flag("fool_card")
		var reason := "Went to bed at %s." % GameState.time_string()
		GameState.end_day(reason)
	elif GameState.day == 0:
		DialogueRunner.start_line("", "Too early. Arantxa said dinner is at 21:30, and you are not sleeping on an empty stomach. Not tonight.")
	else:
		DialogueRunner.start_line("", "It is %s. Sleep after dinner, or after 22:00." % GameState.time_string())


func _draw() -> void:
	draw_rect(Rect2(-8, -12, 16, 24), Color.html("#8a5a2b"))
	draw_rect(Rect2(-7, -11, 14, 22), Color.html("#e9e2d0"))
	draw_rect(Rect2(-7, -2, 14, 13), Color.html("#c8433f"))
	draw_rect(Rect2(-5, -9, 10, 5), Color.WHITE)
