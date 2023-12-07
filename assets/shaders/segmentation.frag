#version 330

#define MAX_COLORS 256

in vec2 fragTexCoord;

uniform sampler2D texture0;
uniform vec3 colours_of_interest[MAX_COLORS];
uniform int colours_of_interest_cnt;
uniform float colour_cone_width;
uniform float brightness_margin_width;

out vec4 finalColor;

void main() {
	finalColor = texture(texture0, fragTexCoord);
}
