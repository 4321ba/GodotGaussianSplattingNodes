shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, skip_vertex_transform;

uniform sampler2D render_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture;
uniform sampler2D orm_texture;

const float GRID_STEP = 1.0 / 128.0; 

vec3 srgb_to_linear(vec3 x) {
    vec3 higher = pow((x + 0.055) / 1.055, vec3(2.4));
    vec3 lower = x / 12.92;
	return mix(higher, lower, lessThan(x, vec3(0.04045)));
}

void vertex() {
	vec2 ndc_xy = VERTEX.xy;
	vec2 screen_uv = ndc_xy * 0.5 + 0.5;
	float splat_depth = texture(normal_texture, screen_uv).a;
	
	if (splat_depth < 0.01) {
		float closest_depth = 0.0;
		for (int i = 1; i <= 4; i++) {
			float offset = GRID_STEP * float(i);
			float d1 = texture(normal_texture, screen_uv + vec2(offset, 0.0)).a;
			float d2 = texture(normal_texture, screen_uv - vec2(offset, 0.0)).a;
			float d3 = texture(normal_texture, screen_uv + vec2(0.0, offset)).a;
			float d4 = texture(normal_texture, screen_uv - vec2(0.0, offset)).a;
			float d5 = texture(normal_texture, screen_uv + vec2(offset, offset)).a;
			float d6 = texture(normal_texture, screen_uv + vec2(-offset, offset)).a;
			float d7 = texture(normal_texture, screen_uv + vec2(offset, -offset)).a;
			float d8 = texture(normal_texture, screen_uv + vec2(-offset, -offset)).a;
			
			float max1 = max(max(d1, d2), max(d3, d4));
			float max2 = max(max(d5, d6), max(d7, d8));
			closest_depth = max(max1, max2);
			if (closest_depth > 0.01) break;
		}
		splat_depth = closest_depth;
	}
	
	vec4 ndc = vec4(ndc_xy, splat_depth, 1.0);
	vec4 view_pt = INV_PROJECTION_MATRIX * ndc;
	VERTEX = view_pt.xyz / view_pt.w;
	POSITION = vec4(ndc_xy, splat_depth, 1.0);
}

void fragment() {
	vec4 albedo_alpha = texture(render_texture, SCREEN_UV);
	
	// Discard absolutely empty space, but allow soft alpha edges to render
	if (albedo_alpha.a < 0.01) discard; 

	vec4 normal_and_depth = texture(normal_texture, SCREEN_UV);
	DEPTH = normal_and_depth.a;
	
	// Check the implicit flag: Does this splat have a normal vector?
	vec3 raw_normal = normal_and_depth.xyz;
	float is_pbr = length(raw_normal) > 0.1 ? 1.0 : 0.0;
	
	// Route color cleanly
	vec3 albedo_color = srgb_to_linear(albedo_alpha.rgb);
	ALBEDO = mix(vec3(0.0), albedo_color, is_pbr);
	EMISSION = mix(albedo_color, vec3(0.0), is_pbr);
	
	// --- FIXED: Restore transparency! ---
	ALPHA = albedo_alpha.a;
	
	// Un-flip PBR normal, but give SH splats a safe, flat normal to avoid shading artifacts
	vec3 pbr_normal = (VIEW_MATRIX * vec4(-raw_normal.x, -raw_normal.y, raw_normal.z, 0.0)).xyz;
	vec3 flat_normal = (VIEW_MATRIX * vec4(0, 0, 1, 0.0)).xyz;
	NORMAL = mix(flat_normal, pbr_normal, is_pbr);
	
	vec3 orm = texture(orm_texture, SCREEN_UV).rgb;
	AO = mix(1.0, orm.r, is_pbr);
	ROUGHNESS = mix(1.0, orm.g, is_pbr);
	METALLIC = mix(0.0, orm.b, is_pbr);
}