shader_type canvas_item;
#include "colors_lib.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
//uniform vec4 color_ramp;
//uniform int light_divisions = 10;

// float in_start, float in_end, float out_start, float out_end
uniform vec4 ramp_1 = vec4(0.0, 0.35, 0.2, 0.35);
uniform vec4 ramp_2 = vec4(0.3, 0.5, 0.37, 0.4875);
uniform vec4 ramp_3 = vec4(0.5, 0.65, 0.5215, 0.65);
uniform vec4 ramp_4 = vec4(0.65, 0.8, 0.7, 0.8);
uniform vec4 ramp_5 = vec4(0.8, 0.97, 0.85, 0.97);
uniform vec4 ramp_6 = vec4(0.97, 1.0, 0.99, 1.0);

#define ramp_value(value, ramp) \
	if (ramp.x <= value && value < ramp.y) { \
		return ramp.z + ((ramp.w - ramp.z) / (ramp.y - ramp.x)) * (value - ramp.x); \
	} else

// turned it into a macro now
//float ramp_value_og(float value, vec4 ramp) {
	//if (ramp.x <= value && value < ramp.y) {
		//return ramp.z + ((ramp.w - ramp.z) / (ramp.y - ramp.x)) * (value - ramp.x);
	//} else {
		//return value;
	//}
//}

float luminance_multiramp(float input) {
	float val = input;
	//val = sqrt(val);

	// TODO make this actually work if they are overlapping
	ramp_value(val, ramp_1);
	ramp_value(val, ramp_2);
	ramp_value(val, ramp_3);
	ramp_value(val, ramp_4);
	ramp_value(val, ramp_5);
	ramp_value(val, ramp_6);

	return val;
}


void fragment() {
	//vec3 sRGB_color = texture(TEXTURE, UV).rgb;

	vec3 sRGB_color =  textureLod(screen_texture, UV, 0.0).rgb;

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
	COLOR.rgb = final_color;
	COLOR.a = 255.0;

}
