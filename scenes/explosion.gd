extends GPUParticles3D

func _ready() -> void:
	emitting = true
	$AudioStreamPlayer3D.play()
	
	# Wait for the particles to finish, then delete the node
	await get_tree().create_timer(2.2).timeout
	queue_free()
