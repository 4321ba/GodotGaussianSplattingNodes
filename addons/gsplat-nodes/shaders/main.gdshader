shader_type spatial;
// CRITICAL: skip_vertex_transform prevents Godot from double-transforming our reconstructed VERTEX!
render_mode blend_mix, depth_draw_opaque, cull_disabled, skip_vertex_transform;

uniform sampler2D render_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture;
uniform sampler2D orm_texture;

// We define the size of one quad subdivision (Assuming 128x128 subdivision)
const float GRID_STEP = 1.0 / 128.0; 

vec3 srgb_to_linear(vec3 x) {
    vec3 higher = pow((x + 0.055) / 1.055, vec3(2.4));
    vec3 lower = x / 12.92;
	return mix(higher, lower, lessThan(x, vec3(0.04045)));
}

void vertex() {
	// 1. Grab the raw local coordinates of the quad [-1, 1]
	vec2 ndc_xy = VERTEX.xy;
	
	// 2. Convert to Screen UV to sample our textures
	vec2 screen_uv = ndc_xy * 0.5 + 0.5;
	
	// 3. Sample the splat depth from the compute shader
	float splat_depth = texture(normal_texture, screen_uv).a;
	
	// --- FIXED EDGE DILATION ---
	// The background outputs exactly 0.0. If we are on the background, dilate!
	if (splat_depth < 0.01) {
		float closest_depth = 0.0;
		
		// Search up to 4 grid blocks away
		for (int i = 1; i <= 4; i++) {
			float offset = GRID_STEP * float(i);
			
			// 8-tap search ring (Cardinals + Diagonals)
			float d1 = texture(normal_texture, screen_uv + vec2(offset, 0.0)).a;
			float d2 = texture(normal_texture, screen_uv - vec2(offset, 0.0)).a;
			float d3 = texture(normal_texture, screen_uv + vec2(0.0, offset)).a;
			float d4 = texture(normal_texture, screen_uv - vec2(0.0, offset)).a;
			float d5 = texture(normal_texture, screen_uv + vec2(offset, offset)).a;
			float d6 = texture(normal_texture, screen_uv + vec2(-offset, offset)).a;
			float d7 = texture(normal_texture, screen_uv + vec2(offset, -offset)).a;
			float d8 = texture(normal_texture, screen_uv + vec2(-offset, -offset)).a;
			
			// We want the MAXIMUM depth (which belongs to a splat, > 0.0)
			float max1 = max(max(d1, d2), max(d3, d4));
			float max2 = max(max(d5, d6), max(d7, d8));
			closest_depth = max(max1, max2);
			
			// If we found a valid splat depth in this ring, stop searching!
			if (closest_depth > 0.01) {
				break;
			}
		}
		
		// Snap this background vertex to the found splat depth
		splat_depth = closest_depth;
	}
	
	// 4. Reconstruct the true View Space position using the flattened geometry
	vec4 ndc = vec4(ndc_xy, splat_depth, 1.0);
	vec4 view_pt = INV_PROJECTION_MATRIX * ndc;
	
	// 5. MOLD THE GEOMETRY
	VERTEX = view_pt.xyz / view_pt.w;
	
	// 6. Lock the quad to the screen in Clip Space
	POSITION = vec4(ndc_xy, splat_depth, 1.0);
}

void fragment() {
	vec4 albedo_alpha = texture(render_texture, SCREEN_UV);
	
	// The fragments on the stretched edges will now be safely discarded, 
	// but the underlying lighting grid will be perfectly matched to the silhouette!
	if (albedo_alpha.a < 0.1) discard; 

	ALBEDO = srgb_to_linear(albedo_alpha.rgb);
	ALPHA = albedo_alpha.a;
	
	vec4 normal_and_depth = texture(normal_texture, SCREEN_UV);
	
	// Pixel-perfect depth for Godot's Z-buffer sorting, pulled directly from alpha[cite: 19]
	DEPTH = normal_and_depth.a;
	
	// Un-flip the compute shader's inverted axes
	vec3 world_normal = normal_and_depth.xyz;
	world_normal.x = -world_normal.x;
	world_normal.y = -world_normal.y;
	NORMAL = (VIEW_MATRIX * vec4(world_normal, 0.0)).xyz;
	
	vec3 orm = texture(orm_texture, SCREEN_UV).rgb;
	AO = orm.r;
	ROUGHNESS = orm.g;
	METALLIC = orm.b;
}