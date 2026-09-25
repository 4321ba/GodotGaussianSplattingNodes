extends Node3D

@export var id: int = -1
# --- Configuration ---
@export_group("Stats")
@export var shooting_range: float = 6.0
@export var fire_rate: float = 0.5 # Shots per second
@export var damage: int = 3
@export var is_aoe: bool = false

@export_group("Visuals")
@export var turret_visuals: Node3D # Drag the rotating part (Turret) here
@export var impact_effect: PackedScene   # [NEW] Drag Explosion.tscn here (for Rocket towers)

@export_group("Grid Settings")
@export var walkable_tile_id: int = 0 # The ID of your Grass tile
@export var blocked_tile_id: int = 16  # The ID of your Foundation/Concrete tile

# --- State ---
var cooldown_timer: float = 0.0
var current_grid_pos: Vector3i

@onready var gridmap = $"/root/MainScene/GridMap"
@onready var particles = $GPUParticles3D

var range_indicator: MeshInstance3D

func _ready() -> void:
	$GPUParticles3D.reparent(turret_visuals)
	# If no specific part is assigned, rotate the whole tower
	#if not turret_visuals:
	#	turret_visuals = self
	_setup_range_indicator()

func _setup_range_indicator():
	range_indicator = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = shooting_range
	mesh.bottom_radius = shooting_range
	mesh.height = 0.1
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.484, 0.379, 0.251, 0.3) # Cyan, 30% visible
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	mesh.material = material
	range_indicator.mesh = mesh
	
	add_child(range_indicator)
	range_indicator.visible = false
	range_indicator.position.y = 0.1

var rotation_dir_target = Vector3()

func _physics_process(delta: float) -> void:
	# 1. Handle Cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# 2. Find Target
	var target = _get_best_target()
	
	if target:
		# 3. Rotate towards target
		rotation_dir_target = target.global_position
		
		# 4. Shoot
		if cooldown_timer <= 0:
			_shoot(target)
			
	if rotation_dir_target.length_squared() > 0.001:
		_rotate_turret(rotation_dir_target, delta)

func _get_best_target() -> Node3D:
	var best_enemy = null
	var shortest_dist_to_goal = INF
	
	# Get all enemies (Make sure your enemies are in this Group!)
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		# Check if in range
		var dist_to_tower = global_position.distance_to(enemy.global_position)
		if dist_to_tower > shooting_range:
			continue
		
		# Check priority: Closest to the Goal
		# (We assume enemies are simpler and use distance to end point)
		var dist_to_goal = enemy.distance_to_goal()
		
		if dist_to_goal < shortest_dist_to_goal:
			shortest_dist_to_goal = dist_to_goal
			best_enemy = enemy
			
	return best_enemy

var recoil_pitch: float = 0.0


func _rotate_turret(target_pos: Vector3, delta: float):
	# 1. Calculate the Target Angle
	# We create a temporary Basis looking at the target to get the correct angle
	var target_dir = target_pos - turret_visuals.global_position
	target_dir.y = 0 # Keep it flat
	
	if target_dir.length_squared() > 0.001:
		# Emulate "look_at" then "rotate 90"
		var target_basis = Basis.looking_at(target_dir, Vector3.UP)
		target_basis = target_basis.rotated(Vector3.UP, deg_to_rad(90))
		
		var target_rot_y = target_basis.get_euler().y
		
		# 2. Smoothly Interpolate (Tween) the Y angle
		var rotation_speed = 20
		turret_visuals.rotation.y = lerp_angle(turret_visuals.rotation.y, target_rot_y, delta * rotation_speed)
	
	# 3. Apply Recoil Pitch (X) and Lock Z
	turret_visuals.rotation.x = 0
	turret_visuals.rotation.z = recoil_pitch

func _shoot(target: Node3D):
	# Reset cooldown
	cooldown_timer = 1.0 / fire_rate
	
	# Visual feedback (optional print)
	#print("Bang! Killed ", target.name)
	
	# Kill logic
	if not is_aoe:
		target.take_damage(damage)
	else:
		var AOE_RANGE = 3.0
	# Get all enemies (Make sure your enemies are in this Group!)
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			var dist_to_target = target.global_position.distance_to(enemy.global_position)
			if dist_to_target <= AOE_RANGE:
				enemy.take_damage(damage * (AOE_RANGE - dist_to_target) / AOE_RANGE)
			
	particles.restart()
	$AudioStreamPlayer3D.play()
	
	if impact_effect:
		var impact = impact_effect.instantiate()
		get_tree().root.add_child(impact)
		impact.global_position = target.global_position
	
	var recoil_distance = 0.15
	var tween = create_tween()
	tween.set_parallel(true) # Do everything at once
	var back_vector = -turret_visuals.transform.basis.x * recoil_distance
	tween.tween_property(turret_visuals, "position", back_vector, 0.05)
	tween.tween_property(self, "recoil_pitch", deg_to_rad(10), 0.05) # Tilt up 20 degrees
	# .chain() waits for the previous parallel block to finish
	tween.chain().tween_property(turret_visuals, "position", Vector3(0,0,0), 0.15)
	tween.parallel().tween_property(self, "recoil_pitch", 0.0, 0.15)

# --- Placement Logic ---

func place_tower(grid_coord: Vector2i):
	# 1. Convert 2D grid coord to 3D grid coord (assuming Y=0 is floor)
	current_grid_pos = Vector3i(grid_coord.x, 0, grid_coord.y)
	
	# 2. Swap the tile in the GridMap to the "Blocked" version
	gridmap.set_cell_item(current_grid_pos, blocked_tile_id)
	
	# 4. Snap position visually to the center of the tile
	# (Assuming cell_size is 1.0, add 0.5 to center it)
	global_position = Vector3(2*grid_coord.x + 1, 0.3, 2*grid_coord.y + 1)

func remove_tower():
	# 1. Restore the tile to "Walkable"
	gridmap.set_cell_item(current_grid_pos, walkable_tile_id)
	HealthAndMoney.i.add_money(HealthAndMoney.tower_prices[id] * 0.8) # 80%: return from sell
	queue_free()

func _on_static_body_3d_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			remove_tower()


func _on_static_body_3d_mouse_entered() -> void:
	if range_indicator:
		range_indicator.visible = true


func _on_static_body_3d_mouse_exited() -> void:
	if range_indicator:
		range_indicator.visible = false
