class_name Conditions
extends RefCounted
## Evaluates the small condition language used by dialogues and map entities.
## A condition is a Dictionary; every key must hold for it to pass. {} always passes.
##
##   {"flag": "met_unai"}                 {"not_flag": "met_unai"}
##   {"flag_today": "dinner_done"}        {"not_flag_today": "almuerzo"}
##   {"stamp": "almuerzo"}                {"not_stamp": "make_laugh"}
##   {"day": 1}  {"day_at_least": 1}      {"time_between": ["10:30", "11:30"]}
##   {"words_at_least": 3}                {"has_words": ["egun_on", "agur"]}
##   {"friendship_at_least": {"who": "iker", "value": 2}}
##   {"has_item": "seeds"}                {"energy_at_least": 20}  {"battery_at_least": 15}


static func check(cond: Dictionary) -> bool:
	for key in cond:
		var v = cond[key]
		var ok := true
		match key:
			"flag":
				ok = GameState.has_flag(str(v))
			"not_flag":
				ok = not GameState.has_flag(str(v))
			"flag_today":
				ok = GameState.has_flag_today(str(v))
			"not_flag_today":
				ok = not GameState.has_flag_today(str(v))
			"stamp":
				ok = GameState.has_stamp(str(v))
			"not_stamp":
				ok = not GameState.has_stamp(str(v))
			"day":
				ok = GameState.day == int(v)
			"day_at_least":
				ok = GameState.day >= int(v)
			"time_between":
				var from: int = Content.parse_time(v[0])
				var to: int = Content.parse_time(v[1])
				ok = GameState.minutes >= from and GameState.minutes < to
			"words_at_least":
				ok = GameState.words.size() >= int(v)
			"has_words":
				for w in v:
					if not GameState.knows_word(str(w)):
						ok = false
			"friendship_at_least":
				ok = GameState.get_friendship(str(v.get("who", ""))) >= int(v.get("value", 0))
			"has_item":
				ok = GameState.item_count(str(v)) > 0
			"energy_at_least":
				ok = GameState.energy >= int(v)
			"battery_at_least":
				ok = GameState.battery >= int(v)
			_:
				push_warning("Unknown condition key: " + str(key))
		if not ok:
			return false
	return true


static func first_match(options: Array) -> Dictionary:
	## Returns the first entry whose optional "if" passes, or {}.
	for opt in options:
		if opt is Dictionary and check(opt.get("if", {})):
			return opt
	return {}
