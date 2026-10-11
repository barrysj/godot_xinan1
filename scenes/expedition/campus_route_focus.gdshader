shader_type canvas_item;
render_mode unshaded;

uniform vec2 points[32];
uniform vec2 light_boundary[32];
uniform int light_boundary_count = 0;
uniform float light_boundary_feather = 12.0;
uniform float light_outside_brightness = 0.82;
uniform float light_outside_saturation = 1.0;
uniform vec3 light_inside_ambient = vec3(0.0);
uniform int point_count = 0;
uniform bool focused = false;
uniform vec4 route_color : source_color;
uniform vec2 crop_origin = vec2(200.0, 260.0);
uniform vec2 crop_size = vec2(1200.0, 800.0);
uniform vec2 texture_origin = vec2(0.0);
uniform vec2 texture_size = vec2(1600.0, 1200.0);
uniform float feather = 22.0;
uniform float outside_brightness = 0.40;
uniform float inside_gain = 1.15;

void fragment() {
	vec2 p = crop_origin + UV * crop_size;
	vec4 base = texture(TEXTURE, (p - texture_origin) / texture_size);
	vec3 result = base.rgb;
	if (light_boundary_count > 2) {
		float edge_distance = 10000.0;
		bool inside_light = false;
		for (int i = 0; i < light_boundary_count; i++) {
			vec2 a = light_boundary[i];
			vec2 b = light_boundary[(i + 1) % light_boundary_count];
			vec2 edge = b - a;
			float t = clamp(dot(p - a, edge) / max(dot(edge, edge), 0.001), 0.0, 1.0);
			edge_distance = min(edge_distance, length(p - a - edge * t));
			if ((a.y > p.y) != (b.y > p.y) && p.x < a.x + (p.y - a.y) * (b.x - a.x) / (b.y - a.y)) inside_light = !inside_light;
		}
		float signed_distance = inside_light ? -edge_distance : edge_distance;
		float light_mask = 1.0 - smoothstep(-light_boundary_feather, light_boundary_feather, signed_distance);
		float light_luminance = dot(result, vec3(0.2126, 0.7152, 0.0722));
		vec3 subdued = mix(vec3(light_luminance), result, light_outside_saturation) * light_outside_brightness;
		// Lift dark ground gently without washing out already bright windows or effects.
		vec3 campus = result + light_inside_ambient * (1.0 - smoothstep(0.08, 0.35, light_luminance));
		result = mix(subdued, campus, light_mask);
	}
	if (focused && point_count > 2) {
		float distance_to_edge = 10000.0;
		bool inside = false;
		for (int i = 0; i < point_count; i++) {
			vec2 a = points[i];
			vec2 b = points[(i + 1) % point_count];
			vec2 edge = b - a;
			float t = clamp(dot(p - a, edge) / max(dot(edge, edge), 0.001), 0.0, 1.0);
			distance_to_edge = min(distance_to_edge, length(p - a - edge * t));
			if ((a.y > p.y) != (b.y > p.y)) {
				if (p.x < a.x + (p.y - a.y) * (b.x - a.x) / (b.y - a.y)) {
					inside = !inside;
				}
			}
		}
		float signed_distance = inside ? -distance_to_edge : distance_to_edge;
		float mask = 1.0 - smoothstep(-feather, feather, signed_distance);
		float luminance = dot(result, vec3(0.2126, 0.7152, 0.0722));
		vec3 outside = mix(vec3(luminance), result, 0.45) * outside_brightness;
		vec3 lit = min(result * inside_gain, vec3(1.0));
		lit = mix(lit, route_color.rgb, 0.07);
		result = mix(outside, lit, mask);
		// A broad feathered rim, not a hard building-shaped outline.
		float rim = exp(-pow(signed_distance / 10.0, 2.0)) * 0.22;
		result = mix(result, route_color.rgb, rim);
	}
	COLOR = vec4(result, base.a);
}
