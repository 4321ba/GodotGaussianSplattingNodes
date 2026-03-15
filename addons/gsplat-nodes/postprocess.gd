@tool
class_name SplatCompositor
extends CompositorEffect

static var splat_meshes: Array[SplatCloud3D] = []
static var splat_transforms: Dictionary = {}
static var rasterizer: GaussianSplattingRasterizer = null
static var rasterizer_update_queued := false

@export_range(0.0, 1.0, 0.001) var depth_bias := 0.05
@export_enum("Composite", "GS Alpha", "GS Color", "GS Depth", "Scene Depth", "Depth Reject Mask") var debug_view := 0

var rd: RenderingDevice
var shader: RID
var pipeline: RID
var depth_sampler: RID

static func register_splat(splat: SplatCloud3D) -> void:
	if splat not in splat_meshes:
		splat_meshes.append(splat)
		queue_rasterizer_update()

static func unregister_splat(splat: SplatCloud3D) -> void:
	if splat in splat_meshes:
		splat_meshes.erase(splat)
		queue_rasterizer_update()

static func queue_rasterizer_update() -> void:
	if not rasterizer_update_queued:
		rasterizer_update_queued = true
		# Using Callable to defer a static function call
		Callable(SplatCompositor, "_rebuild_rasterizer").call_deferred()

static func _rebuild_rasterizer() -> void:
	rasterizer_update_queued = false
	
	if splat_meshes.is_empty():
		if rasterizer:
			RenderingServer.call_on_render_thread(rasterizer.cleanup_gpu)
			rasterizer = null
		return

	var active_splats: Array[SplatCloudData] = []
	for m in splat_meshes:
		if m.splat_data: active_splats.append(m.splat_data)
	if active_splats.is_empty(): return

	var combined_data = active_splats[0]
	for data in active_splats.slice(1):
		combined_data = SplatCloudData.merge(combined_data, data)

	var tex = Texture2DRD.new()
	var current_viewport = Engine.get_singleton('EditorInterface').get_editor_viewport_3d(0) if Engine.is_editor_hint() else splat_meshes[0].get_viewport()
	var current_camera = current_viewport.get_camera_3d()

	if rasterizer: RenderingServer.call_on_render_thread(rasterizer.cleanup_gpu)
	rasterizer = GaussianSplattingRasterizer.new(combined_data, current_viewport.size, tex, current_camera)
	
func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_PRE_TRANSPARENT
	access_resolved_depth = true
	RenderingServer.call_on_render_thread(initialize_compute_shader)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if pipeline.is_valid(): RenderingServer.free_rid(pipeline)
		if shader.is_valid(): RenderingServer.free_rid(shader)
		if depth_sampler.is_valid(): RenderingServer.free_rid(depth_sampler)

func initialize_compute_shader() -> void:
	rd = RenderingServer.get_rendering_device()
	if not rd: return
	var glsl_file: RDShaderFile = load("res://addons/gsplat-nodes/post.glsl") # Adjust this path to wherever you save post.glsl
	if not glsl_file: return
	shader = rd.shader_create_from_spirv(glsl_file.get_spirv())
	pipeline = rd.compute_pipeline_create(shader)
	var sampler_state := RDSamplerState.new()
	depth_sampler = rd.sampler_create(sampler_state)
	
func _render_callback(_effect_callback_type: int, render_data: RenderData) -> void:
	if not rd or not shader.is_valid() or not pipeline.is_valid() or not rasterizer:
		return

	# Use standard '=' instead of ':=' to avoid parser inference errors
	var scene_buffers = render_data.get_render_scene_buffers()
	var scene_data = render_data.get_render_scene_data()
	
	# Explicitly type this as a Vector2i
	var size: Vector2i = scene_buffers.get_internal_size()
	if size.x <= 0 or size.y <= 0: return

	if rasterizer.texture_size != size:
		rasterizer.texture_size = size

	var transforms: Array[Transform3D] = []
	for m in splat_meshes:
		transforms.append(splat_transforms.get(m, Transform3D.IDENTITY))
	rasterizer.update_object_transforms(transforms)

	rasterizer.update_camera_matrices()
	rasterizer.rasterize()

	var x_groups := int(ceili(size.x / 16.0))
	var y_groups := int(ceili(size.y / 16.0))

	for view in scene_buffers.get_view_count():
		# Explicitly type these as RID
		var scene_tex: RID = scene_buffers.get_color_layer(view)
		var scene_depth_tex: RID 
		
		if scene_buffers.has_method("get_depth_layer"):
			scene_depth_tex = scene_buffers.get_depth_layer(view)
		else:
			scene_depth_tex = scene_buffers.get_texture_slice("render_buffers", "depth", view, 0, 1, 1)
		
		if not scene_tex.is_valid() or not scene_depth_tex.is_valid(): continue

		var proj := scene_data.get_cam_projection()
		
		var push_constants := PackedFloat32Array([
			size.x, size.y, 0.0, depth_bias, 0.0, float(debug_view), 0.0, 0.0
		] + _projection_to_column_major_floats(proj.inverse()))

		var scene_uniform := RDUniform.new()
		scene_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		scene_uniform.binding = 0
		scene_uniform.add_id(scene_tex)

		var gsplat_uniform := RDUniform.new()
		gsplat_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		gsplat_uniform.binding = 1
		gsplat_uniform.add_id(rasterizer.descriptors['render_texture'].rid)

		var scene_depth_uniform := RDUniform.new()
		scene_depth_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		scene_depth_uniform.binding = 2
		scene_depth_uniform.add_id(depth_sampler)
		scene_depth_uniform.add_id(scene_depth_tex)

		var uniform_set := UniformSetCacheRD.get_cache(shader, 0, [scene_uniform, gsplat_uniform, scene_depth_uniform])

		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		rd.compute_list_set_push_constant(compute_list, push_constants.to_byte_array(), push_constants.size() * 4)
		rd.compute_list_dispatch(compute_list, x_groups, y_groups, 1)
		rd.compute_list_end()

func _projection_to_column_major_floats(matrix: Projection) -> Array:
	return [
		matrix.x[0], matrix.x[1], matrix.x[2], matrix.x[3],
		matrix.y[0], matrix.y[1], matrix.y[2], matrix.y[3],
		matrix.z[0], matrix.z[1], matrix.z[2], matrix.z[3],
		matrix.w[0], matrix.w[1], matrix.w[2], matrix.w[3]
	]
