@icon("res://addons/gsplat-nodes/icons/splat_cloud_data.svg")
class_name SplatCloudData extends Resource

@export var size : int
@export var vertices : PackedFloat32Array
@export var properties : Array[StringName]
@export var split : Array[int] # indices where new objects start


const DEFAULT_PROPERTIES : Array[StringName] = [
	&"x", &"y", &"z", &"nx", &"ny", &"nz", 
	&"f_dc_0", &"f_dc_1", &"f_dc_2", 
	&"f_rest_0", &"f_rest_1", &"f_rest_2", &"f_rest_3", &"f_rest_4", &"f_rest_5", &"f_rest_6", &"f_rest_7", &"f_rest_8", &"f_rest_9", &"f_rest_10", &"f_rest_11", 
	&"f_rest_12", &"f_rest_13", &"f_rest_14", &"f_rest_15", &"f_rest_16", &"f_rest_17", &"f_rest_18", &"f_rest_19", &"f_rest_20", &"f_rest_21", 
	&"f_rest_22", &"f_rest_23", &"f_rest_24", &"f_rest_25", &"f_rest_26", &"f_rest_27", &"f_rest_28", &"f_rest_29", &"f_rest_30", &"f_rest_31", 
	&"f_rest_32", &"f_rest_33", &"f_rest_34", &"f_rest_35", &"f_rest_36", &"f_rest_37", &"f_rest_38", &"f_rest_39", &"f_rest_40", &"f_rest_41", 
	&"f_rest_42", &"f_rest_43", &"f_rest_44", 
	&"opacity", &"scale_0", &"scale_1", &"scale_2", &"rot_0", &"rot_1", &"rot_2", &"rot_3",
	&"metallicFactor", &"roughnessFactor"
]
const DEFAULT_PROP_CNT = len(DEFAULT_PROPERTIES)


func get_vertex(index : int) -> Dictionary:
	var start_index := len(properties) * index
	var vertex := {}
	for i in len(properties):
		vertex[properties[i]] = vertices[start_index + i]
	return vertex

static func merge(pc1 : SplatCloudData, pc2 : SplatCloudData) -> SplatCloudData:
	var merged := SplatCloudData.new()
	merged.size = pc1.size + pc2.size
	assert(pc1.properties.hash() == pc2.properties.hash())
	merged.properties = pc1.properties
	merged.vertices = PackedFloat32Array(pc1.vertices)
	merged.vertices.append_array(pc2.vertices)
	merged.split.append_array(pc1.split)
	merged.split.append(pc1.vertices.size())
	for s in pc2.split:
		merged.split.append(s + pc1.vertices.size())
	return merged

static func load_gaussian_splats(
	point_cloud : SplatCloudData,
	stride : int,
	device : RenderingDevice,
	buffer : RID,
	should_terminate_reference : Array[bool],
	num_points_loaded : Array[int],
	callback : Callable
):
	const STRUCT_SIZE := 64 # Perfectly aligned 16 vec4s!
	assert(len(should_terminate_reference) == 1 and len(num_points_loaded) == 1)

	var num_properties := len(point_cloud.properties)
	var p := point_cloud.vertices

	var idx_x = point_cloud.properties.find(&"x")
	var idx_nx = point_cloud.properties.find(&"nx")
	var idx_dc0 = point_cloud.properties.find(&"f_dc_0")
	var idx_rest0 = point_cloud.properties.find(&"f_rest_0")
	var idx_op = point_cloud.properties.find(&"opacity")
	var idx_scale0 = point_cloud.properties.find(&"scale_0")
	var idx_rot0 = point_cloud.properties.find(&"rot_0")
	var idx_metallic = point_cloud.properties.find(&"metallicFactor")
	var idx_roughness = point_cloud.properties.find(&"roughnessFactor")

	var upload_data   : Array[PackedByteArray] = []
	var upload_offset : Array[int]            = []
	var upload_size   : Array[int]            = []
	var upload_mutex  := Mutex.new()

	var task_id = WorkerThreadPool.add_group_task(func(i : int):
		if should_terminate_reference[0]: return

		var points := PackedFloat32Array(); points.resize(STRUCT_SIZE*stride)
		var tile_size := mini(point_cloud.size - i*stride, stride)

		for j in tile_size:
			var v := num_properties*(i*stride + j)
			var b := j*STRUCT_SIZE

			points[b+0] = p[v+idx_x+0]
			points[b+1] = p[v+idx_x+1]
			points[b+2] = p[v+idx_x+2]
			points[b+3] = 1.0 / (1.0 + exp(-p[v+idx_op]))

			points[b+4] = p[v+idx_nx+0] if idx_nx != -1 else 0.0
			points[b+5] = p[v+idx_nx+1] if idx_nx != -1 else 0.0
			points[b+6] = p[v+idx_nx+2] if idx_nx != -1 else 0.0
			points[b+7] = p[v+idx_roughness] if idx_roughness != -1 else 0.75

			var scale := Basis.from_scale(Vector3(exp(p[v+idx_scale0]), exp(p[v+idx_scale0+1]), exp(p[v+idx_scale0+2])))
			var rotation := Basis(Quaternion(p[v+idx_rot0+1], p[v+idx_rot0+2], p[v+idx_rot0+3], p[v+idx_rot0+0])).transposed()
			var cov_3d := (scale * rotation).transposed() * (scale * rotation)

			points[b+8]  = cov_3d.x[0]
			points[b+9]  = cov_3d.y[0]
			points[b+10] = cov_3d.z[0]
			points[b+11] = p[v+idx_metallic] if idx_metallic != -1 else 0.0

			points[b+12] = cov_3d.y[1]
			points[b+13] = cov_3d.z[1]
			points[b+14] = cov_3d.z[2]

			var obj_id = 0.0
			for k in point_cloud.split:
				if v >= k: obj_id += 1.0
			points[b+15] = obj_id

			if idx_dc0 != -1:
				points[b+16] = p[v+idx_dc0+0]
				points[b+17] = p[v+idx_dc0+1]
				points[b+18] = p[v+idx_dc0+2]
			else:
				points[b+16] = 0.0; points[b+17] = 0.0; points[b+18] = 0.0;
				
			if idx_rest0 != -1:
				# Transpose PLY segregated (RRR...GGG...BBB) to GPU interleaved (RGB, RGB, RGB)
				for k in range(15):
					points[b+19 + k*3 + 0] = p[v+idx_rest0 + k + 0]  # Red
					points[b+19 + k*3 + 1] = p[v+idx_rest0 + k + 15] # Green
					points[b+19 + k*3 + 2] = p[v+idx_rest0 + k + 30] # Blue
			else:
				for k in range(45):
					points[b+19+k] = 0.0

		if should_terminate_reference[0]: return

		var byte_data : PackedByteArray = points.to_byte_array()
		var actual_byte_size := STRUCT_SIZE * tile_size * 4
		if byte_data.size() > actual_byte_size:
			byte_data.resize(actual_byte_size)

		var byte_offset := i * STRUCT_SIZE * stride * 4
		var byte_size   := actual_byte_size

		upload_mutex.lock()
		upload_data.append(byte_data)
		upload_offset.append(byte_offset)
		upload_size.append(byte_size)
		upload_mutex.unlock()

	, ceili(point_cloud.size / stride + 1.0))

	WorkerThreadPool.wait_for_group_task_completion(task_id)

	if should_terminate_reference[0]:
		callback.call()
		return

	var upload_on_render_thread := func():
		if should_terminate_reference[0]: return

		upload_mutex.lock()
		var data   = upload_data.duplicate()
		var offset = upload_offset.duplicate()
		var size   = upload_size.duplicate()
		upload_data.clear()
		upload_offset.clear()
		upload_size.clear()
		upload_mutex.unlock()

		for idx in data.size():
			device.buffer_update(buffer, offset[idx], size[idx], data[idx])

		callback.call()

	RenderingServer.call_on_render_thread(upload_on_render_thread)
