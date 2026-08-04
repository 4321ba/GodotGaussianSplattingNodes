@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "gsplat.gltf.importer"

func _get_visible_name() -> String:
	return "Gaussian Splat (.gltf/.glb)"

func _get_recognized_extensions() -> PackedStringArray:
	return ["gltf", "glb"]

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
	return 0.5

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> Error:
	var file := FileAccess.open(source_file, FileAccess.READ)
	if not file:
		return ERR_FILE_CANT_OPEN

	var is_glb = source_file.get_extension().to_lower() == "glb"
	var json_dict = {}
	var bin_buffer = PackedByteArray()

	# 1. PARSE GLTF / GLB HEADER & BUFFERS
	if is_glb:
		file.get_32() # magic
		file.get_32() # version
		file.get_32() # length
		var chunk0_len = file.get_32()
		file.get_32() # chunk0_type (JSON)
		var json_str = file.get_buffer(chunk0_len).get_string_from_utf8()
		json_dict = JSON.parse_string(json_str)

		if file.get_position() < file.get_length():
			var chunk1_len = file.get_32()
			file.get_32() # chunk1_type (BIN)
			bin_buffer = file.get_buffer(chunk1_len)
	else:
		var json_str = file.get_as_text()
		json_dict = JSON.parse_string(json_str)
		var buffers = json_dict.get("buffers", [])
		if buffers.size() > 0 and buffers[0].has("uri"):
			var uri = buffers[0]["uri"]
			var bin_path = source_file.get_base_dir().path_join(uri)
			var bin_file = FileAccess.open(bin_path, FileAccess.READ)
			if bin_file:
				bin_buffer = bin_file.get_buffer(bin_file.get_length())

	# 2. FIND PRIMITIVE WITH KHR_gaussian_splatting
	var splat_prim = null
	var meshes = json_dict.get("meshes", [])
	for mesh in meshes:
		for prim in mesh.get("primitives", []):
			if prim.has("extensions") and prim["extensions"].has("KHR_gaussian_splatting"):
				splat_prim = prim
				break
		if splat_prim: break

	if not splat_prim:
		printerr("No KHR_gaussian_splatting extension found in glTF primitive.")
		return ERR_FILE_UNRECOGNIZED

	var attributes = splat_prim.get("attributes", {})
	
	# Helper function to extract accessor byte offset and count
	var get_acc = func(attr_name: String):
		if not attributes.has(attr_name):
			return null
		var acc_id = attributes[attr_name]
		var acc = json_dict["accessors"][acc_id]
		var bv = json_dict["bufferViews"][acc["bufferView"]]
		var count = acc["count"]
		var byte_offset = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
		var byte_stride = bv.get("byteStride", 0)
		
		var type_str = acc["type"]
		var comps = 1
		if type_str == "VEC2": comps = 2
		elif type_str == "VEC3": comps = 3
		elif type_str == "VEC4": comps = 4
		
		var f_stride = comps if byte_stride == 0 else byte_stride / 4
		return {"offset": byte_offset / 4, "stride": f_stride, "count": count}

	var all_floats = bin_buffer.to_float32_array()

	var pos_info = get_acc.call("POSITION")
	var scale_info = get_acc.call("KHR_gaussian_splatting:SCALE")
	var rot_info = get_acc.call("KHR_gaussian_splatting:ROTATION")
	var op_info = get_acc.call("KHR_gaussian_splatting:OPACITY")
	var sh_info = get_acc.call("KHR_gaussian_splatting:SH_DEGREE_0_COEF_0")

	if not pos_info or not scale_info or not rot_info or not op_info or not sh_info:
		printerr("Missing required KHR_gaussian_splatting attributes.")
		return ERR_FILE_CORRUPT

	var point_count = pos_info.count
	
	# --- DYNAMIC PROPERTY LOOKUP ---
	var props = SplatCloudData.DEFAULT_PROPERTIES
	var prop_cnt = props.size()
	
	var idx_x = props.find(&"x")
	var idx_dc0 = props.find(&"f_dc_0")
	var idx_op = props.find(&"opacity")
	var idx_scale0 = props.find(&"scale_0")
	var idx_rot0 = props.find(&"rot_0")

	var new_vertices = PackedFloat32Array()
	new_vertices.resize(point_count * prop_cnt)

	# 3. INTERLEAVE & CONVERT ATTRIBUTES
	for i in point_count:
		var out_idx = i * prop_cnt

		# Position (VEC3)
		var p_idx = pos_info.offset + i * pos_info.stride
		new_vertices[out_idx + idx_x + 0] = all_floats[p_idx + 0]
		new_vertices[out_idx + idx_x + 1] = all_floats[p_idx + 1]
		new_vertices[out_idx + idx_x + 2] = all_floats[p_idx + 2]

		# Spherical Harmonics Degree 0 (VEC3)
		var sh_idx = sh_info.offset + i * sh_info.stride
		new_vertices[out_idx + idx_dc0 + 0] = all_floats[sh_idx + 0]
		new_vertices[out_idx + idx_dc0 + 1] = all_floats[sh_idx + 1]
		new_vertices[out_idx + idx_dc0 + 2] = all_floats[sh_idx + 2]

		# Opacity (SCALAR) - Inverse Sigmoid
		# Required because load_gaussian_splats applies exp(-opacity)[cite: 16]
		var op_idx = op_info.offset + i * op_info.stride
		var o = clampf(all_floats[op_idx + 0], 0.0001, 0.9999)
		new_vertices[out_idx + idx_op] = log(o / (1.0 - o))

		# Scale (VEC3) - Inverse Exponential
		# Required because load_gaussian_splats applies exp(scale)[cite: 16]
		var sc_idx = scale_info.offset + i * scale_info.stride
		new_vertices[out_idx + idx_scale0 + 0] = log(maxf(all_floats[sc_idx + 0], 0.0001))
		new_vertices[out_idx + idx_scale0 + 1] = log(maxf(all_floats[sc_idx + 1], 0.0001))
		new_vertices[out_idx + idx_scale0 + 2] = log(maxf(all_floats[sc_idx + 2], 0.0001))

		# Rotation (VEC4) 
		# glTF spec defines rotation as X, Y, Z, W[cite: 12]
		# SplatCloudData parses them as rot_0 (W), rot_1 (X), rot_2 (Y), rot_3 (Z)[cite: 16]
		var rot_idx = rot_info.offset + i * rot_info.stride
		new_vertices[out_idx + idx_rot0 + 0] = all_floats[rot_idx + 3] # W
		new_vertices[out_idx + idx_rot0 + 1] = all_floats[rot_idx + 0] # X
		new_vertices[out_idx + idx_rot0 + 2] = all_floats[rot_idx + 1] # Y
		new_vertices[out_idx + idx_rot0 + 3] = all_floats[rot_idx + 2] # Z

	# 4. BAKE RESOURCE WITH TYPED ARRAY FIX
	var splat_data = SplatCloudData.new()
	splat_data.size = point_count
	splat_data.properties = props.duplicate()
	splat_data.vertices = new_vertices
	
	var empty_split : Array[int] = []
	splat_data.split = empty_split

	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(splat_data, filename)
