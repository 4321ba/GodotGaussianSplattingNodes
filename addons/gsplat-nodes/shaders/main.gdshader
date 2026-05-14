shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D render_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture;
uniform sampler2D orm_texture;

// Source: https://gamedev.stackexchange.com/a/148088
vec3 srgb_to_linear(vec3 x) {
    vec3 higher = pow((x + 0.055) / 1.055, vec3(2.4));
    vec3 lower = x / 12.92;
	return mix(higher, lower, lessThan(x, vec3(0.04045)));
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0); // Pushes quad back
}

void fragment() {
	vec4 albedo_alpha = texture(render_texture, SCREEN_UV);
	
	// Crucial for Deferred Translucency: We must discard empty space!
	if (albedo_alpha.a < 0.1) discard; 

	ALBEDO = srgb_to_linear(albedo_alpha.rgb);
	ALPHA = albedo_alpha.a;
	
	// Godot naturally converts this to view-space for the deferred pass
	NORMAL = texture(normal_texture, SCREEN_UV).xyz;
	
	vec3 orm = texture(orm_texture, SCREEN_UV).rgb;
	AO = orm.r;
	ROUGHNESS = orm.g;
	METALLIC = orm.b;
}
