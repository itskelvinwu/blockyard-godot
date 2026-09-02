extends Node
## Persistent tycoon session. Autoload.

signal changed

const SAVE_PATH := "user://blockyard_map1.json"
const BUILDERS_MAX := 2
const ENERGY_MAX := 100
const UPGRADE_KINDS := ["stove", "fridge", "table", "chair", "counter"]

var unlocked: PackedStringArray = ["kitchen", "dining", "foyer"]
var cash: int = 5200
var gems: int = 48
var energy: float = 80.0
var lot_level: int = 1
var upgrades := {"stove": 1, "fridge": 1, "table": 1, "chair": 1, "counter": 1}
var jobs: Array = []
var clock_min: float = 8.0 * 60.0
var panel: String = "none"
var focus_id: String = ""
var zoom: float = 32.0
var target := Vector2(8, 12)

func _ready() -> void:
	load_save()


func is_open(id: String) -> bool:
	return unlocked.has(id)


func is_building(id: String) -> bool:
	for j in jobs:
		if str(j.get("room_id", "")) == id:
			return true
	return false


func builders_free() -> int:
	return BUILDERS_MAX - jobs.size()


func upgrade_cost(tier: int) -> int:
	return int(round(180.0 * float(tier) * 1.35))


func lot_cost(level: int) -> int:
	return int(round(280.0 * float(level) * 1.45))


func next_cost(kind: String) -> int:
	var t: int = int(upgrades.get(kind, 1))
	if t >= 10:
		return 0
	return upgrade_cost(t)


func lot_next_cost() -> int:
	if lot_level >= 10:
		return 0
	return lot_cost(lot_level)


func bump(kind: String) -> bool:
	var t: int = int(upgrades.get(kind, 1))
	if t >= 10:
		return false
	var cost := upgrade_cost(t)
	if cash < cost or energy < 4.0:
		return false
	cash -= cost
	energy -= 4.0
	upgrades[kind] = t + 1
	persist()
	changed.emit()
	return true


func start_build(room_id: String, room_name: String, cost: int) -> String:
	if room_id == "lot":
		if lot_level >= 10:
			return "max"
		cost = lot_cost(lot_level)
	if is_open(room_id) or is_building(room_id):
		return "busy"
	if jobs.size() >= BUILDERS_MAX:
		return "builders"
	if cash < cost:
		return "cash"
	var duration := 14.0 + float(cost) * 0.008
	var job := {
		"id": "%s-%d" % [room_id, Time.get_ticks_msec()],
		"room_id": room_id,
		"name": room_name,
		"ends_at": Time.get_unix_time_from_system() + duration,
		"duration": duration,
		"skip_gems": maxi(8, int(round(float(cost) / 40.0))),
	}
	cash -= cost
	jobs.append(job)
	panel = "build"
	focus_id = str(job["id"])
	persist()
	changed.emit()
	return "ok"


func skip_job(id: String) -> bool:
	for j in jobs:
		if str(j.get("id", "")) != id:
			continue
		var g: int = int(j.get("skip_gems", 8))
		if gems < g:
			return false
		gems -= g
		_finish_job(j)
		jobs.erase(j)
		persist()
		changed.emit()
		return true
	return false


func tick(now: float, dt: float) -> void:
	clock_min = fmod(clock_min + dt * 2.0, 24.0 * 60.0)
	energy = minf(float(ENERGY_MAX), energy + dt * 0.08)
	var remain: Array = []
	var dirty := false
	for j in jobs:
		if float(j.get("ends_at", 0.0)) <= now:
			_finish_job(j)
			dirty = true
		else:
			remain.append(j)
	if dirty:
		jobs = remain
		persist()
		changed.emit()


func _finish_job(j: Dictionary) -> void:
	var rid := str(j.get("room_id", ""))
	if rid == "lot":
		lot_level = mini(10, lot_level + 1)
	elif not unlocked.has(rid):
		unlocked.append(rid)


func persist() -> void:
	var data := {
		"unlocked": unlocked,
		"cash": cash,
		"gems": gems,
		"energy": energy,
		"lot_level": lot_level,
		"upgrades": upgrades,
		"jobs": jobs,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	if d.has("unlocked"):
		unlocked = PackedStringArray(d["unlocked"])
	cash = int(d.get("cash", cash))
	gems = int(d.get("gems", gems))
	energy = float(d.get("energy", energy))
	lot_level = int(d.get("lot_level", lot_level))
	if d.has("upgrades"):
		upgrades = d["upgrades"]
	if d.has("jobs"):
		jobs = d["jobs"]
