shader_type canvas_item;
#include "colors_lib.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
//uniform vec4 color_ramp;
uniform int light_divisions = 10;

float ramp_value(float value, float in_start, float in_end, float out_start, float out_end) {
	return out_start + ((out_end - out_start) / (in_end - in_start)) * (value - in_start);
}

float luminance_multiramp(float input) {
	float val = input;
	//val = sqrt(val);
	
	//val = floor(input * float(light_divisions)) / float(light_divisions);
	if (0.0 <= val && val < 0.35) {
		val = ramp_value(val, 0.0, 0.35, 0.2, 0.35);
		
	} else if (0.35 <= val && val < 0.5) {
		val = ramp_value(val, 0.3, 0.5, 0.37, 0.4875);
		
	} else if (0.5 <= val && val < 0.65) {
		val = ramp_value(val, 0.5, 0.65, 0.5215, 0.65);
		
	} else if (0.65 <= val && val < 0.8) {
		val = ramp_value(val, 0.65, 0.8, 0.7, 0.8);
		
	} else if (0.8 <= val && val < 0.97) {
		val = ramp_value(val, 0.8, 0.97, 0.85, 0.97);
		
	} else if (0.97 <= val) {
		val = ramp_value(val, 0.97, 1.0, 0.99, 1.0);
		
	}
	
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
