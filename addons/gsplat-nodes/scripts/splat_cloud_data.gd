@icon("res://addons/gsplat-nodes/icons/splat_cloud_data.svg")
class_name SplatCloudData extends Resource

@export var size : int
@export var vertices : PackedFloat32Array
@export var properties : Array[StringName]
@export var split : Array[int] # indices where new objects start


const DEFAULT_PROPERTIES : Array[StringName] = [&"x", &"y", &"z", &"nx", &"ny", &"nz", &"f_dc_0", &"f_dc_1", &"f_dc_2", &"metallicFactor", &"roughnessFactor", &"opacity", &"scale_0", &"scale_1", &"scale_2", &"rot_0", &"rot_1", &"rot_2", &"rot_3"]
const DEFAULT_PROP_CNT = 19


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
	const STRUCT_SIZE := 20 # floats
	assert(len(should_terminate_reference) == 1 and len(num_points_loaded) == 1)
	#'''
	# --- ADD THESE DEBUG LINES ---
	print("\n--- SPLAT DATA DEBUG ---")
	print("Total Points: ", point_cloud.size)
	for i in range(min(3, point_cloud.size)):
		print("Vertex ", i, ": ", point_cloud.get_vertex(i))
	print("------------------------\n")
	# -----------------------------
	#'''
	var num_properties := len(point_cloud.properties)
	var p := point_cloud.vertices

	# ------------------------------------------------------------------
	# NEW: Queues that workers will fill – upload happens later on render thread
	# ------------------------------------------------------------------
	var upload_data   : Array[PackedByteArray] = []
	var upload_offset : Array[int]            = []
	var upload_size   : Array[int]            = []
	var upload_mutex  := Mutex.new()

	var task_id = WorkerThreadPool.add_group_task(func(i : int):
		if should_terminate_reference[0]: return

		# We swizzle point data so that it matches the std430 layout struct in our kernels
		var points := PackedFloat32Array(); points.resize(STRUCT_SIZE*stride)
		var tile_size := mini(point_cloud.size - i*stride, stride)
		var creation_time := Time.get_ticks_msec()*1e-3

		for j in tile_size:
			var v := num_properties*(i*stride + j)
			var b := j*STRUCT_SIZE

			# 1. Position and Opacity
			points[b+0] = p[v+0]
			points[b+1] = p[v+1]
			points[b+2] = p[v+2]
			points[b+3] = 1.0 / (1.0 + exp(-p[v+11]))

			# 2. Base Color & Object ID
			points[b+4] = clamp(p[v+6] * 0.28209 + 0.5, 0.0, 1.0)
			points[b+5] = clamp(p[v+7] * 0.28209 + 0.5, 0.0, 1.0)
			points[b+6] = clamp(p[v+8] * 0.28209 + 0.5, 0.0, 1.0)
			points[b+7] = 0
			for k in point_cloud.split:
				if v >= k: points[b+7] += 1

			# --- Rotation & Scale ---
			var scale := Basis.from_scale(Vector3(exp(p[v+12]), exp(p[v+13]), exp(p[v+14])))
			var rotation := Basis(Quaternion(p[v+16], p[v+17], p[v+18], p[v+15])).transposed()
			var cov_3d := (scale * rotation).transposed() * (scale * rotation)

			# 3. Normal & Roughness (With Pseudo-Normal Heuristic!)
			var nx = p[v+3]; var ny = p[v+4]; var nz = p[v+5];
			if nx == 0.0 and ny == 0.0 and nz == 0.0:
				var s0 = p[v+12]; var s1 = p[v+13]; var s2 = p[v+14];
				var min_s = min(s0, min(s1, s2))
				var derived_normal: Vector3
				if min_s == s0: derived_normal = rotation.x
				elif min_s == s1: derived_normal = rotation.y
				else: derived_normal = rotation.z
				derived_normal = derived_normal.normalized()
				nx = derived_normal.x; ny = derived_normal.y; nz = derived_normal.z;

			points[b+8] = nx
			points[b+9] = ny
			points[b+10] = nz
			points[b+11] = p[v+10] if p[v+10] > 0.0 else 0.75 # Roughness

			# 4. Covariance & Metallic
			points[b+12] = cov_3d.x[0]
			points[b+13] = cov_3d.y[0]
			points[b+14] = cov_3d.z[0]
			points[b+15] = p[v+9] # Metallic

			# 5. Covariance Part 2
			points[b+16] = cov_3d.y[1]
			points[b+17] = cov_3d.z[1]
			points[b+18] = cov_3d.z[2]
			points[b+19] = 0.0 # Pad

		if should_terminate_reference[0]: return

		# --------------------------------------------------------------
		# Instead of calling device.buffer_update here (forbidden on workers)
		# we just queue the byte data
		# --------------------------------------------------------------
		var byte_data : PackedByteArray = points.to_byte_array()
		var actual_byte_size := STRUCT_SIZE * tile_size * 4
		if byte_data.size() > actual_byte_size:
			byte_data.resize(actual_byte_size)   # void return in Godot 4.3+

		var byte_offset := i * STRUCT_SIZE * stride * 4
		var byte_size   := actual_byte_size

		upload_mutex.lock()
		upload_data.append(byte_data)
		upload_offset.append(byte_offset)
		upload_size.append(byte_size)
		upload_mutex.unlock()

	, ceili(point_cloud.size / stride + 1.0)) # +1.0 to force float division

	# Wait for all worker threads to finish processing
	WorkerThreadPool.wait_for_group_task_completion(task_id)

	# Early-out if loading was cancelled
	if should_terminate_reference[0]:
		callback.call()
		return

	# ------------------------------------------------------------------
	# Upload everything on the rendering thread (the only place allowed)
	# ------------------------------------------------------------------
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
