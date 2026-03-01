@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "gsplat.ply.importer"

func _get_visible_name() -> String:
	return "Gaussian Splat (.ply)"

func _get_recognized_extensions() -> PackedStringArray:
	return ["ply"]

func _get_save_extension() -> String:
	return "res"

func _get_resource_type() -> String:
	return "Resource"

func _get_preset_count() -> int:
	return 1

func _get_preset_name(preset_index: int) -> String:
	return "Default"

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return []

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _get_import_order() -> int:
	return 0

func _get_priority() -> float:
	return 1.0

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> Error:
	var file := FileAccess.open(source_file, FileAccess.READ)
	if not file:
		return ERR_FILE_CANT_OPEN
	
	var properties : Array[StringName] = []
	var size := 0
	
	# Parse the header
	var line := file.get_line().split(' ')
	while not line[0] == 'end_header':
		line = file.get_line().split(' ')
		match line[0]:
			'format':   file.big_endian = line[1] == 'binary_big_endian'
			'element':  size = int(line[2])
			'property': properties.push_back(line[2])
	
	# Read binary vertices
	var vertices := file.get_buffer(size * len(properties) * 4).to_float32_array()
	
	# Format the properties to match the default layout
	if properties.hash() != SplatCloudData.DEFAULT_PROPERTIES.hash():
		var prop_inverse := {}
		for i in properties.size():
			prop_inverse[properties[i]] = i
		
		var new_vertices := PackedFloat32Array()
		new_vertices.resize(size * SplatCloudData.DEFAULT_PROP_CNT)
		
		for i in size:
			for pi in SplatCloudData.DEFAULT_PROP_CNT:
				if SplatCloudData.DEFAULT_PROPERTIES[pi] in prop_inverse:
					new_vertices[i * SplatCloudData.DEFAULT_PROP_CNT + pi] = vertices[i * len(properties) + prop_inverse[SplatCloudData.DEFAULT_PROPERTIES[pi]]]
				else:
					new_vertices[i * SplatCloudData.DEFAULT_PROP_CNT + pi] = 0.0
					
		properties = SplatCloudData.DEFAULT_PROPERTIES.duplicate()
		vertices = new_vertices

	# Create the resource and populate it
	var splat_data := SplatCloudData.new()
	splat_data.size = size
	splat_data.properties = properties
	splat_data.vertices = vertices
	splat_data.split = [] # Default to empty split
	
	# Save the resource to disk as a .res file
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(splat_data, filename)
