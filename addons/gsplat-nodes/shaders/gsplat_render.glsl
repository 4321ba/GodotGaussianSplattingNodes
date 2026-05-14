#[compute]
#version 460
#extension GL_KHR_shader_subgroup_arithmetic: enable

#define MIN_FACTOR     (255)
#define MIN_ALPHA      (1.0 / MIN_FACTOR)
#define TILE_SIZE      (16)
#define WORKGROUP_SIZE (TILE_SIZE*TILE_SIZE)

layout (local_size_x = TILE_SIZE, local_size_y = TILE_SIZE, local_size_z = 1) in;

struct RasterizeData {
    vec4 color_opacity;
    vec4 normal_roughness;
    vec4 conic_metallic;
    vec4 pos_image_xy;
    vec4 pos_z_pad;
};

layout(std430, set = 0, binding = 0) restrict readonly buffer CulledBuffer { RasterizeData culled_buffer[]; };
layout(std430, set = 0, binding = 1) restrict readonly buffer SortBuffer { uint sort_buffer[]; };
layout(std430, set = 0, binding = 2) restrict readonly buffer BoundsBuffer { uvec2 bounds_buffer[]; };
layout(std430, set = 0, binding = 3) restrict writeonly buffer TargetTileSplatBuffer { vec3 splat_pos; float num_tile_splats; };

layout(rgba32f, set = 0, binding = 4) uniform restrict writeonly image2D rasterized_image;
layout(rgba16f, set = 0, binding = 5) uniform restrict writeonly image2D rasterized_normal;
layout(rgba16f, set = 0, binding = 6) uniform restrict writeonly image2D rasterized_orm;

layout(push_constant) restrict readonly uniform PushConstants { float heatmap_factor; uint target_tile_id; };

shared vec4[WORKGROUP_SIZE] conic_met_tile;
shared vec4[WORKGROUP_SIZE] color_tile;
shared vec4[WORKGROUP_SIZE] norm_rough_tile;
shared vec4[WORKGROUP_SIZE] pos_xy_tile;
shared uint shared_t;

void main() {
    if (gl_LocalInvocationIndex == 0) shared_t = ~0u;
    barrier();
    const ivec2 dims = imageSize(rasterized_image);
    const uvec2 grid_size = (dims + TILE_SIZE - 1) / TILE_SIZE;

    const uvec2 id_block = gl_WorkGroupID.xy;
    const uint id_local = gl_LocalInvocationIndex;
    const uint tile_id = id_block.y*grid_size.x + id_block.x;
    const uvec2 pixel = id_block*TILE_SIZE + gl_LocalInvocationID.xy;
    const bool pixel_in_bounds = pixel.x < uint(dims.x) && pixel.y < uint(dims.y);
    const vec2 image_pos = vec2(pixel);

    const uvec2 bounds = bounds_buffer[tile_id];
    const uint num_splats = uint(max(0, int(bounds.y - bounds.x)));
    const uint num_iterations = uint(ceil(float(num_splats) / float(WORKGROUP_SIZE)));

    vec3 blended_color = vec3(0.0);
    vec3 blended_normal = vec3(0.0);
    vec3 blended_orm = vec3(0.0);
    float t = pixel_in_bounds ? 1.0 : 0.0;

    for (uint i = 0; i < num_iterations && shared_t > MIN_FACTOR; ++i) {
        const uint sort_offset = WORKGROUP_SIZE*i;
        const uint chunk_size = min(uint(WORKGROUP_SIZE), num_splats - sort_offset);

        barrier();
        RasterizeData data;
        if (id_local < chunk_size) {
            data = culled_buffer[sort_buffer[(bounds.x + sort_offset) + id_local]];
        } else {
            data.conic_metallic = vec4(0.0); 
            data.color_opacity = vec4(0.0);
            data.normal_roughness = vec4(0.0, 1.0, 0.0, 0.5);
            data.pos_image_xy = vec4(0.0);
        }
        conic_met_tile[id_local] = data.conic_metallic;
        color_tile[id_local] = data.color_opacity;
        norm_rough_tile[id_local] = data.normal_roughness;
        pos_xy_tile[id_local] = data.pos_image_xy;

        if (id_local == 0) shared_t = 0u;
        barrier();

        for (uint j = 0; pixel_in_bounds && j < chunk_size && t > MIN_ALPHA; ++j) {
            vec3 conic = conic_met_tile[j].xyz;
            float metallic = conic_met_tile[j].w;
            vec4 color_op = color_tile[j];
            vec4 norm_rough = norm_rough_tile[j];
            vec2 offset = pos_xy_tile[j].xy - image_pos;

            float power = -0.5 * (conic.x * offset.x*offset.x + conic.z * offset.y*offset.y) - conic.y * offset.x*offset.y;
            if (power > 0.0) continue; 
            
            vec3 world_normal = norm_rough.xyz;
            
            float alpha = min(0.999, color_op.a * exp(power));
            float next_t = t * (1.0 - alpha);
            float weight = alpha * t;
            
            blended_color += color_op.rgb * weight;
            blended_normal += world_normal * weight;
            blended_orm += vec3(1.0, norm_rough.w, metallic) * weight; // AO, Roughness, Metallic

            t = next_t;
        }
        atomicAdd(shared_t, uint(t*MIN_FACTOR));
        barrier();
    }

    vec3 heatmap_color = mix(vec3(0,0,1), vec3(1,0.2,0.2), float(num_splats)*5e-4) * (1.0 - t) * heatmap_factor;
    if (pixel_in_bounds) {
        float final_alpha = 1.0 - t;
        imageStore(rasterized_image, ivec2(pixel), vec4(blended_color + heatmap_color, final_alpha));
        imageStore(rasterized_normal, ivec2(pixel), vec4(normalize(blended_normal + vec3(0.0,0.0,0.001)), 0.0));
        imageStore(rasterized_orm, ivec2(pixel), vec4(blended_orm, 0.0));
    }

    if (subgroupElect() && pixel_in_bounds && tile_id == target_tile_id && t != 1.0) {
        RasterizeData target_data = culled_buffer[sort_buffer[bounds.x + (bounds.y - bounds.x)/10]];
        splat_pos = vec3(target_data.pos_image_xy.zw, target_data.pos_z_pad.x);
        num_tile_splats = float(num_splats);
    }
}
