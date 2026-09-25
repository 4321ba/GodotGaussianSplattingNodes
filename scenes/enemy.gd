extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var enemy_spawner = $"/root/MainScene/EnemySpawner"

@export var speed = 3.0
@export var max_health = 10.0
@export var damage_when_achieved_goal = 1
var health = 0


# --- Animation Configuration ---
@export_group("Visuals & Animation")
@export var use_explosion_death = true
@export var bob_speed: float = 12.0

# Assign these in the Inspector for each scene!
@export var heads_to_bob: Array[Node3D] # For Tanks/VTBs (Drag the head/turret here)
@export var body_to_bob: Node3D         # For Infantry (Drag the main mesh here)
@export var legs: Node3D                # [NEW] For Infantry: The single object containing both legs

var anim_time: float = 0.0

func distance_to_goal():
	return nav_agent.distance_to_target()

func _ready() -> void:
	health = max_health
	nav_agent.target_position = $"/root/MainScene/Goal".global_position


func _process(delta: float) -> void:
	# Only animate if moving
	#if velocity.length() > 0.1:
	anim_time += delta * bob_speed
	_animate_parts()
	#else:
	#	_reset_pose(delta)


var prev_velocity = Vector3(0,0,0)

func _physics_process(_delta: float) -> void:
	# If the agent is hopelessly lost (or fallen), snap them back to the mesh
	#if not nav_agent.is_target_reachable():
	#	var valid_point = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, global_position)
	#	global_position = valid_point
	
	var new_velocity: Vector3
	if enemy_spawner.map_changing:
		new_velocity = prev_velocity
	else:
		new_velocity = (nav_agent.get_next_path_position() - global_position).normalized() * speed
	
	#nav_agent.velocity = new_velocity
	velocity = new_velocity
	#print(enemy_spawner.map_changing, velocity)
	prev_velocity = velocity
	if velocity:
		look_at(global_position + velocity)
	move_and_slide()

func _on_navigation_agent_3d_target_reached() -> void:
	print("I've got in!")
	HealthAndMoney.i.remove_health(damage_when_achieved_goal)
	queue_free()


@onready var health_bar_red: Sprite3D = $HealthBar/Red

func take_damage(amount: float):
	health -= amount
	$GPUParticles3D.restart()
	
	# Clamp health to 0
	health = max(health, 0.0)
	
	# Calculate percentage (0.0 to 1.0)
	var health_percent = health / max_health
	
	# Update the scale
	# We tween it for a polished "smooth" drop effect
	var tween = create_tween()
	tween.tween_property(health_bar_red, "scale:x", health_percent, 0.2)
	
	if health <= 0:
		die()

var expl_scene = preload("res://scenes/explosion.tscn")

func die():
	HealthAndMoney.i.add_money(damage_when_achieved_goal)
	set_process(false)
	set_physics_process(false)
	remove_from_group("enemies")
	$CollisionShape3D.set_deferred("disabled", true)

	var mesh_to_animate = $MeshInstance3D
	
	var tween = create_tween()
	if use_explosion_death:
		var e = expl_scene.instantiate()
		get_tree().root.add_child(e)
		e.global_position = global_position
		
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(mesh_to_animate, "position:y", mesh_to_animate.position.y - 2.0, 0.5)
	else:
		$AudioStreamPlayer3D.play()
		# Optional: Use EASE_IN for the fall to make it feel heavy
		#tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		#tween.tween_property(mesh_to_animate, "rotation:z", deg_to_rad(-90), 0.3)
		# We run this after the previous tween finishes (implicitly chained)
		# We sink it by 1 meter relative to current position
		#tween.tween_property(mesh_to_animate, "position:y", mesh_to_animate.position.y - 1.0, 0.2)
		
		
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(mesh_to_animate, "rotation:z", deg_to_rad(-90), 0.3)
		
		# B. Slide Forward (Momentum)
		# We move the root node (self) forward by 0.5 meters to simulate skidding
		# Use EASE_OUT so friction slows it down
		var slide_dir = -global_transform.basis.z
		var slide_dest = global_position + (slide_dir * 1)
		tween.tween_property(self, "global_position", slide_dest, 0.5).set_ease(Tween.EASE_OUT)
		
		# PHASE 2: Sink into ground (Sequential)
		# .chain() waits for the previous parallel block to finish
		tween.chain().tween_property(mesh_to_animate, "position:y", mesh_to_animate.position.y - 1.0, 0.2)
		
	
	tween.finished.connect(queue_free) # audio finishes before this
	#await get_tree().create_timer(1.0).timeout
	#queue_free()



func _animate_parts():
	var sine_wave = sin(anim_time)
	var cosine_wave = cos(anim_time)
	
	# 1. Tank/VTB Head Bobbing
	if heads_to_bob.size() >= 1:
		heads_to_bob[0].position.y = abs(sin(anim_time/2)) * 0.05
		heads_to_bob[0].position.x = cos(anim_time/2) * 0.1
	if heads_to_bob.size() >= 2:
		heads_to_bob[1].position.y = abs(cos(anim_time/2)) * 0.05
		heads_to_bob[1].position.x = sin(anim_time/2) * 0.1
		
	# 2. Infantry Body Bobbing
	if body_to_bob:
		# Bounce logic
		var bounce = abs(sine_wave) 
		body_to_bob.position.y = bounce * 0.1
		body_to_bob.rotation.x = cosine_wave * 0.1

	# 3. [NEW] Infantry Leg Mirroring
	if legs:
		# We flip the legs every time the sine wave completes a half-cycle
		# Using sign() gives us 1.0 or -1.0 immediately
		legs.scale.z = -sign(sine_wave)

func _reset_pose(delta):
	var lerp_speed = delta * 5.0
	
	if body_to_bob:
		body_to_bob.position = body_to_bob.position.lerp(Vector3(0,0,0), lerp_speed)
		body_to_bob.rotation.x = lerp_angle(body_to_bob.rotation.x, 0.0, lerp_speed)
	
	if legs:
		# Reset scale to normal
		legs.scale.z = 1.0
