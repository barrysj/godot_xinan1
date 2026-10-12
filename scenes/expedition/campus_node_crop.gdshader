shader_type canvas_item;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float circle = 1.0 - smoothstep(0.485, 0.5, length(UV - vec2(0.5)));
	COLOR = source;
	COLOR.a *= circle;
}
