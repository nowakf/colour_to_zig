#version 330
in vec2 fragTexCoord;

uniform sampler3D texture0;

out vec4 finalColor;

const float SAMPLES = 10.0;

const float PI = 3.14; //update!
const float HALF_GOLDEN_ANGLE = 1.1999816148643266611157777533165;
const int TH_SAMPLES = 10;
const vec3 scale = vec3(0.01);

float noise(vec2 pt) {
	return fract(sin(dot(pt, vec2(12.9898, 4.1414))) * 43758.5453);
}

vec4 golden_gaussian_3d(vec2 center) {
	vec4 color = vec4(0.0);
	float initial = noise(center) * (2.0 * PI);
	for (int i = 0; i<TH_SAMPLES; i++) {
		float theta = initial + HALF_GOLDEN_ANGLE * i; //prolly wrong
		float phi = acos(1.0 - 2.0*(float(i)+0.5) / float(TH_SAMPLES));
		vec3 norm = vec3(cos(theta) * sin(phi), sin(theta) * sin(phi), cos(phi));
		color += texture(texture0, vec3(center, 0.0)+norm*scale*noise(norm.xy));
	}
	return color / float(TH_SAMPLES);
}

void main() {
	finalColor = golden_gaussian_3d(fragTexCoord);
}
