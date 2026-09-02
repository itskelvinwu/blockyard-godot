class_name MapData
extends RefCounted
## Map 1 — Corner Diner. Same units as the web preview (meters, Y-up).


static func rooms() -> Array:
	return [
		_room("kitchen", "Kitchen", Vector2(-7, -1), Vector2(7, 7), Color("c5d2d6"), Color("e8eef0"), true, 0, [
			{"kind": "stove", "pos": Vector3(-5.4, 0, 1.2)},
			{"kind": "stove", "pos": Vector3(-5.4, 0, 2.6)},
			{"kind": "fridge", "pos": Vector3(-5.6, 0, 4.6)},
			{"kind": "counter", "pos": Vector3(-2.2, 0, 0.4)},
			{"kind": "shelf", "pos": Vector3(-1.4, 0, 5.4)},
		]),
		_room("dining", "Dining", Vector2(0, -1), Vector2(9, 7), Color("d7b48a"), Color("f3ece3"), true, 0, [
			{"kind": "table", "pos": Vector3(2.4, 0, 1.6)},
			{"kind": "chair", "pos": Vector3(2.4, 0, 2.5), "yaw": PI},
			{"kind": "chair", "pos": Vector3(2.4, 0, 0.7), "yaw": 0.0},
			{"kind": "table", "pos": Vector3(5.6, 0, 1.6)},
			{"kind": "chair", "pos": Vector3(5.6, 0, 2.5), "yaw": PI},
			{"kind": "chair", "pos": Vector3(5.6, 0, 0.7), "yaw": 0.0},
			{"kind": "table", "pos": Vector3(2.4, 0, 4.4)},
			{"kind": "chair", "pos": Vector3(2.4, 0, 5.3), "yaw": PI},
			{"kind": "chair", "pos": Vector3(2.4, 0, 3.5), "yaw": 0.0},
			{"kind": "table", "pos": Vector3(5.6, 0, 4.4)},
			{"kind": "chair", "pos": Vector3(5.6, 0, 5.3), "yaw": PI},
			{"kind": "chair", "pos": Vector3(5.6, 0, 3.5), "yaw": 0.0},
			{"kind": "host", "pos": Vector3(7.6, 0, 5.4)},
		]),
		_room("foyer", "Entrance", Vector2(2, 6), Vector2(5, 4), Color("c56a4a"), Color("f0e6dc"), true, 0, [
			{"kind": "planter", "pos": Vector3(3.0, 0, 8.6)},
			{"kind": "planter", "pos": Vector3(6.0, 0, 8.6)},
			{"kind": "host", "pos": Vector3(4.5, 0, 6.8)},
		]),
		_room("patio", "Patio", Vector2(-7, 6), Vector2(9, 5), Color("8ea36a"), Color("dfe6d4"), false, 650, [
			{"kind": "table", "pos": Vector3(-4.2, 0, 8.2)},
			{"kind": "chair", "pos": Vector3(-4.2, 0, 9.0), "yaw": PI},
			{"kind": "chair", "pos": Vector3(-4.2, 0, 7.4), "yaw": 0.0},
		]),
		_room("line", "More stoves", Vector2(-7, -6), Vector2(7, 5), Color("b7c4c8"), Color("e8eef0"), false, 900, [
			{"kind": "stove", "pos": Vector3(-5.4, 0, -3.6)},
			{"kind": "stove", "pos": Vector3(-5.4, 0, -2.2)},
		]),
		_room("storage", "Dry storage", Vector2(0, -6), Vector2(5, 5), Color("cbb892"), Color("efe6d6"), false, 480, [
			{"kind": "shelf", "pos": Vector3(1.2, 0, -4.4)},
			{"kind": "shelf", "pos": Vector3(3.4, 0, -4.4)},
		]),
		_room("restroom", "Restroom", Vector2(9, -1), Vector2(4, 5), Color("b9d0d4"), Color("eef4f5"), false, 520, [
			{"kind": "sink", "pos": Vector3(11.2, 0, 0.6)},
		]),
		_room("office", "Office", Vector2(9, 4), Vector2(4, 5), Color("7f8ea3"), Color("e4e8ee"), false, 740, [
			{"kind": "desk", "pos": Vector3(11.0, 0, 6.2)},
		]),
	]


static func _room(id: String, name: String, origin: Vector2, size: Vector2, floor: Color, wall: Color, start: bool, cost: int, props: Array) -> Dictionary:
	return {
		"id": id, "name": name, "origin": origin, "size": size,
		"floor": floor, "wall": wall, "start": start, "cost": cost, "props": props,
	}


static func stall_pos(i: int) -> Vector2:
	var col := i % 5
	var row := int(i / 5.0)
	return Vector2(17.2 + col * 2.7, 13.35 + row * 3.5)


static func stall_count(level: int) -> int:
	return clampi(level, 1, 10)
