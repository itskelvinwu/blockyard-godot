extends Node3D
## Diner, lot, street, city, connected walls, and traffic with following distance.

const LANE_E := 22.2
const LANE_W := 19.4
const ROAD_Z := (LANE_E + LANE_W) * 0.5
const DRIVE_X := 15.6
const AISLE_Z := 17.2
const FOYER := Vector2(5.4, 10.15)
const SIDEWALK_Z := 11.55
const WALL := 0.18
const WH := 2.22
const PLASTER := Color("f2ebe2")
const FRAME := Color("6a5040")
const CAP := Color("d8cbb8")

var _lot_holder: String = ""
var _rooms: Dictionary = {}
var _traffic: Array = []


func _ready() -> void:
	_ground()
	_rooms_build()
	_roads()
	_city()
	_spawn_staff()
	_spawn_traffic()
	Session.changed.connect(_on_session)


func _process(dt: float) -> void:
	Session.tick(Time.get_unix_time_from_system(), dt)
	for a in _traffic:
		_step_agent(a, dt)


func _on_session() -> void:
	_rooms_build()


func _ground() -> void:
	Kit.box(Vector3(80, 0.08, 80), Color("3e7d58"), Vector3(0, -0.06, 0), self)
	Kit.box(Vector3(19.5, 0.1, 15), Color("e4d9c8"), Vector3(1.75, -0.02, 3.5), self)


func _rooms_build() -> void:
	for child in _rooms.values():
		if is_instance_valid(child):
			child.queue_free()
	_rooms.clear()
	var open_rooms: Array = []
	for r in MapData.rooms():
		if Session.is_open(str(r["id"])):
			open_rooms.append(r)
	for r in MapData.rooms():
		var n := Node3D.new()
		n.name = r["id"]
		add_child(n)
		_rooms[r["id"]] = n
		var o: Vector2 = r["origin"]
		var s: Vector2 = r["size"]
		var cx := o.x + s.x * 0.5
		var cz := o.y + s.y * 0.5
		var open: bool = Session.is_open(r["id"])
		var busy: bool = Session.is_building(r["id"])
		if not open:
			Kit.box(Vector3(s.x - 0.08, 0.06, s.y - 0.08), Color("c4a070") if busy else Color("5a8a9a"), Vector3(cx, 0.04, cz), n)
			if not busy:
				Kit.sphere(0.42, Color("f4f1ea"), Vector3(cx, 1.15, cz), n)
			continue
		Kit.box(Vector3(s.x + 0.04, 0.06, s.y + 0.04), r["floor"], Vector3(cx, 0.07, cz), n)
		_room_walls(r, open_rooms, n)
		for p in r["props"]:
			_prop(p, n)
	for r in open_rooms:
		var b := _bounds(r)
		for p in [Vector2(b.x0, b.z0), Vector2(b.x1, b.z0), Vector2(b.x0, b.z1), Vector2(b.x1, b.z1)]:
			Kit.box(Vector3(WALL + 0.1, WH + 0.12, WALL + 0.1), Color("e4d8cc"), Vector3(p.x, 0.07 + (WH + 0.12) * 0.5, p.y), self)


func _bounds(r: Dictionary) -> Dictionary:
	var o: Vector2 = r["origin"]
	var s: Vector2 = r["size"]
	return {"x0": o.x, "z0": o.y, "x1": o.x + s.x, "z1": o.y + s.y}


func _overlap(a0: float, a1: float, b0: float, b1: float) -> Vector2:
	var lo := maxf(a0, b0)
	var hi := minf(a1, b1)
	return Vector2(lo, hi) if hi - lo > 0.2 else Vector2.ZERO


func _shares(room: Dictionary, dir: String, others: Array) -> Array:
	var r := _bounds(room)
	var hits: Array = []
	for o in others:
		if str(o["id"]) == str(room["id"]):
			continue
		var b := _bounds(o)
		var span := Vector2.ZERO
		if dir == "w" and absf(r.x0 - b.x1) < 0.06:
			span = _overlap(r.z0, r.z1, b.z0, b.z1)
		elif dir == "e" and absf(r.x1 - b.x0) < 0.06:
			span = _overlap(r.z0, r.z1, b.z0, b.z1)
		elif dir == "s" and absf(r.z0 - b.z1) < 0.06:
			span = _overlap(r.x0, r.x1, b.x0, b.x1)
		elif dir == "n" and absf(r.z1 - b.z0) < 0.06:
			span = _overlap(r.x0, r.x1, b.x0, b.x1)
		if span != Vector2.ZERO:
			hits.append({"lo": span.x, "hi": span.y, "id": str(o["id"])})
	return hits


func _punch(from: float, to: float, holes: Array) -> Array:
	var hs: Array = holes.duplicate()
	hs.sort_custom(func(a, b): return float(a.lo) < float(b.lo))
	var out: Array = []
	var c := from
	for h in hs:
		var lo := maxf(from, float(h.lo))
		var hi := minf(to, float(h.hi))
		if hi - lo <= 0.12:
			continue
		if lo > c + 0.08:
			out.append(Vector2(c, lo))
		c = maxf(c, hi)
	if to - c > 0.08:
		out.append(Vector2(c, to))
	return out


func _wall_run(parent: Node3D, along: String, at: float, a: float, b: float) -> void:
	var len := b - a
	if len < 0.08:
		return
	var mid := (a + b) * 0.5
	var y := 0.07 + WH * 0.5
	if along == "x":
		Kit.box(Vector3(len + 0.02, WH, WALL), PLASTER, Vector3(mid, y, at), parent)
		Kit.box(Vector3(len + WALL, 0.08, WALL + 0.08), CAP, Vector3(mid, 0.07 + WH + 0.04, at), parent)
	else:
		Kit.box(Vector3(WALL, WH, len + 0.02), PLASTER, Vector3(at, y, mid), parent)
		Kit.box(Vector3(WALL + 0.08, 0.08, len + WALL), CAP, Vector3(at, 0.07 + WH + 0.04, mid), parent)


func _door_frame(parent: Node3D, along: String, at: float, lo: float, hi: float) -> void:
	var mid := (lo + hi) * 0.5
	var width := hi - lo
	var jamb_h := 1.92
	if along == "x":
		Kit.box(Vector3(0.12, jamb_h, WALL + 0.06), FRAME, Vector3(lo, 0.07 + jamb_h * 0.5, at), parent)
		Kit.box(Vector3(0.12, jamb_h, WALL + 0.06), FRAME, Vector3(hi, 0.07 + jamb_h * 0.5, at), parent)
		Kit.box(Vector3(width + 0.16, 0.14, WALL + 0.08), FRAME, Vector3(mid, 0.07 + jamb_h + 0.07, at), parent)
	else:
		Kit.box(Vector3(WALL + 0.06, jamb_h, 0.12), FRAME, Vector3(at, 0.07 + jamb_h * 0.5, lo), parent)
		Kit.box(Vector3(WALL + 0.06, jamb_h, 0.12), FRAME, Vector3(at, 0.07 + jamb_h * 0.5, hi), parent)
		Kit.box(Vector3(WALL + 0.08, 0.14, width + 0.16), FRAME, Vector3(at, 0.07 + jamb_h + 0.07, mid), parent)


func _room_walls(room: Dictionary, open_rooms: Array, parent: Node3D) -> void:
	var r := _bounds(room)
	var edges := [
		{"dir": "w", "along": "z", "at": r.x0, "from": r.z0, "to": r.z1},
		{"dir": "e", "along": "z", "at": r.x1, "from": r.z0, "to": r.z1},
		{"dir": "s", "along": "x", "at": r.z0, "from": r.x0, "to": r.x1},
		{"dir": "n", "along": "x", "at": r.z1, "from": r.x0, "to": r.x1},
	]
	for e in edges:
		var hits := _shares(room, e.dir, open_rooms)
		var skip: Array = []
		var holes: Array = []
		for hit in hits:
			if str(room["id"]) > str(hit.id):
				skip.append({"lo": hit.lo, "hi": hit.hi})
			else:
				var mid := (hit.lo + hit.hi) * 0.5
				var half := minf(0.86, (hit.hi - hit.lo) * 0.5 - 0.18)
				holes.append({"lo": mid - half, "hi": mid + half})
		if str(room["id"]) == "foyer" and e.dir == "n":
			var mid := (e.from + e.to) * 0.5
			holes.append({"lo": mid - 1.17, "hi": mid + 1.17})
		var owned := _punch(e.from, e.to, skip)
		for seg in owned:
			var local: Array = []
			for h in holes:
				if h.lo < seg.y and h.hi > seg.x:
					local.append(h)
			for piece in _punch(seg.x, seg.y, local):
				_wall_run(parent, e.along, e.at, piece.x, piece.y)
		for h in holes:
			_door_frame(parent, e.along, e.at, h.lo, h.hi)


func _prop(p: Dictionary, parent: Node3D) -> void:
	var kind := str(p.get("kind", ""))
	var yaw := float(p.get("yaw", 0.0))
	var holder := Node3D.new()
	holder.position = Vector3(p["pos"].x, 0.1, p["pos"].z)
	holder.rotation.y = yaw
	parent.add_child(holder)
	match kind:
		"table":
			Kit.box(Vector3(1.1, 0.08, 1.1), Color("c4a070"), Vector3(0, 0.62, 0), holder)
			Kit.box(Vector3(0.12, 0.6, 0.12), Color("6a5040"), Vector3(0, 0.3, 0), holder)
		"chair":
			Kit.box(Vector3(0.42, 0.08, 0.42), Color("6a5040"), Vector3(0, 0.38, 0), holder)
			Kit.box(Vector3(0.42, 0.32, 0.08), Color("6a5040"), Vector3(0, 0.56, -0.17), holder)
		"stove":
			Kit.box(Vector3(0.9, 0.7, 0.7), Color("3a3e44"), Vector3(0, 0.4, 0), holder)
		"fridge":
			Kit.box(Vector3(0.7, 1.4, 0.6), Color("d0d6da"), Vector3(0, 0.7, 0), holder)
		"counter":
			Kit.box(Vector3(1.6, 0.7, 0.6), Color("8a6a48"), Vector3(0, 0.4, 0), holder)
		"host":
			Kit.box(Vector3(0.9, 1.05, 0.5), Color("3a2a22"), Vector3(0, 0.52, 0), holder)
		"planter":
			Kit.box(Vector3(0.5, 0.4, 0.5), Color("8a5a3a"), Vector3(0, 0.2, 0), holder)
			Kit.box(Vector3(0.36, 0.3, 0.36), Color("3d7a4a"), Vector3(0, 0.5, 0), holder)
		"shelf":
			Kit.box(Vector3(1.4, 1.4, 0.4), Color("8a6a48"), Vector3(0, 0.7, 0), holder)
		"sink":
			Kit.box(Vector3(0.8, 0.85, 0.5), Color("d0d6da"), Vector3(0, 0.42, 0), holder)
		"desk":
			Kit.box(Vector3(1.4, 0.08, 0.7), Color("6a5040"), Vector3(0, 0.72, 0), holder)
		_:
			pass


func _roads() -> void:
	var n := MapData.stall_count(Session.lot_level)
	Kit.box(Vector3(96, 0.08, 6.8), Color("4a4844"), Vector3(10, 0.0, ROAD_Z), self)
	Kit.box(Vector3(94, 0.02, 0.12), Color("e8d878"), Vector3(10, 0.05, ROAD_Z), self)
	Kit.box(Vector3(3.8, 0.06, 6.0), Color("5a5854"), Vector3(DRIVE_X, 0.0, 14.2), self)
	var cols := mini(5, n)
	var rows := ceili(float(n) / 5.0)
	var lot_w := cols * 2.7 + 2.4
	var lot_d := rows * 3.5 + 2.2
	var lot_x := 17.2 + ((cols - 1) * 2.7) * 0.5
	var lot_z := 13.35 + ((rows - 1) * 3.5) * 0.5 + 0.4
	Kit.box(Vector3(lot_w, 0.08, lot_d), Color("5c5a56"), Vector3(lot_x - 0.3, 0.01, lot_z), self)
	for i in n:
		var p := MapData.stall_pos(i)
		Kit.box(Vector3(2.2, 0.02, 0.06), Color("e8e0c8"), Vector3(p.x, 0.06, p.y + 1.4), self)
		Kit.box(Vector3(2.2, 0.02, 0.06), Color("e8e0c8"), Vector3(p.x, 0.06, p.y - 1.4), self)


func _city() -> void:
	var blocks := [
		Vector3(36, 0, 6), Vector3(37, 0, 14), Vector3(36, 0, -3), Vector3(38, 0, 28),
		Vector3(-20, 0, 4), Vector3(-21, 0, 12), Vector3(-19, 0, -5), Vector3(-20, 0, 28),
		Vector3(4, 0, 32), Vector3(13, 0, 32), Vector3(-6, 0, 32), Vector3(22, 0, 32),
		Vector3(4, 0, -16), Vector3(-6, 0, -16), Vector3(14, 0, -16), Vector3(24, 0, -16),
	]
	var cols := [
		Color("d8c4a8"), Color("c45c4a"), Color("6a8aa0"), Color("e8dcc0"),
		Color("e8dcc0"), Color("7a6aa0"), Color("4a7a62"), Color("c4784a"),
		Color("c4784a"), Color("d0c8bc"), Color("8aa0b4"), Color("b0a090"),
		Color("b0a090"), Color("d4b48a"), Color("6a7a8a"), Color("e8dcc8"),
	]
	for i in blocks.size():
		Kit.box(Vector3(5.0, 4.4, 4.2), cols[i], blocks[i] + Vector3(0, 2.2, 0), self)


func _spawn_staff() -> void:
	var chef := BlockCharacter.new()
	chef.setup(Color("e8c4a8"), Color("f4f1ea"), Color("2a3038"), "chef")
	chef.position = Vector3(-4.4, 0, 2.0)
	chef.rotation.y = PI / 2.0
	add_child(chef)
	var server := BlockCharacter.new()
	server.setup(Color("c49a78"), Color("2a5a9a"), Color("1a2430"))
	server.position = Vector3(3.2, 0, 4.4)
	server.walk_speed = 0.7
	add_child(server)
	server.set_meta("path", [Vector2(1.8, 4.8), Vector2(7.2, 4.8), Vector2(7.2, 2.6), Vector2(1.8, 2.6)])
	server.set_meta("pi", 0)


func _spawn_traffic() -> void:
	var paints := [Color("c44c3a"), Color("2a5a9a"), Color("4aaa7a"), Color("e08a62"), Color("e8c44a"), Color("eef1f4")]
	var n := MapData.stall_count(Session.lot_level)
	for i in n:
		var car := BlockCar.new()
		car.setup(paints[i % paints.size()])
		car.position = Vector3(-40.0, 0, LANE_E)
		car.rotation.y = PI / 2.0
		add_child(car)
		var guest := BlockCharacter.new()
		guest.setup(Color("e8c4a8"), paints[(i + 2) % paints.size()], Color("3a4650"))
		guest.visible = false
		add_child(guest)
		var stall := MapData.stall_pos(i)
		_traffic.append({
			"id": "d%d" % i, "car": car, "guest": guest, "stall": stall, "phase": "hold",
			"t": -1.5 - i * 8.0, "wp": 0, "gwp": 0, "in_car": true, "spd": 0.0,
		})
	var packs := [[-26.0, LANE_E, PI / 2.0], [-4.0, LANE_E, PI / 2.0], [18.0, LANE_E, PI / 2.0], [28.0, LANE_W, -PI / 2.0], [6.0, LANE_W, -PI / 2.0], [-16.0, LANE_W, -PI / 2.0]]
	for i in packs.size():
		var pack: Array = packs[i]
		var pc := BlockCar.new()
		pc.setup(paints[i % paints.size()])
		pc.position = Vector3(pack[0], 0, pack[1])
		pc.rotation.y = pack[2]
		add_child(pc)
		_traffic.append({"id": "p%d" % i, "car": pc, "pass": true, "lane": pack[1], "yaw": pack[2], "spd": 6.0})


func _in_junction(x: float, z: float) -> bool:
	return absf(x - DRIVE_X) < 3.0 and z > 17.4 and z < 23.6


func _junction_hot() -> bool:
	for a in _traffic:
		if a.get("pass", false):
			continue
		var c: Node3D = a["car"]
		if str(a["phase"]) in ["turn", "leave"] and _in_junction(c.position.x, c.position.z):
			return true
	return false


func _car_gap(self_id: String, x: float, z: float, yaw: float) -> float:
	var best := 16.0
	var sy := sin(yaw)
	var cy := cos(yaw)
	for a in _traffic:
		if str(a.get("id", "")) == self_id:
			continue
		if str(a.get("phase", "")) == "hold":
			continue
		var o: Node3D = a["car"]
		var dx := o.position.x - x
		var dz := o.position.z - z
		var along := dx * sy + dz * cy
		var lat := absf(dx * cy - dz * sy)
		if along > 0.35 and along < best and lat < 1.45:
			best = along
	return best


func _along(car: Node3D, a: Dictionary, pts: Array, spd: float, dt: float) -> bool:
	var budget := spd * dt
	while budget > 0.0001 and int(a["wp"]) < pts.size():
		var t: Vector2 = pts[int(a["wp"])]
		var dx := t.x - car.position.x
		var dz := t.y - car.position.z
		var dist := Vector2(dx, dz).length()
		if dist < 0.18:
			a["wp"] = int(a["wp"]) + 1
			continue
		var step := minf(budget, dist)
		car.position.x += (dx / dist) * step
		car.position.z += (dz / dist) * step
		car.rotation.y = lerp_angle(car.rotation.y, atan2(dx, dz), 1.0 - exp(-14.0 * dt))
		budget -= step
	a["spd"] = spd
	car.wheel_spin += absf(spd) * dt * 5.2
	return int(a["wp"]) >= pts.size()


func _take_lot(id: String) -> bool:
	if _lot_holder == id:
		return true
	if _lot_holder == "":
		_lot_holder = id
		return true
	return false


func _drop_lot(id: String) -> void:
	if _lot_holder == id:
		_lot_holder = ""


func _step_agent(a: Dictionary, dt: float) -> void:
	if a.get("pass", false):
		var car: Node3D = a["car"]
		var yaw: float = a["yaw"]
		car.rotation.y = yaw
		car.position.z = lerpf(car.position.z, a["lane"], 1.0 - exp(-10.0 * dt))
		var gap := _car_gap(str(a["id"]), car.position.x, car.position.z, yaw)
		var want := 6.0
		if _junction_hot():
			if yaw > 0.0 and car.position.x < DRIVE_X - 2.2 and car.position.x > DRIVE_X - 14.0:
				want = 0.0
			if yaw < 0.0 and car.position.x > DRIVE_X + 2.2 and car.position.x < DRIVE_X + 14.0:
				want = 0.0
		if gap < 2.5:
			want = 0.0
		elif gap < 5.2:
			want *= (gap - 2.5) / 2.7
		a["spd"] = lerpf(float(a["spd"]), want, 1.0 - exp(-6.0 * dt))
		car.position.x += sin(yaw) * float(a["spd"]) * dt
		car.wheel_spin += float(a["spd"]) * dt * 5.2
		if yaw > 0.0 and car.position.x > 44.0:
			car.position.x = -34.0
		if yaw < 0.0 and car.position.x < -34.0:
			car.position.x = 44.0
		return

	a["t"] = float(a["t"]) + dt
	var car: Node3D = a["car"]
	var guest: Node3D = a["guest"]
	var stall: Vector2 = a["stall"]
	var sx := stall.x
	var sz := stall.y
	var door := Vector2(sx - 1.15, sz)
	var id := str(a["id"])
	match str(a["phase"]):
		"hold":
			car.position = Vector3(-40, 0, LANE_E)
			car.rotation.y = PI / 2.0
			a["in_car"] = true
			if a["t"] > 0.0 and _take_lot(id):
				a["phase"] = "cruise"
				a["wp"] = 0
				car.position.x = -32.0
		"cruise":
			if _along(car, a, [Vector2(DRIVE_X - 6.5, LANE_E)], 5.6, dt):
				a["phase"] = "wait_turn"
		"wait_turn":
			a["spd"] = 0.0
			var clear := true
			for o in _traffic:
				if not o.get("pass", false):
					continue
				if absf(o["car"].position.x - DRIVE_X) < 8.0:
					clear = false
			if clear:
				a["phase"] = "turn"
				a["wp"] = 0
		"turn":
			if _along(car, a, [Vector2(DRIVE_X, LANE_E), Vector2(DRIVE_X, AISLE_Z), Vector2(sx, AISLE_Z), Vector2(sx, sz)], 4.0, dt):
				_drop_lot(id)
				a["phase"] = "unload"
				a["t"] = 0.0
		"unload":
			car.door_yaw = lerpf(car.door_yaw, 1.35, 1.0 - exp(-5.0 * dt))
			if a["t"] > 0.4 and a["in_car"]:
				a["in_car"] = false
				guest.position = Vector3(door.x, 0, door.y)
				a["gwp"] = 0
			if a["t"] > 0.75:
				a["phase"] = "walkin"
		"walkin":
			car.door_yaw = lerpf(car.door_yaw, 0.0, 1.0 - exp(-3.0 * dt))
			if _follow_person(guest, a, [Vector2(door.x, SIDEWALK_Z), Vector2(FOYER.x + 1.1, SIDEWALK_Z), FOYER], dt):
				a["phase"] = "dine"
				a["t"] = 0.0
				guest.walk_speed = 0.0
		"dine":
			if a["t"] > 3.2:
				a["phase"] = "walkout"
				a["gwp"] = 0
		"walkout":
			if _follow_person(guest, a, [Vector2(FOYER.x + 1.1, SIDEWALK_Z), Vector2(door.x, SIDEWALK_Z), door], dt):
				a["phase"] = "board"
				a["t"] = 0.0
		"board":
			car.door_yaw = lerpf(car.door_yaw, 1.35, 1.0 - exp(-5.0 * dt))
			if a["t"] > 0.55:
				a["in_car"] = true
				car.door_yaw = lerpf(car.door_yaw, 0.0, 1.0 - exp(-4.0 * dt))
				if car.door_yaw < 0.08 and _take_lot(id):
					a["phase"] = "leave"
					a["wp"] = 0
		"leave":
			car.door_yaw = 0.0
			if int(a["wp"]) == 2:
				var clear := true
				for o in _traffic:
					if not o.get("pass", false):
						continue
					if absf(o["car"].position.x - DRIVE_X) < 8.0:
						clear = false
				if not clear:
					a["spd"] = 0.0
					guest.visible = not a["in_car"]
					return
			if _along(car, a, [Vector2(sx, AISLE_Z), Vector2(DRIVE_X, AISLE_Z), Vector2(DRIVE_X, LANE_E), Vector2(44, LANE_E)], 3.6, dt):
				_drop_lot(id)
				car.position = Vector3(-40, 0, LANE_E)
				car.rotation.y = PI / 2.0
				a["phase"] = "hold"
				a["t"] = -5.0
				a["in_car"] = true
				a["wp"] = 0
	guest.visible = not a["in_car"]


func _follow_person(node: Node3D, a: Dictionary, pts: Array, dt: float) -> bool:
	var wp: int = int(a["gwp"])
	if wp >= pts.size():
		node.walk_speed = 0.0
		return true
	var t: Vector2 = pts[wp]
	var dx := t.x - node.position.x
	var dz := t.y - node.position.z
	var dist := Vector2(dx, dz).length()
	node.rotation.y = lerp_angle(node.rotation.y, atan2(dx, dz), 1.0 - exp(-11.0 * dt))
	if dist < 0.26:
		a["gwp"] = wp + 1
		return int(a["gwp"]) >= pts.size()
	node.walk_speed = 0.78
	node.position.x += sin(node.rotation.y) * 1.45 * dt
	node.position.z += cos(node.rotation.y) * 1.45 * dt
	return false
