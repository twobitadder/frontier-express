shader_type canvas_item;

uniform vec4 nebula_1 : source_color;
uniform vec4 nebula_2 : source_color;
uniform vec4 base_color : source_color;
uniform float threshold_1 = 0.5;
uniform float threshold_2 = 0.9;


void fragment() {
	vec4 color = texture(TEXTURE,UV);
	
	if (color.r > threshold_1)
		COLOR = nebula_1;
	else if (color.r > threshold_2)
		COLOR = nebula_2;
	else
		COLOR = vec4(0.0f);
}
