extends Node
## Single source of truth for a run: clock, stats, flags, passport progress, inventory.
## Everything here is plain data so SaveManager can serialise it.

const DAY_NAMES := ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]
const LAST_DAY := 6
const DAY_START_MINUTES := 7 * 60
const DAY_END_MINUTES := 23 * 60 + 30
const SUNDAY_START_MINUTES := 19 * 60
const REAL_SECONDS_PER_GAME_MINUTE := 0.6
const ENERGY_DRAIN_EVERY_MINUTES := 15
const TRANSLATOR_BATTERY_COST := 15
const WORD_BATTERY_BONUS := 5
const WORDS_FOR_STAMP := 5

var day := 0
var minutes := SUNDAY_START_MINUTES
var energy := 100
var battery := 100
var flags := {}
var stamps: Array = []
var words: Array = []
var friendship := {}
var plots := {}        # plot_id -> {"crop": String, "planted_day": int}
var inventory := {}    # item_id -> count
var messages: Array = []  # phone inbox: {"day", "minutes", "from", "text"}
var day_log: Array = []   # what happened today; feeds the diary page
var used_translator_today := false
var current_map := "home"
var current_spawn := "start"

var clock_running := false
var ui_locks := 0
var _accumulator := 0.0


func _process(delta: float) -> void:
	if not clock_running or ui_locks > 0:
		return
	_accumulator += delta
	while _accumulator >= REAL_SECONDS_PER_GAME_MINUTE and clock_running:
		_accumulator -= REAL_SECONDS_PER_GAME_MINUTE
		advance_time(1)


func new_game() -> void:
	day = 0
	minutes = SUNDAY_START_MINUTES
	energy = 100
	battery = 100
	flags = {}
	stamps = []
	words = []
	friendship = {}
	plots = {}
	inventory = {}
	messages = []
	day_log = []
	used_translator_today = false
	current_map = "home"
	current_spawn = "start"
	clock_running = false
	ui_locks = 0
	_accumulator = 0.0
	_emit_all()


func _emit_all() -> void:
	Events.time_changed.emit(day, minutes)
	Events.energy_changed.emit(energy)
	Events.battery_changed.emit(battery)


# --- UI locking (dialogue, menus) pauses the clock and the player -------------

func lock_ui() -> void:
	ui_locks += 1
	Events.ui_lock_changed.emit(true)


func unlock_ui() -> void:
	ui_locks = maxi(0, ui_locks - 1)
	Events.ui_lock_changed.emit(ui_locks > 0)


func is_ui_locked() -> bool:
	return ui_locks > 0


# --- Clock ------------------------------------------------------------------

func day_name() -> String:
	return DAY_NAMES[clampi(day, 0, DAY_NAMES.size() - 1)]


func time_string() -> String:
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]


func advance_time(amount: int) -> void:
	if amount <= 0 or not clock_running:
		return
	var target := minutes + amount
	while minutes < target:
		minutes += 1
		if minutes % ENERGY_DRAIN_EVERY_MINUTES == 0:
			change_energy(-1)
		_on_minute(minutes)
		if minutes >= DAY_END_MINUTES:
			Events.time_changed.emit(day, minutes)
			end_day("Já passa das 23:30. Adormeceste de sapatos calçados.")
			return
	Events.time_changed.emit(day, minutes)


func _on_minute(m: int) -> void:
	if m == 20 * 60:
		receive_message("Mãe", Content.mom_text_for_day(day))
	elif m == 22 * 60:
		receive_message("Pai", Content.dad_text_for_day(day))
	elif m == 21 * 60 + 30 and not has_flag_today("dinner_done"):
		Events.notify.emit("21:30. Hora de jantar em casa do Unai.")


# --- Stats ------------------------------------------------------------------

func change_energy(delta: int) -> void:
	var before := energy
	energy = clampi(energy + delta, 0, 100)
	Events.energy_changed.emit(energy)
	if energy == 0 and before > 0:
		Events.notify.emit("Estás exausto. Arranja comida ou vai para a cama.")


func change_battery(delta: int) -> void:
	battery = clampi(battery + delta, 0, 100)
	Events.battery_changed.emit(battery)


func can_use_translator() -> bool:
	return battery >= TRANSLATOR_BATTERY_COST


func use_translator() -> bool:
	if not can_use_translator():
		Events.notify.emit("Bateria do telemóvel demasiado fraca para a app de tradução.")
		return false
	change_battery(-TRANSLATOR_BATTERY_COST)
	used_translator_today = true
	return true


# --- Flags, stamps, words, friendship, items ---------------------------------

func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value
	Events.flag_set.emit(key)


func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))


func today_key(key: String) -> String:
	return "%s_day%d" % [key, day]


func set_flag_today(key: String) -> void:
	set_flag(today_key(key))


func has_flag_today(key: String) -> bool:
	return has_flag(today_key(key))


func has_stamp(stamp_id: String) -> bool:
	return stamp_id in stamps


func earn_stamp(stamp_id: String) -> void:
	if has_stamp(stamp_id):
		return
	stamps.append(stamp_id)
	var label := Content.stamp_name(stamp_id)
	log_event("Carimbo no passaporte: %s" % label)
	Events.stamp_earned.emit(stamp_id)
	Events.notify.emit("Novo carimbo no passaporte: %s (%d/12)" % [label, stamps.size()])


func knows_word(word_id: String) -> bool:
	return word_id in words


func learn_word(word_id: String) -> void:
	if knows_word(word_id):
		return
	words.append(word_id)
	change_battery(WORD_BATTERY_BONUS)
	Events.word_learned.emit(word_id)
	Events.notify.emit("Nova palavra em basco: %s = %s" % [Content.word_display(word_id), Content.word_meaning(word_id)])
	log_event("Aprendi a palavra basca '%s' (%s)." % [Content.word_display(word_id), Content.word_meaning(word_id)])
	if words.size() >= WORDS_FOR_STAMP:
		earn_stamp("basque_5")


func get_friendship(who: String) -> int:
	return int(friendship.get(who, 0))


func change_friendship(who: String, delta: int) -> void:
	friendship[who] = clampi(get_friendship(who) + delta, 0, 10)
	Events.friendship_changed.emit(who, friendship[who])


func item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = item_count(item_id) + count
	Events.item_changed.emit(item_id, inventory[item_id])


func remove_item(item_id: String, count: int = 1) -> bool:
	if item_count(item_id) < count:
		return false
	inventory[item_id] = item_count(item_id) - count
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	Events.item_changed.emit(item_id, item_count(item_id))
	return true


func receive_message(sender: String, text: String) -> void:
	messages.append({"day": day, "minutes": minutes, "from": sender, "text": text})
	Events.message_received.emit(sender, text)
	Events.notify.emit("[Telemóvel] %s: %s" % [sender, text])


func log_event(text: String) -> void:
	day_log.append(text)


# --- Garden -------------------------------------------------------------------

func plot_stage(plot_id: String) -> int:
	## 0 empty, 1 just planted, 2 sprouting, 3 ready to harvest
	if not plots.has(plot_id):
		return 0
	var age: int = day - int(plots[plot_id].get("planted_day", day))
	if age <= 0:
		return 1
	if age == 1:
		return 2
	return 3


func plant(plot_id: String, crop: String) -> void:
	plots[plot_id] = {"crop": crop, "planted_day": day}
	Events.plot_changed.emit(plot_id)


func harvest(plot_id: String) -> String:
	var crop: String = plots.get(plot_id, {}).get("crop", "")
	plots.erase(plot_id)
	Events.plot_changed.emit(plot_id)
	return crop


# --- Day cycle ----------------------------------------------------------------

func can_sleep() -> bool:
	return has_flag_today("dinner_done") or minutes >= 22 * 60


func end_day(reason: String = "") -> void:
	if not clock_running:
		return
	clock_running = false
	_accumulator = 0.0
	if day >= 1 and not used_translator_today:
		earn_stamp("no_translator")
	var diary_text := Content.diary_for_day(day, day_log, reason)
	Events.day_ended.emit(day, diary_text)


func start_next_day() -> void:
	day += 1
	minutes = DAY_START_MINUTES
	energy = 100
	battery = 100
	used_translator_today = false
	day_log = []
	current_map = "home"
	current_spawn = "bed"
	clock_running = true
	_emit_all()
	Events.day_started.emit(day)


# --- Serialisation ------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"version": 1,
		"day": day, "minutes": minutes, "energy": energy, "battery": battery,
		"flags": flags, "stamps": stamps, "words": words, "friendship": friendship,
		"plots": plots, "inventory": inventory, "messages": messages, "day_log": day_log,
		"used_translator_today": used_translator_today,
		"current_map": current_map, "current_spawn": current_spawn,
	}


func from_dict(d: Dictionary) -> void:
	new_game()
	day = int(d.get("day", 0))
	minutes = int(d.get("minutes", SUNDAY_START_MINUTES))
	energy = int(d.get("energy", 100))
	battery = int(d.get("battery", 100))
	flags = d.get("flags", {})
	stamps = d.get("stamps", [])
	words = d.get("words", [])
	friendship = d.get("friendship", {})
	plots = d.get("plots", {})
	inventory = d.get("inventory", {})
	messages = d.get("messages", [])
	day_log = d.get("day_log", [])
	used_translator_today = bool(d.get("used_translator_today", false))
	current_map = str(d.get("current_map", "home"))
	current_spawn = str(d.get("current_spawn", "start"))
	_emit_all()
