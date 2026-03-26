#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(rgba16f, binding = 0, set = 0) uniform image2D scene_tex;
layout(rgba32f, binding = 1, set = 0) uniform readonly image2D gsplat_tex; 
layout(set = 0, binding = 2) uniform sampler2D scene_depth_tex;

layout(push_constant, std430) uniform Params {
    vec2 screen_size;
    float alpha_cutoff;
    float depth_bias;
    float depth_test_min_alpha;
    float debug_view;
    vec2 _pad0;
    mat4 _inv_projection;

} p;

vec3 srgb_to_linear(vec3 color) {
    bvec3 cutoff = lessThanEqual(color, vec3(0.04045));
    vec3 lower = color / 12.92;
    vec3 higher = pow((color + 0.055) / 1.055, vec3(2.4));
    return mix(higher, lower, cutoff);
}

void main() {
    ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
    vec2 size = p.screen_size;
    if (pixel.x >= int(size.x) || pixel.y >= int(size.y)) return;

    vec4 scene_color = imageLoad(scene_tex, pixel);
    vec4 gsplat_data = imageLoad(gsplat_tex, pixel);

    vec3 gsplat_rgb = gsplat_data.rgb;
    float raw_gsplat_depth = gsplat_data.a; 
    
    // Determine if the splat rasterizer actually wrote to this pixel
    bool has_gsplat_depth = raw_gsplat_depth > 0.0001;
    float gsplat_alpha = has_gsplat_depth ? 1.0 : 0.0;

    // Fetch the raw Godot hardware depth buffer
    float raw_scene_depth = texelFetch(scene_depth_tex, pixel, 0).r;
    bool has_scene_depth = raw_scene_depth > 0.0; // 0.0 is the far plane / skybox
    
    // Godot 4 uses Reverse-Z (1.0 is near, 0.0 is far).
    // If the scene's raw depth is greater than the splat's raw depth, 
    // the scene is physically closer to the camera. We reject the splat.
    bool depth_rejected = has_scene_depth && has_gsplat_depth && (raw_scene_depth > raw_gsplat_depth);

    if (!has_gsplat_depth || depth_rejected) return;

    vec3 gsplat_linear = srgb_to_linear(gsplat_rgb) * gsplat_alpha;
    vec3 composited_color = gsplat_linear + scene_color.rgb * (1.0 - gsplat_alpha);
    imageStore(scene_tex, pixel, vec4(composited_color, scene_color.a));
}
