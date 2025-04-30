shader_type spatial;

uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture: hint_depth_texture, repeat_disable, filter_nearest;

uniform vec2 plane_size;

uniform vec4 primary_color: source_color;
uniform vec4 secondary_color: source_color;
uniform float roughness = 0.2;

uniform sampler2D wave_noise;
uniform float wave_amplitude = 1.0;
uniform float wave_turbulence = 0.25;

uniform sampler2D normal_map_a: hint_normal;
uniform sampler2D normal_map_b: hint_normal;
uniform float normal_map_a_strength: hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float normal_map_b_strength: hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float uv_scale = 1.0;
uniform vec2 movement_direction = vec2(0.1, 0.1);
uniform float movement_strength = 1.0;

uniform float depth_distance: hint_range(0.0, 20.0, 0.1) = 4.0;
uniform float beers_law: hint_range(0.0, 20.0, 0.1) = 12.0;
uniform float water_transparency: hint_range(0.0, 1.0, 0.01) = 0.0;

uniform float refraction_strength: hint_range(0.0, 8.0, 0.001) = 0.5;

varying vec3 normal_map_vary;

float wave(vec2 position) {
	position += texture(wave_noise, position / 10.0).x * 2.0 - 1.0;
	vec2 wv = 1.0 - abs(sin(position));
	return pow(1.0 - pow(wv.x * wv.y, 0.65), 4.0);
}

float height(vec2 position, float time) {
	float t = time * wave_turbulence;
	float d = wave((position + t) * 0.4) * 0.3;
	d += wave((position - t) * 0.3) * 0.3;
	d += wave((position + t) * 0.5) * 0.2;
	d += wave((position - t) * 0.6) * 0.2;
	return d * wave_amplitude - (wave_amplitude / 2.0);
}

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void fragment() {
	float fresnel = fresnel(3.0, NORMAL, VIEW);

	vec2 uv = vec2(UV.x * plane_size.x, UV.y * plane_size.y) * uv_scale;
	vec2 uv_movement = normalize(movement_direction) * TIME * movement_strength / plane_size;

	vec3 normal_map_component_a = texture(normal_map_a, uv + uv_movement).rgb * normal_map_a_strength;
	vec3 normal_map_component_b = texture(normal_map_b, uv - uv_movement * 0.5).rgb * normal_map_b_strength;
	vec3 normal_map = normal_map_component_a + normal_map_component_b;
	//vec3 normal_map = normal_map_vary;

	vec3 ref_normal_map = normal_map * 2.0 - (normal_map_a_strength + normal_map_b_strength);
	vec3 ref_normal = mix(NORMAL, TANGENT * ref_normal_map + BINORMAL * ref_normal_map + NORMAL * ref_normal_map, 1.0);
	vec2 ref_offs = SCREEN_UV - ref_normal.xy * refraction_strength;

	float depth_clean = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	float depth = textureLod(depth_texture, ref_offs, 0.0).r;
	vec3 screen = textureLod(screen_texture, ref_offs, 0.0).rgb;

	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec3 ndc_clean = vec3(SCREEN_UV * 2.0 - 1.0, depth_clean);

	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z + VERTEX.z;

	float surface_height = 0.0001;
	//float surface_height = height(UV.xy, TIME);

	vec4 world;
	if (linear_depth < surface_height) {
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc_clean, 1.0);
	}
	else {
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	}

	float depth_texture_y = world.y / world.w;
	float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;

	float depth_blend = clamp((vertex_y - depth_texture_y) / depth_distance, 0.0, 1.0);
	depth_blend = exp(-depth_blend * beers_law);

	vec3 depth_color = mix(secondary_color, primary_color, depth_blend).rgb;
	vec3 refraction_texture = textureLod(screen_texture, ref_offs, ROUGHNESS * 2.0).rgb;
	if (linear_depth < surface_height) {
		refraction_texture = textureLod(screen_texture, SCREEN_UV, ROUGHNESS * 2.0).rgb;
	}
	else {
		refraction_texture = textureLod(screen_texture, ref_offs, ROUGHNESS * 2.0).rgb;
	}

	vec3 final_color = mix(depth_color, refraction_texture, water_transparency * depth_blend);

	ALBEDO = final_color + (0.2 * fresnel);
	ROUGHNESS = roughness * (1.0 - fresnel);
	NORMAL_MAP = normal_map;
}

void vertex() {
	vec2 pos = VERTEX.xz;
	float k = height(pos, TIME);
	VERTEX.y = k;
	normal_map_vary = normalize(vec3(k - height(pos + vec2(0.1, 0.0), TIME), 0.1, k - height(pos + vec2(0.0, 0.1), TIME)));
	NORMAL = normal_map_vary;
}