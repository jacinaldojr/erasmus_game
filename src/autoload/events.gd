extends Node
## Global signal bus + input map setup. Systems talk through here so scenes stay decoupled.

signal time_changed(day: int, minutes: int)
signal energy_changed(value: int)
signal battery_changed(value: int)
signal stamp_earned(stamp_id: String)
signal word_learned(word: String)
signal flag_set(key: String)
signal friendship_changed(who: String, value: int)
signal item_changed(item_id: String, count: int)
signal notify(text: String)
signal ui_lock_changed(locked: bool)
signal map_change_requested(map_id: String, spawn_id: String)
signal location_changed(map_name: String)
signal day_ended(day: int, diary_text: String)
signal day_started(day: int)
signal message_received(sender: String, text: String)
signal plot_changed(plot_id: String)

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
	"passport": [KEY_TAB],
	"phone": [KEY_P],
	"menu": [KEY_ESCAPE],
	"translate": [KEY_T],
}


func _init() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
