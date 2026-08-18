#[compute]
#version 460
#extension GL_KHR_shader_subgroup_arithmetic: enable

#define TILE_SIZE                (16)
#define SORT_WORKGROUP_SIZE      (512)
#define SORT_PARTITION_DIVISION  (8)
#define SORT_PARTITION_SIZE      (SORT_PARTITION_DIVISION * SORT_WORKGROUP_SIZE)
#define MAX_OBJECT_COUNT         16

#define SH_C0 0.28209479177387814
#define SH_C1 0.4886025119029199
#define SH_C2_0 1.0925484305920792
#define SH_C2_1 1.0925484305920792
#define SH_C2_2 0.31539156525252005
#define SH_C2_3 1.0925484305920792
#define SH_C2_4 0.5462742152960396
#define SH_C3_0 0.5900435899266435
#define SH_C3_1 2.890611442640554
#define SH_C3_2 0.4570457994644658
#define SH_C3_3 0.3731763325901154
#define SH_C3_4 0.4570457994644658
#define SH_C3_5 1.445305721320277
#define SH_C3_6 0.5900435899266435

layout(local_size_x = 256, local_size_y = 1, local_size_z = 1) in;

// 64-Float memory aligned block
struct Splat {
    vec4 pos_and_opacity;
    vec4 normal_and_roughness;
    vec4 cov_and_metallic;
    vec4 cov2_and_id;
    vec4 sh_coeffs[12]; // 48 SH floats
};

struct RasterizeData {
    vec4 color_opacity;
    vec4 normal_roughness;
    vec4 conic_metallic;
    vec4 pos_image_xy;
    vec4 pos_z_pad;
};

layout(std430, set = 0, binding = 0) restrict readonly buffer SplatsBuffer { Splat splat_buffer[]; };
layout(std430, set = 0, binding = 1) restrict writeonly buffer CulledBuffer { RasterizeData culled_buffer[]; };
layout(std430, set = 0, binding = 2) restrict buffer Histograms { uint sort_buffer_size; uint histogram[]; };
layout(std430, set = 0, binding = 3) restrict writeonly buffer SortKeysBuffer { uint sort_keys[]; };
layout(std430, set = 0, binding = 4) restrict writeonly buffer SortValuesBuffer { uint sort_values[]; };
layout(std430, set = 0, binding = 5) restrict writeonly buffer GridDimensionsBuffer { uint grid_dims[]; };
layout(std140, set = 0, binding = 6) restrict uniform Uniforms { vec3 camera_pos; float model_scale; ivec2 dims; float time; };
layout(std140, set = 0, binding = 7) restrict uniform Transforms { mat4 transforms[MAX_OBJECT_COUNT]; };
layout(push_constant) restrict readonly uniform PushConstants { mat4 view_matrix; mat4 projection_matrix; };

vec3 get_sh_vec3(in Splat splat, int index) {
    int start = index * 3;
    float r = splat.sh_coeffs[start / 4][start % 4];
    float g = splat.sh_coeffs[(start + 1) / 4][(start + 1) % 4];
    float b = splat.sh_coeffs[(start + 2) / 4][(start + 2) % 4];
    return vec3(r, g, b);
}

vec3 get_color(in vec3 view_dir, in Splat splat) {
    const float x = view_dir.x, y = view_dir.y, z = view_dir.z;
    const float xx = x*x, yy = y*y, zz = z*z, xy = x*y, yz = y*z, xz = x*z;
    return max(vec3(0), 0.5 
        + get_sh_vec3(splat, 0) * SH_C0
        - get_sh_vec3(splat, 1) * SH_C1 * y
        + get_sh_vec3(splat, 2) * SH_C1 * z
        - get_sh_vec3(splat, 3) * SH_C1 * x
        + get_sh_vec3(splat, 4) * SH_C2_0 * xy
        - get_sh_vec3(splat, 5) * SH_C2_1 * yz
        + get_sh_vec3(splat, 6) * SH_C2_2 * (2.0*zz - xx - yy)
        - get_sh_vec3(splat, 7) * SH_C2_3 * xz
        + get_sh_vec3(splat, 8) * SH_C2_4 * (xx - yy)
        - get_sh_vec3(splat, 9) * SH_C3_0 * y * (3.0*xx - yy)
        + get_sh_vec3(splat, 10) * SH_C3_1 * x * yz
        - get_sh_vec3(splat, 11) * SH_C3_2 * y * (4.0*zz - xx - yy)
        + get_sh_vec3(splat, 12) * SH_C3_3 * z * (2.0*zz - 3.0*xx - 3.0*yy)
        - get_sh_vec3(splat, 13) * SH_C3_4 * x * (4.0*zz - xx - yy)
        + get_sh_vec3(splat, 14) * SH_C3_5 * z * (xx - yy)
        - get_sh_vec3(splat, 15) * SH_C3_6 * x * (xx - 3.0*yy));
}

vec3 project_covariance(in mat3 covariance_3d, in float scale_modifier, in vec3 mean, in ivec2 dims) {
    const mat3 cov_3d = covariance_3d * scale_modifier*scale_modifier;
    vec2 tan_fov_inv = vec2(projection_matrix[0][0], projection_matrix[1][1]);
    vec2 focal = vec2(dims - 1) * 0.5 * tan_fov_inv;
    vec2 tan_fov = 1.0 / abs(tan_fov_inv);
    float depth_inv = -1.0 / mean.z;
    focal *= depth_inv;
    mean.xy = clamp(mean.xy * depth_inv, -tan_fov * 1.3, tan_fov * 1.3);
    mat3 view_linear = mat3(view_matrix);
    mat3 jacobian = mat3(focal.x, 0, 0, 0, focal.y, 0, focal.x * mean.x, focal.y * mean.y, 0);
    mat3 screen_transform = jacobian * view_linear;
    mat3 cov_2d = screen_transform * cov_3d * transpose(screen_transform);
    return vec3(cov_2d[0][0] + 0.3, cov_2d[0][1], cov_2d[1][1] + 0.3);
}

uvec4 get_rect(in vec2 image_pos, in float radius, in uvec2 grid_size) {
    return ivec4(
        clamp(     (image_pos - radius) / TILE_SIZE,  vec2(0.0), vec2(grid_size)),
        clamp(ceil((image_pos + radius) / TILE_SIZE), vec2(0.0), vec2(grid_size))
    );
}

void main() {
    const int id = int(gl_GlobalInvocationID.x);
    const uvec2 grid_size = (dims + TILE_SIZE - 1) / TILE_SIZE;
    if (id >= splat_buffer.length()) return;
    barrier();

    const Splat splat = splat_buffer[id];
    uint instance_id = uint(splat.cov2_and_id.w + 0.5);
    mat4 model_matrix = transforms[instance_id];

    mat3 cov_mx = mat3(
        splat.cov_and_metallic.x, splat.cov_and_metallic.y, splat.cov_and_metallic.z,
        splat.cov_and_metallic.y, splat.cov2_and_id.x, splat.cov2_and_id.y,
        splat.cov_and_metallic.z, splat.cov2_and_id.y, splat.cov2_and_id.z
    );

    mat3 object_linear = mat3(model_matrix);
    mat3 world_covariance = object_linear * cov_mx * transpose(object_linear);
    vec4 world_pos = model_matrix * vec4(splat.pos_and_opacity.xyz * model_scale, 1.0);
    vec4 view_pos = view_matrix * world_pos;
    vec4 clip_pos = projection_matrix * view_pos;

    vec2 view_bounds = clip_pos.ww * 1.2;
    if (any(lessThan(clip_pos.xyz, vec3(-view_bounds, 0.0))) || any(greaterThan(clip_pos.xyz, vec3(view_bounds, clip_pos.w)))) return;

    float splat_opacity = splat.pos_and_opacity.w;
    const vec3 covariance = project_covariance(world_covariance, model_scale, view_pos.xyz, dims);
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

    mat3 normal_matrix = transpose(inverse(object_linear));
    vec3 world_normal = normalize(normal_matrix * splat.normal_and_roughness.xyz);

    // Compute Color via SH Math! (PBR models will gracefully fall back to base color since their f_rest is 0)
    vec3 view_dir = normalize(world_pos.xyz - camera_pos);
    vec3 computed_color = get_color(view_dir, splat);

    RasterizeData data;
    data.color_opacity = vec4(computed_color, splat_opacity);
    data.normal_roughness = vec4(world_normal, splat.normal_and_roughness.w);
    data.conic_metallic = vec4(vec3(covariance.z, -covariance.y, covariance.x) / det, splat.cov_and_metallic.w);
    data.pos_image_xy = vec4(image_pos, world_pos.xy);
    data.pos_z_pad = vec4((ndc_pos.z + 1.0) * 0.5, 0.0, 0.0, 0.0);

    culled_buffer[id] = data;
    barrier();

    if (subgroupElect()) {
        uint sort_buffer_size = sort_buffer_size;
        atomicMax(grid_dims[0], (sort_buffer_size + SORT_PARTITION_SIZE - 1) / SORT_PARTITION_SIZE);
        atomicMax(grid_dims[3], (sort_buffer_size + 256 - 1) / 256);
    }

    uint depth = uint(ndc_pos.z*ndc_pos.z*ndc_pos.z * 0xFFFF) & 0xFFFF;
    for (uint y = rect_bounds.y; y < rect_bounds.w; ++y)
    for (uint x = rect_bounds.x; x < rect_bounds.z; ++x) {
        uint tile_id = y*grid_size.x + x;
        uint key = (tile_id << 16) | depth;
        sort_keys[sort_buffer_offset] = key;
        sort_values[sort_buffer_offset] = id;
        sort_buffer_offset++;
    }
}
