shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Blurs the screen in the Y-direction.
void fragment() {
	float num1 = 0.3 / 4.0;
	float num2 = 0.2 / 4.0;
	
    vec3 col = texture(screen_texture, SCREEN_UV).xyz * 0.5;
    col += texture(screen_texture, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE.x, 0)).xyz * num1;
    col += texture(screen_texture, SCREEN_UV + vec2(-SCREEN_PIXEL_SIZE.x, 0)).xyz * num1;
    col += texture(screen_texture, SCREEN_UV + vec2(0, SCREEN_PIXEL_SIZE.y)).xyz * num1;
    col += texture(screen_texture, SCREEN_UV + vec2(0, -SCREEN_PIXEL_SIZE.y)).xyz * num1;
    col += texture(screen_texture, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE.x, -SCREEN_PIXEL_SIZE.y)).xyz * num2;
    col += texture(screen_texture, SCREEN_UV + vec2(-SCREEN_PIXEL_SIZE.x, -SCREEN_PIXEL_SIZE.y)).xyz * num2;
    col += texture(screen_texture, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y)).xyz * num2;
    col += texture(screen_texture, SCREEN_UV + vec2(-SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y)).xyz * num2;
    COLOR.xyz = col;
}