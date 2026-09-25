@tool
extends Node3D

# Drag your 1x256 color palette PNG here
@export var palette_texture: Texture2D

@export var align_meshes_to_floor: bool = false:
	set(value):
		align_meshes_to_floor = value
		if value:
			_perform_alignment()
			set_deferred("align_meshes_to_floor", false)

func _perform_alignment():
	#print(NavigationServer3D.map_get_edge_connection_margin($Grass/NavigationRegion3D.get_navigation_map()))
	print("Starting alignment & material fix...")
	var count = 0
	
	# Create the material once to share it (efficient)
	var shared_material = StandardMaterial3D.new()
	if palette_texture:
		shared_material.albedo_texture = palette_texture
		# "Nearest" is crucial for voxel art to stay crisp
		shared_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		# Ensure we don't get weird specular shiny spots on voxels
		shared_material.roughness = 1.0 
		shared_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	
	for child in get_children():
		if child is MeshInstance3D and child.mesh:
			
			# 1. ALIGNMENT (Move Pivot to Bottom)
			var aabb = child.mesh.get_aabb()
			child.position.y = aabb.size.y / 2.0
			
			# 2. APPLY TEXTURE (To the Mesh Resource itself)
			# We apply it to the Mesh resource, not the node override, 
			# so the MeshLibrary exporter definitely picks it up.
			if palette_texture:
				child.mesh.surface_set_material(0, shared_material)
			
			# Mark scene as dirty
			if child.owner:
				child.owner = get_tree().edited_scene_root 
			
			count += 1
			
	if count > 0:
		print("Success: Aligned and Textured ", count, " meshes.")
	else:
		print("Warning: No meshes found.")
