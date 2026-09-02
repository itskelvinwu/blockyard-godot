extends Node3D
## Fixed isometric tycoon camera. Drag to pan, pinch/wheel to zoom.

const ISO := Vector3(12, 11, 12)
@onready var cam: Camera3D = $Camera3D
var _dragging := false
var _last := Vector2.ZERO


func _ready() -> void:
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.near = 1.0
	cam.far = 220.0
	cam.size = Session.zoom
	_place()


func _process(dt: float) -> void:
	cam.size = lerpf(cam.size, Session.zoom, 1.0 - exp(-10.0 * dt))
	_place()


func _place() -> void:
	var t := Vector3(Session.target.x, 0.0, Session.target.y)
	cam.position = t + ISO.normalized() * 42.0
	cam.look_at(t, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_dragging = event.pressed
		_last = event.position
	elif event is InputEventScreenDrag:
		_pan(event.relative)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			_last = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			Session.zoom = clampf(Session.zoom * 1.08, 18.0, 90.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			Session.zoom = clampf(Session.zoom * 0.92, 18.0, 90.0)
	elif event is InputEventMouseMotion and _dragging:
		_pan(event.relative)


func _pan(rel: Vector2) -> void:
	var k := 0.028 * (70.0 / Session.zoom)
	var fwd := Vector3(-ISO.x, 0, -ISO.z).normalized()
	var right := Vector3(-fwd.z, 0, fwd.x)
	Session.target += Vector2(right.x * -rel.x * k + fwd.x * rel.y * k, right.z * -rel.x * k + fwd.z * rel.y * k)
	Session.target.x = clampf(Session.target.x, -22.0, 28.0)
	Session.target.y = clampf(Session.target.y, -14.0, 28.0)
