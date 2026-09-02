class_name BlockCar
extends Node3D
## Codigames-style box car. Wheels spin on the axle (X).

var paint := Color("c44c3a")
var wheel_spin: float = 0.0
var door_yaw: float = 0.0
var _wheels: Array[Node3D] = []
var _door: Node3D


func setup(p_paint: Color) -> void:
	paint = p_paint
	Kit.box(Vector3(0.95, 0.52, 1.9), paint, Vector3(0, 0.48, 0), self)
	Kit.box(Vector3(0.86, 0.4, 0.95), Color("1a2430"), Vector3(0, 0.92, 0.08), self)
	Kit.box(Vector3(0.7, 0.22, 0.08), Color("8ec4d8"), Vector3(0, 0.92, 0.5), self)
	_door = Node3D.new()
	_door.position = Vector3(-0.48, 0.55, 0.15)
	add_child(_door)
	Kit.box(Vector3(0.06, 0.42, 0.7), paint, Vector3(-0.02, 0.08, 0), _door)
	for xz in [Vector2(0.48, 0.6), Vector2(-0.48, 0.6), Vector2(0.48, -0.6), Vector2(-0.48, -0.6)]:
		var w := Node3D.new()
		w.position = Vector3(xz.x, 0.2, xz.y)
		add_child(w)
		var mesh := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.2
		cyl.bottom_radius = 0.2
		cyl.height = 0.14
		cyl.radial_segments = 10
		mesh.mesh = cyl
		mesh.rotation.z = PI / 2.0
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("141518")
		mesh.material_override = mat
		w.add_child(mesh)
		_wheels.append(w)


func _process(_dt: float) -> void:
	for w in _wheels:
		w.rotation.x = wheel_spin
	if _door:
		_door.rotation.y = -door_yaw
