extends Camera3D

# Speed in radians per second
@export var rotation_speed: float = 2.0
@export var move_speed: float = 5.0

var prev_rot_speed = 0.0
var prev_move_speed = 0.0

func _process(delta: float) -> void:
	# Get input strength (-1 for left, +1 for right, 0 for neither)
	var input_dir = Input.get_axis("ui_left", "ui_right")
	prev_rot_speed = lerp(prev_rot_speed, input_dir * rotation_speed, 0.2)
	get_parent().rotate_y(prev_rot_speed * delta)
	
	var move_dir = Input.get_axis("ui_down", "ui_up")
	if -global_transform.basis.z.x < 0: # forward dir .x < 0 => we're facing -x more than +x
		move_dir *= -1
	prev_move_speed = lerp(prev_move_speed, move_dir * move_speed, 0.2)
	get_parent().position.x += (prev_move_speed * delta)
