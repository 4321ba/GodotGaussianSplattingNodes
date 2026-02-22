@tool
extends MeshInstance3D

# Need to use get_singleton because of https://github.com/godotengine/godot/issues/91713
@onready var viewport : Variant = Engine.get_singleton('EditorInterface').get_editor_viewport_3d(0) if Engine.is_editor_hint() else get_viewport()
@onready var camera : Variant = viewport.get_camera_3d()
@onready var material : ShaderMaterial = get_surface_override_material(0)
@onready var camera_fov := [camera.fov]

var rasterizer : GaussianSplattingRasterizer
var should_print_debug = false
const DEBUG_PRINT_INTERVAL = 1.0
var debug_timer = 0.0

var splat_meshes : Array[SplatMesh] = []

func _ready() -> void:
	find_by_method(get_parent(), StringName("is_splat_mesh"), splat_meshes)
	assert(len(splat_meshes) <= GaussianSplattingRasterizer.MAX_OBJECT_COUNT)
	var splat_filenames := []
	for m in splat_meshes:
		splat_filenames.append(m.ply_file)
	
	if splat_filenames:
		init_rasterizer(splat_filenames)
	
	viewport.size_changed.connect(reset_render_texture)

# source: https://forum.godotengine.org/t/how-do-you-get-all-nodes-of-a-certain-class/9143
func find_by_method(node: Node, method_name : StringName, result : Array) -> void:
	if node.has_method(method_name) and node.is_visible_in_tree():
		result.push_back(node)
	for child in node.get_children():
		find_by_method(child, method_name, result)

func print_debug_info() -> void:
	
	# --- variables ---
	
	var loaded_file : String
	var num_rendered_splats := '0'
	var video_memory_used := '0.00MB'
	var timings : PackedStringArray
	
	loaded_file = ""
	if splat_meshes:
		loaded_file += splat_meshes[0].ply_file.get_file()
		for m in splat_meshes.slice(1):
			loaded_file += ", " + m.ply_file.get_file()
	
	# --- update debug info ---
	
	if not (rasterizer and rasterizer.context): return
	var device := rasterizer.context.device
	
	### Update Total Duplicated Splats ###
	if rasterizer.descriptors.has('histogram'): 
		var num_splats := device.buffer_get_data(rasterizer.descriptors['histogram'].rid, 0, 4).decode_u32(0)
		num_rendered_splats = add_number_separator(num_splats) + (' (buffer overflow!)' if num_splats > rasterizer.point_cloud.size * 10 else '')
	
	### Update VRAM Used ###
	var vram_bytes := device.get_memory_usage(RenderingDevice.MEMORY_TOTAL)
	video_memory_used = '%.2f%s' % [vram_bytes * (1e-6 if vram_bytes < 1e9 else 1e-9), 'MB' if vram_bytes < 1e9 else 'GB']
	
	### Update Pipeline Timestamps ###
	var timestamp_count := device.get_captured_timestamps_count()
	if timestamp_count > 0:
		timings = PackedStringArray(); timings.resize(timestamp_count-1 + 1)
		var previous_time := device.get_captured_timestamp_gpu_time(0)
		var total_time_ms := (device.get_captured_timestamp_gpu_time(timestamp_count-1) - previous_time)*1e-6
		for i in range(1, timestamp_count):
			var timestamp_time := device.get_captured_timestamp_gpu_time(i)
			var stage_time_ms := (timestamp_time - previous_time)*1e-6
			var gpu_time_percentage_text := ('%5.2f%%' % (stage_time_ms/total_time_ms*1e2))
			timings[i-1] = '%-16s %.2fms (%s)' % [device.get_captured_timestamp_name(i) + ':', stage_time_ms, gpu_time_percentage_text]
			previous_time = timestamp_time
		timings[-1] = 'Total GPU Time:  %.2fms' % total_time_ms
	
	# --- print debug info ---
	
	var fps := Engine.get_frames_per_second()
	print('')
	print('')
	print('-------------------------- GaussianSplatting Info --------------------------')
	print('FPS:             %d (%s)' % [fps, '%.2fms' % (1e3 / fps)])
	print('Loaded File:     %s' % ['(loading...)' if rasterizer and not rasterizer.is_loaded else loaded_file])
	print('VRAM Used:       %s' % video_memory_used)
	print('Rendered Splats: %s' % num_rendered_splats)
	print('Rendered Size:   %.0v' % rasterizer.texture_size)
	print('Camera Position: %+.2v' % camera.global_position)
	print('')
	print('Stage Timings')
	for i in len(timings):
		print(timings[i])
	

func init_rasterizer(ply_file_paths : Array) -> void:
	if rasterizer: RenderingServer.call_on_render_thread(rasterizer.cleanup_gpu)
	
	var ply_file = PlyFile.new(ply_file_paths[0])
	for file in ply_file_paths.slice(1):
		if file.ends_with('.ply'):
			var next_ply_file = PlyFile.new(file)
			ply_file = PlyFile.merge(ply_file, next_ply_file)
	
	var render_texture := Texture2DRD.new()
	rasterizer = GaussianSplattingRasterizer.new(ply_file, viewport.size, render_texture, camera)
	material.set_shader_parameter('render_texture', render_texture)
	#if not Engine.is_editor_hint():
		#camera.reset()
		#$LoadingBar.set_visibility(true)
		#rasterizer.loaded.connect($LoadingBar.set_visibility.bind(false))
	#ImGui.Text('Enable Heatmap: '); ImGui.SameLine(); if ImGui.Checkbox('##heatmap_bool', rasterizer.should_enable_heatmap): rasterizer.is_loaded = false
	#ImGui.Text('Render Scale:   '); ImGui.SameLine(); if ImGui.SliderFloat('##render_scale_float', rasterizer.render_scale, 0.05, 1.5): reset_render_texture()
	#ImGui.Text('Model Scale:    '); ImGui.SameLine(); if ImGui.SliderFloat('##model_scale_float', rasterizer.model_scale, 0.25, 5.0): rasterizer.is_loaded = false
	#ImGui.Text('Camera FOV:     '); ImGui.SameLine(); if ImGui.SliderFloat('##fov_float', camera_fov, 20, 170): camera.fov = camera_fov[0]

func reset_render_texture() -> void:
	rasterizer.is_loaded = false
	rasterizer.texture_size = viewport.size
	material.set_shader_parameter('render_texture', rasterizer.render_texture)

func _process(delta: float) -> void:
	if should_print_debug:
		debug_timer += delta
		if debug_timer > DEBUG_PRINT_INTERVAL:
			debug_timer -= DEBUG_PRINT_INTERVAL
			print_debug_info()
		
		#$LoadingBar.update_progress(float(rasterizer.num_splats_loaded[0]) / float(rasterizer.point_cloud.size))
	if not rasterizer:
		return;
	
	var has_camera_updated := rasterizer.update_camera_matrices()
	
	
	var splat_transforms : Array[Transform3D] = []
	for m in splat_meshes:
		splat_transforms.append(m.global_transform)
	rasterizer.update_object_transforms(splat_transforms)
		
	#Engine.max_fps = 30
	RenderingServer.call_on_render_thread(rasterizer.rasterize)

func _notification(what):
	if what == NOTIFICATION_PREDELETE and rasterizer: 
		RenderingServer.call_on_render_thread(rasterizer.cleanup_gpu)

## Source: https://reddit.com/r/godot/comments/yljjmd/comment/iuz0x43/
static func add_number_separator(number : int, separator : String = ',') -> String:
	var in_str := str(number)
	var out_chars := PackedStringArray()
	var length := in_str.length()
	for i in range(1, length + 1):
		out_chars.append(in_str[length - i])
		if i < length and i % 3 == 0:
			out_chars.append(separator)
	out_chars.reverse()
	return ''.join(out_chars)
