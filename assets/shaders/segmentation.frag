#version 330

#define MAX_COLORS 256

in vec2 fragTexCoord;

const int GAUSS_SAMPLES = 16;
const float SCALE = 5.;
uniform sampler2D camera_frame;
uniform sampler2D state;

out vec4 finalColor;

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

const float PI = 3.14159265359;
const float HALF_GOLDEN_ANGLE = 1.1999816148643266611157777533165;
vec4 golden_gaussian(sampler2D tex, vec2 center) {
	vec2 scale = SCALE/textureSize(camera_frame, 0);
	vec4 color = vec4(0.0);
	float initial = rand(center) * (2.0 * PI);
	for (int i = 0; i<GAUSS_SAMPLES; i++) {
		float theta = initial + HALF_GOLDEN_ANGLE * i;
		vec2 norm = vec2(cos(theta), sin(theta));
		color += vec4(texture(tex, center+norm*scale*rand(norm.xy)));
	}
	return color / float(GAUSS_SAMPLES);
}


vec4 update(in vec2 uv) {
	vec4 init = texture(state, fragTexCoord * vec2(1, -1)); //stupid raylib
	vec4 add = golden_gaussian(camera_frame, fragTexCoord);
	return mix(init, add, vec4(distance(init, add) / 3. + 0.01));
}

void main() {
	finalColor = update(fragTexCoord);
}
