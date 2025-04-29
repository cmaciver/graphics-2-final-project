shader_type spatial;
render_mode blend_mul, diffuse_toon;
#include "colors_lib.gdshaderinc"

uniform bool on = true;

uniform sampler2D diffuse;

// float in_start, float in_end, float out_start, float out_end
uniform vec4 ramp_1 = vec4(0.0, 0.35, 0.2, 0.35);
uniform vec4 ramp_2 = vec4(0.3, 0.5, 0.37, 0.4875);
uniform vec4 ramp_3 = vec4(0.5, 0.65, 0.5215, 0.65);
uniform vec4 ramp_4 = vec4(0.65, 0.8, 0.7, 0.8);
uniform vec4 ramp_5 = vec4(0.8, 0.97, 0.85, 0.97);
uniform vec4 ramp_6 = vec4(0.97, 1.0, 0.99, 1.0);


float ramp_value(float value, vec4 ramp) {
	if (ramp.x <= value && value < ramp.y) {
		return ramp.z + ((ramp.w - ramp.z) / (ramp.y - ramp.x)) * (value - ramp.x);
	} else {
		return value;
	}
}

float luminance_multiramp(float input) {
	float val = input;
	//val = sqrt(val);

	//val = floor(input * float(light_divisions)) / float(light_divisions);

	val = ramp_value(val, ramp_1);
	val = ramp_value(val, ramp_2);
	val = ramp_value(val, ramp_3);
	val = ramp_value(val, ramp_4);
	val = ramp_value(val, ramp_5);
	val = ramp_value(val, ramp_6);


	return val;
}

void light() {
    DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
}

void fragment() {
	diffuse;

	vec3 sRGB_color = texture(diffuse, UV, 0.0).rgb;
	if (! on) {
		ALBEDO = sRGB_color;
		ALPHA = 1.0;
	} else {


		vec3 linear_color;
		linear_color = sRGB_color;
		linear_color = linear_from_sRGB(sRGB_color); // THIS IS ACTUALLY MORE IMPORTANT THAN YOU THINK IT IS!!

		//// may or may not actually keep this
		//float luminance = 0.299*linear_color.r + 0.587*linear_color.g + 0.114*linear_color.b;

		vec3 oklab_color = oklab_from_linear(linear_color);
		oklab_color = oklch_from_oklab(oklab_color);
		//oklab_color.z += 1.7;


		// do cell shading on just the luminance
		oklab_color.x = luminance_multiramp(oklab_color.x);

		oklab_color = oklab_from_oklch(oklab_color);
		vec3 final_color;
		final_color = linear_from_oklab(oklab_color);
		//final_color = sRGB_from_linear(final_color);

		ALBEDO = final_color;
		ALPHA = 0.5;
		ALPHA_ANTIALIASING_EDGE = 0.2; // does this do anything ?
	}
}
