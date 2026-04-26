@tool
extends RefCounted

const BinaryPlyReader = preload("res://addons/gdgs/importers/parsers/binary_ply_reader.gd")
# We load the Resource directly instead of using the Canonical Builder
#const GaussianResource = preload("res://addons/gdgs/resources/gaussian_resource.gd") 

static func decode(path: String) -> Dictionary:
	var ply := BinaryPlyReader.read(path, true)
	if not ply.get("ok", false): return ply

	var vertex := BinaryPlyReader.get_element(ply, "vertex")
	if vertex.is_empty(): return _error(ERR_INVALID_DATA, "PLY missing vertex element")

	var property_map: Dictionary = vertex.get("property_map", {})
	var count := int(vertex.get("count", 0))
	var stride := int(vertex.get("stride", 0))
	var data: PackedByteArray = vertex.get("data", PackedByteArray())

	# We pack exactly 20 floats (80 bytes) per PBR splat
	var packed_floats := PackedFloat32Array()
	packed_floats.resize(count * 20)

	var aabb := AABB()

	for i in count:
		var base := i * stride
		var b := i * 20

		var px = float(_read_property(data, base, property_map, "x", 0.0))
		var py = float(_read_property(data, base, property_map, "y", 0.0))
		var pz = float(_read_property(data, base, property_map, "z", 0.0))
		var pos = Vector3(px, py, pz)
		
		if i == 0: aabb = AABB(pos, Vector3.ZERO)
		else: aabb = aabb.expand(pos)

		# 1. Pos and Opacity (vec4)
		packed_floats[b+0] = px
		packed_floats[b+1] = py
		packed_floats[b+2] = pz
		packed_floats[b+3] = _sigmoid(float(_read_property(data, base, property_map, "opacity", 0.0)))

		# 2. Base Color & Metallic (vec4) - Derived from DC0
		packed_floats[b+4] = clamp(float(_read_property(data, base, property_map, "f_dc_0", 0.0)) * 0.28209 + 0.5, 0.0, 1.0)
		packed_floats[b+5] = clamp(float(_read_property(data, base, property_map, "f_dc_1", 0.0)) * 0.28209 + 0.5, 0.0, 1.0)
		packed_floats[b+6] = clamp(float(_read_property(data, base, property_map, "f_dc_2", 0.0)) * 0.28209 + 0.5, 0.0, 1.0)
		packed_floats[b+7] = float(_read_property(data, base, property_map, "metallicFactor", 0.0))

		# 3. Normal & Roughness (vec4)
		packed_floats[b+8] = float(_read_property(data, base, property_map, "nx", 0.0))
		packed_floats[b+9] = float(_read_property(data, base, property_map, "ny", 1.0))
		packed_floats[b+10] = float(_read_property(data, base, property_map, "nz", 0.0))
		packed_floats[b+11] = float(_read_property(data, base, property_map, "roughnessFactor", 0.5))

		# 4. Covariance (float[6])
		var scale_2 := float(_read_property(data, base, property_map, "scale_2", log(1e-6)))
		var scale := Vector3(
			exp(float(_read_property(data, base, property_map, "scale_0", 0.0))),
			exp(float(_read_property(data, base, property_map, "scale_1", 0.0))),
			exp(scale_2)
		)
		var rot := Quaternion(
			float(_read_property(data, base, property_map, "rot_1", 0.0)),
			float(_read_property(data, base, property_map, "rot_2", 0.0)),
			float(_read_property(data, base, property_map, "rot_3", 0.0)),
			float(_read_property(data, base, property_map, "rot_0", 1.0))
		).normalized()
		
		var scale_mat := Basis.from_scale(scale)
		var rot_mat := Basis(rot).transposed()
		var cov_3d := (scale_mat * rot_mat).transposed() * (scale_mat * rot_mat)
		
		packed_floats[b+12] = cov_3d.x[0]; packed_floats[b+13] = cov_3d.y[0]; packed_floats[b+14] = cov_3d.z[0];
		packed_floats[b+15] = cov_3d.y[1]; packed_floats[b+16] = cov_3d.z[1]; packed_floats[b+17] = cov_3d.z[2];

		# 5. Padding (vec2)
		packed_floats[b+18] = 0.0
		packed_floats[b+19] = 0.0

	var res := GaussianResource.new()
	res.point_count = count
	res.point_data_byte = packed_floats.to_byte_array()
	res.aabb = aabb

	return { "ok": true, "resource": res }

static func _read_property(data: PackedByteArray, base: int, property_map: Dictionary, property_name: String, default_value: Variant) -> Variant:
	var prop: Dictionary = property_map.get(property_name, {})
	if prop.is_empty(): return default_value
	return BinaryPlyReader.decode_scalar(data, base + int(prop["offset"]), String(prop["type"]))

static func _sigmoid(value: float) -> float: return 1.0 / (1.0 + exp(-value))
static func _error(code: Error, message: String) -> Dictionary: return { "ok": false, "error": code, "message": message }
