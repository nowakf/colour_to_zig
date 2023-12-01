#version 330

#define MAX_COLORS 256

in vec2 fragTexCoord;

uniform sampler2D texture0;
uniform vec3 colours[MAX_COLORS];
uniform int colours_cnt;
uniform float colour_cone_width;
uniform float brightness_margin_width;

out vec4 finalColor;

float rgb2value(vec3 c) {
	return (1.5 - abs(1.5 - (c.x + c.y + c.z))) * 0.75;
}

float characterize(vec3 col) {
	float best_fit = colour_cone_width;
	float o = -1.;
	for (int i=1; i<colours_cnt; i++) {
		float tmp = distance(normalize(col), normalize(colours[i-1]));
		if (tmp <= best_fit) {
			o = float(i) / float(colours_cnt);
			best_fit = tmp;
		}
	}
	return o;
}
void main() {
	vec4 col = texture(texture0, fragTexCoord);
	float char = characterize(col.rgb);
	if (char < 0.0 || rgb2value(col.rgb) < brightness_margin_width) {
		finalColor = col;
	} else {
		finalColor = vec4(vec3(char), 1.0);
	}
}
