shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform sampler2D render_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_texture;
uniform sampler2D orm_texture;

vec3 srgb_to_linear(vec3 x) {
    vec3 higher = pow((x + 0.055) / 1.055, vec3(2.4));
    vec3 lower = x / 12.92;
	return mix(higher, lower, lessThan(x, vec3(0.04045)));
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
	vec4 ndc = vec4(VERTEX.xy, 1.0, 1.0);
	vec4 view_pt = INV_PROJECTION_MATRIX * ndc;
	VERTEX = view_pt.xyz / view_pt.w;
}

void fragment() {
	vec4 albedo_alpha = texture(render_texture, SCREEN_UV);
	if (albedo_alpha.a < 0.1) discard; 

	ALBEDO = srgb_to_linear(albedo_alpha.rgb);
	ALPHA = albedo_alpha.a;
	
	vec4 normal_and_depth = texture(normal_texture, SCREEN_UV);
	
	// USE EXACT OLD DEPTH BEHAVIOR:
	DEPTH = normal_and_depth.a;
	
	// Keep the normal flip to ensure lighting doesn't hit the back faces
	vec3 world_normal = normal_and_depth.xyz;
	world_normal.x = -world_normal.x;
	world_normal.y = -world_normal.y;
	NORMAL = (VIEW_MATRIX * vec4(world_normal, 0.0)).xyz;
	
	vec3 orm = texture(orm_texture, SCREEN_UV).rgb;
	AO = orm.r;
	ROUGHNESS = orm.g;
	METALLIC = orm.b;
}
