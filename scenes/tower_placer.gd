extends Node3D

@export var ray_length: float = 1000.0

# The ID of the tile we are allowed to build on (Grass)
@export var buildable_tile_id: int = 0 
@export var walkable_tile_id: int = 0
@export var show_debug_visuals: bool = true 
@export var grid_scale: int = 2 # The size of your grid blocks (2x2)


var tower_recon_scene = preload("res://scenes/towers/recon.tscn")
var tower_rocket_scene = preload("res://scenes/towers/rocket.tscn")
var tower_artillery_scene = preload("res://scenes/towers/artillery.tscn")
var tower_scenes = [tower_recon_scene, tower_rocket_scene, tower_artillery_scene]

@onready var debug_container = $DebugContainer
@onready var gridmap = $"/root/MainScene/GridMap"

# 0 = recon, 1 = rocket, 2 = artillery
var chosen_tower: int = 0

func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			chosen_tower = 0
			print("Selected Tower Type: 0")
		elif event.keycode == KEY_2:
			chosen_tower = 1
			print("Selected Tower Type: 1")
		elif event.keycode == KEY_3:
			chosen_tower = 2
			print("Selected Tower Type: 2")
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _handle_click(screen_position: Vector2) -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	# 1. Create a Raycast from the camera
	var from = camera.project_ray_origin(screen_position)
	var to = from + camera.project_ray_normal(screen_position) * ray_length
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	# Ensure collision mask matches your GridMap's collision layer (default is 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		
		# 2. Check if we hit the GridMap
		if collider is GridMap:
			var grid_map = collider
			
			# 3. Calculate Grid Coordinates
			# We subtract a tiny amount from the normal to get the coordinate INSIDE the block we hit.
			# (If we added to the normal, we would get the empty space above the block)
			var point_in_block = result.position - (result.normal * 0.05)
			var local_pos = grid_map.to_local(point_in_block)
			var map_coords = grid_map.local_to_map(local_pos)
			
			# 4. Check Tile Validity
			var tile_id = grid_map.get_cell_item(map_coords)
			
			if tile_id == buildable_tile_id:
				_try_place_tower(map_coords)



# --- Configuration ---
@export var map_size: Vector2i = Vector2i(20, 16) # Set this to match your grid size
@export var map_begin: Vector2i = Vector2i(-10, -8)
@onready var start_point: Node3D = $"/root/MainScene/EnemySpawner"
@onready var end_point: Node3D = $"/root/MainScene/Goal"

# --- The Self-Contained Check ---
func can_place_tower_astar(target_cell: Vector3i) -> bool:
	# 1. Create a temporary AStar grid
	var temp_astar = AStarGrid2D.new()
	
	# FIX: Set the region to cover the negative coordinates too!
	# Rect2i takes (TopLeft X, TopLeft Y, Width, Height)
	var region_width = map_size.x - map_begin.x
	var region_height = map_size.y - map_begin.y
	temp_astar.region = Rect2i(map_begin.x, map_begin.y, region_width, region_height)
	
	temp_astar.cell_size = Vector2(grid_scale, grid_scale)
	temp_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	temp_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	temp_astar.update() 

	# 2. Convert Start/End to Grid Coords
	# FIX: We divide by grid_scale (2) to convert World->Grid. 
	# We DO NOT need to subtract map_begin because our Region now handles coordinates like -10 natively.
	var start_grid = Vector2i(floor(start_point.global_position.x / grid_scale), floor(start_point.global_position.z / grid_scale))
	var end_grid = Vector2i(floor(end_point.global_position.x / grid_scale), floor(end_point.global_position.z / grid_scale))

	# 3. Iterate ONLY the relevant area
	for x in range(map_begin.x, map_size.x):
		for y in range(map_begin.y, map_size.y):
			var pos = Vector3i(x, 0, y)
			var tile_id = gridmap.get_cell_item(pos)
			
			var is_obstacle = (tile_id != walkable_tile_id)
			var is_target_spot = (pos == target_cell)
			
			if is_obstacle or is_target_spot:
				# Check bounds safely
				if temp_astar.region.has_point(Vector2i(x, y)):
					temp_astar.set_point_solid(Vector2i(x, y), true)

	# 4. Check the path
	var path = temp_astar.get_id_path(start_grid, end_grid)
	
	# --- VISUALIZATION ---
	if show_debug_visuals:
		_draw_debug_visuals(temp_astar, path)
	# ---------------------
	
	return not path.is_empty()

func _draw_debug_visuals(astar: AStarGrid2D, path: Array[Vector2i]):
	# 1. Clear ONLY the debug markers (not the towers!)
	for child in debug_container.get_children():
		child.queue_free()
		
	# 2. Setup Meshes
	var cube_mesh = BoxMesh.new()
	# Scale visuals to match grid_scale (slightly smaller for gaps)
	cube_mesh.size = Vector3(grid_scale * 0.9, 0.4, grid_scale * 0.9)
	
	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color(1, 0, 0, 0.5)
	red_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cube_mesh.material = red_mat
	
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = grid_scale * 0.2
	sphere_mesh.height = grid_scale * 0.4
	
	var green_mat = StandardMaterial3D.new()
	green_mat.albedo_color = Color(0, 1, 0, 0.8)
	green_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere_mesh.material = green_mat

	# 3. Draw Solids (Red Boxes)
	for x in range(map_begin.x, map_size.x):
		for y in range(map_begin.y, map_size.y):
			if astar.is_point_solid(Vector2i(x, y)):
				var node = MeshInstance3D.new()
				node.mesh = cube_mesh
				# FIX: Calculate center position for 2x2 grid
				# Formula: (Index * Scale) + (Half Scale)
				var world_x = (x * grid_scale) + (grid_scale / 2.0)
				var world_z = (y * grid_scale) + (grid_scale / 2.0)
				node.position = Vector3(world_x, 1.0, world_z)
				debug_container.add_child(node)

	# 4. Draw Path (Green Dots)
	for point in path:
		var node = MeshInstance3D.new()
		node.mesh = sphere_mesh
		var world_x = (point.x * grid_scale) + (grid_scale / 2.0)
		var world_z = (point.y * grid_scale) + (grid_scale / 2.0)
		node.position = Vector3(world_x, 1.5, world_z)
		debug_container.add_child(node)


# --- [NEW] Enemy Proximity Check ---
func has_enemy_near_cell(cell: Vector3i, radius: float = 1.5) -> bool:
	# Calculate the center of the grid cell in world space
	# Formula: (Index * Scale) + (Half Scale)
	var world_x = (cell.x * grid_scale) + (grid_scale / 2.0)
	var world_z = (cell.z * grid_scale) + (grid_scale / 2.0)
	var cell_center = Vector3(world_x, 0, world_z)
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		# Check horizontal distance (ignoring Y height differences)
		var dist = Vector2(enemy.global_position.x, enemy.global_position.z).distance_to(Vector2(cell_center.x, cell_center.z))
		if dist < radius:
			return true
	return false


func _try_place_tower(map_coords: Vector3i):
	# 1. Check Enemy Proximity (using GameManager)
	if has_enemy_near_cell(map_coords, 1.5):
		print("Cannot place: Enemy too close!")
		return

	# 2. Check Path (using GameManager)
	if not can_place_tower_astar(map_coords):
		print("Cannot place: Blocks path!")
		return
		
	# 3. Check & Subtract Money (using HealthAndMoney Singleton as 'i')
	var price = HealthAndMoney.tower_prices[chosen_tower]
	if HealthAndMoney.i.remove_money(price):
		# Success! Spawn the tower
		if chosen_tower < tower_scenes.size() and tower_scenes[chosen_tower]:
			var new_tower = tower_scenes[chosen_tower].instantiate()
			add_child(new_tower)
			new_tower.place_tower(Vector2i(map_coords.x, map_coords.z))
		else:
			print("Error: No tower scene assigned for index ", chosen_tower)
