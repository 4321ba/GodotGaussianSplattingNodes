#[compute]
#version 460
#extension GL_KHR_shader_subgroup_arithmetic: enable

#define TILE_SIZE                (16)
#define SORT_WORKGROUP_SIZE      (512)
#define SORT_PARTITION_DIVISION  (8)
#define SORT_PARTITION_SIZE      (SORT_PARTITION_DIVISION * SORT_WORKGROUP_SIZE)
#define DECODE_COVARIANCE(c) (mat3(c[0], c[1], c[2], c[1], c[3], c[4], c[2], c[4], c[5]))

layout(local_size_x = 256, local_size_y = 1, local_size_z = 1) in;

// NEW: 20-Float (80 Byte) layout
struct Splat {
	vec4 pos_and_opacity;
	vec4 color_and_metallic;
	vec4 normal_and_roughness;
	float covariance[6]; 
	vec2 _pad;
};

// NEW: 20-Float (80 Byte) layout
struct RasterizeData {
	vec4 color_and_metallic;
	vec4 normal_and_roughness;
	vec4 depth_data;
	vec3 conic;
	float pos_z;
	vec2 image_pos;
    vec2 pos_xy;
};

layout(std430, set = 0, binding = 0) restrict readonly buffer SplatsBuffer {
	Splat splat_buffer[];
};

layout(std430, set = 0, binding = 1) restrict writeonly buffer CulledBuffer {
	RasterizeData culled_buffer[];
};

layout (std430, set = 0, binding = 2) restrict buffer Histograms {
	uint sort_buffer_size;
    uint histogram[];
};

layout (std430, set = 0, binding = 3) restrict writeonly buffer SortKeysBuffer {
    uint sort_keys[];
};

layout (std430, set = 0, binding = 4) restrict writeonly buffer SortValuesBuffer {
    uint sort_values[];
};

layout (std430, set = 0, binding = 5) restrict writeonly buffer GridDimensionsBuffer {
	uint grid_dims[];
};

layout (std430, set = 0, binding = 6) restrict readonly buffer SplatInstanceIdsBuffer {
	uvec2 splat_instance_data[]; // x = unique instance id, y = which splat data to use
};

layout (std430, set = 0, binding = 7) restrict readonly buffer InstanceTransformsBuffer {
	mat4 instance_model_matrices[];
};

layout (std140, set = 0, binding = 8) restrict uniform Uniforms {
	vec3 camera_pos;
	float time;
	ivec2 dims; // Texture size
	int point_count;
	int _uniform_pad0;
};

layout(push_constant) restrict readonly uniform PushConstants {
	mat4 view_matrix;
	mat4 projection_matrix;
};

float ease_out_cubic(in float x) {
	float a = 1.0 - x;
	return 1.0 - a*a*a;
}

/** Computes a 2D projected covariance matrix from the given Gaussian parameters. */
vec3 project_covariance(in mat3 covariance_3d, in float scale_modifier, in vec3 mean, in ivec2 dims) {
	const mat3 cov_3d = covariance_3d * scale_modifier*scale_modifier;
	// Godot camera space looks down -Z, so use positive forward depth here.
	vec2 tan_fov_inv = vec2(projection_matrix[0][0], projection_matrix[1][1]);
	vec2 focal = vec2(dims - 1) * 0.5 * tan_fov_inv;
	// RenderData projections can encode a Y flip in projection_matrix[1][1].
	// Keep that sign in the focal scale, but use absolute FOV extents for clamping.
	vec2 tan_fov = 1.0 / abs(tan_fov_inv);
	float depth_inv = -1.0 / mean.z;
	focal *= depth_inv;

	mean.xy = clamp(mean.xy * depth_inv, -tan_fov * 1.3, tan_fov * 1.3);
	mat3 view_linear = mat3(view_matrix);
	mat3 jacobian = mat3(
		focal.x, 0, 0,
		0, focal.y, 0,
		focal.x * mean.x, focal.y * mean.y, 0);
	mat3 screen_transform = jacobian * view_linear;
	mat3 cov_2d = screen_transform * cov_3d * transpose(screen_transform);
	return vec3(cov_2d[0][0] + 0.3, cov_2d[0][1], cov_2d[1][1] + 0.3);
}

uvec4 get_rect(in vec2 image_pos, in float radius, in uvec2 grid_size) {
	return ivec4(
		clamp(     (image_pos - radius) / TILE_SIZE,  vec2(0), grid_size),
		clamp(ceil((image_pos + radius) / TILE_SIZE), vec2(0), grid_size));
}

void main() {
	const int id = int(gl_GlobalInvocationID.x);
	const uvec2 grid_size = (dims + TILE_SIZE - 1) / TILE_SIZE;
	if (id >= uint(point_count)) return;
	
	barrier();
	uvec2 instance_data = splat_instance_data[id];
	uint instance_id = instance_data.x;
	uint unique_splat_index = instance_data.y;
	const Splat splat = splat_buffer[unique_splat_index];
	mat4 model_matrix = instance_model_matrices[instance_id];

	float is_visible = model_matrix[0][3];
	if (is_visible < 0.5) return;
	model_matrix[0][3] = 0.0;
	
	// --- FRUSTUM CULLING ---
	mat3 object_linear = mat3(model_matrix);
	mat3 world_covariance = object_linear * DECODE_COVARIANCE(splat.covariance) * transpose(object_linear);
	vec4 world_pos = model_matrix * vec4(splat.pos_and_opacity.xyz, 1.0);
	vec4 view_pos = view_matrix * world_pos;
	vec4 clip_pos = projection_matrix * view_pos;
	vec2 view_bounds = clip_pos.ww*1.2;
	if (any(lessThan(clip_pos.xyz, vec3(-view_bounds, 0.0))) || any(greaterThan(clip_pos.xyz, vec3(view_bounds, clip_pos.w)))) return;
	
	// --- GAUSSIAN PROJECTION ---
	float splat_time = time;
	float time_factor_late = 1.0;

	float splat_opacity = splat.pos_and_opacity.w * time_factor_late;
	float splat_scale = 1.0;

	const vec3 covariance = project_covariance(world_covariance, splat_scale, view_pos.xyz, dims);
	float det = covariance.x*covariance.z - covariance.y*covariance.y;
	if (det == 0.0) return;

	float mid = 0.5 * (covariance.x + covariance.z);
	vec2 eigenvalues = mid + vec2(1, -1)*sqrt(max(0.1, mid*mid - det));
	if (any(lessThan(eigenvalues, vec2(0)))) return;

	vec3 ndc_pos = clip_pos.xyz / clip_pos.w;
	vec2 image_pos = ((ndc_pos.xy + 1.0)*0.5) * (dims - 1);

	float radius = pow(splat_opacity, 0.2) * 2.5*sqrt(max(eigenvalues.x, eigenvalues.y));
	uvec4 rect_bounds = get_rect(image_pos, radius, grid_size);
	uint num_tiles_touched = (rect_bounds.z - rect_bounds.x)*(rect_bounds.w - rect_bounds.y);

	if (num_tiles_touched == 0) return;

	const uint buffer_size = atomicAdd(sort_buffer_size, num_tiles_touched);
	uint sort_buffer_offset = buffer_size;
	
	// --- NORMAL TRANSFORM ---
	mat3 normal_matrix = transpose(inverse(object_linear));
	vec3 world_normal = normalize(normal_matrix * splat.normal_and_roughness.xyz);

	RasterizeData data;
	data.image_pos = image_pos;
	data.conic = vec3(covariance.z, -covariance.y, covariance.x) / det; 
	
	// Pass PBR properties!
	data.color_and_metallic = splat.color_and_metallic;
	data.color_and_metallic.a = splat_opacity;
	data.normal_and_roughness = vec4(world_normal, splat.normal_and_roughness.w);

	data.pos_xy = world_pos.xy;
	data.pos_z = world_pos.z;
	data.depth_data = vec4(-view_pos.z, 0.0, 0.0, 0.0);
	culled_buffer[id] = data;
	barrier();

	// --- UPDATE SORT KERNEL DIMENSIONS ---
	if (subgroupElect()) {
		uint sort_buffer_size = sort_buffer_size;
		atomicMax(grid_dims[0], (sort_buffer_size + SORT_PARTITION_SIZE - 1) / SORT_PARTITION_SIZE);
		atomicMax(grid_dims[3], (sort_buffer_size + 256 - 1) / 256);
	}

	// --- GAUSSIAN DUPLICATION ---
	float view_depth = max(0.0, clip_pos.w);
	float depth01 = view_depth / (1.0 + view_depth);
	uint depth = uint(depth01 * 65535.0) & 0xFFFF;
	for (uint y = rect_bounds.y; y < rect_bounds.w; ++y)
	for (uint x = rect_bounds.x; x < rect_bounds.z; ++x) {
		uint tile_id = y*grid_size.x + x;
		uint key = (tile_id << 16) | depth;
		sort_keys[sort_buffer_offset] = key;
		sort_values[sort_buffer_offset] = id;
		sort_buffer_offset++;
	}
}
