class_name BlockCharacter
extends Node3D
## Low-poly staff / guest. Faces +Z. Walk via `walk_speed`.

var walk_speed: float = 0.0
var skin := Color("e8c4a8")
var torso := Color("c45c4a")
var legs := Color("3a4650")
var _phase: float = 0.0
var _larm: Node3D
var _rarm: Node3D
var _lleg: Node3D
var _rleg: Node3D
var _head: Node3D


func setup(p_skin: Color, p_torso: Color, p_legs: Color, hat: String = "") -> void:
	skin = p_skin
	torso = p_torso
	legs = p_legs
	Kit.box(Vector3(0.56, 0.55, 0.32), torso, Vector3(0, 1.05, 0), self)
	_head = Node3D.new()
	_head.position = Vector3(0, 1.42, 0)
	add_child(_head)
	Kit.sphere(0.26, skin, Vector3.ZERO, _head)
	if hat == "chef":
		Kit.box(Vector3(0.38, 0.18, 0.38), Color("f4f1ea"), Vector3(0, 0.28, 0), _head)
	elif hat == "cap":
		Kit.box(Vector3(0.4, 0.1, 0.4), torso, Vector3(0, 0.22, 0.02), _head)
	_larm = Node3D.new()
	_larm.position = Vector3(-0.34, 1.18, 0)
	add_child(_larm)
	Kit.capsule(0.07, 0.42, skin, Vector3(0, -0.22, 0), _larm)
	_rarm = Node3D.new()
	_rarm.position = Vector3(0.34, 1.18, 0)
	add_child(_rarm)
	Kit.capsule(0.07, 0.42, skin, Vector3(0, -0.22, 0), _rarm)
	_lleg = Node3D.new()
	_lleg.position = Vector3(-0.14, 0.62, 0)
	add_child(_lleg)
	Kit.capsule(0.08, 0.5, legs, Vector3(0, -0.22, 0), _lleg)
	_rleg = Node3D.new()
	_rleg.position = Vector3(0.14, 0.62, 0)
	add_child(_rleg)
	Kit.capsule(0.08, 0.5, legs, Vector3(0, -0.22, 0), _rleg)


func _process(dt: float) -> void:
	var moving := walk_speed > 0.08
	_phase = fmod(_phase + dt * (1.7 if moving else 0.25), 1.0)
	var s := sin(_phase * TAU)
	if _larm:
		_larm.rotation.x = (-0.45 if moving else 0.08) * s
		_rarm.rotation.x = (0.45 if moving else 0.08) * s
		_lleg.rotation.x = (0.5 if moving else 0.04) * s
		_rleg.rotation.x = (-0.5 if moving else 0.04) * s
	if _head and moving:
		_head.rotation.y = s * 0.18
		rotation.y += 0.0
