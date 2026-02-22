extends Node3D

@onready var splat := $SplatMesh
@onready var splat2 := $SplatMesh2
@onready var cam := $Camera3D

var angle := 0.0
var radius := 1.0
var speed := 0.5

func _process(delta):
	angle += speed * delta

	# --- SplatMesh: move in circle + face forward ---
	var x = cos(angle) * radius
	var z = sin(angle) * radius
	splat.position = Vector3(x, splat.position.y, z)

	# Face movement direction (tangent of circle)
	var forward_dir = -Vector3(-sin(angle), 0, cos(angle)).normalized()
	splat.look_at(splat.position + forward_dir, Vector3.UP)

	# --- SplatMesh2: rotate in place, opposite direction, slower ---
	splat2.rotate_y(-speed * 0.6 * delta)

	# --- Camera forward/back movement ---
	var cam_speed = 2.0
	var move_input = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	var move_input2 = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	cam.translate(Vector3(move_input2 * cam_speed * delta, 0, -move_input * cam_speed * delta))
