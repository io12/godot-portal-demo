shader_type spatial;
render_mode unshaded;
uniform sampler2D texture_albedo : hint_albedo;

void vertex() {
}

void fragment() {
	vec2 base_uv = SCREEN_UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo_tex.rgb;
}
