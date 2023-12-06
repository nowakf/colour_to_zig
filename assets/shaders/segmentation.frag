#version 330

#define MAX_COLORS 256

in vec2 fragTexCoord;

uniform sampler3D texture0;
uniform vec3 colours_of_interest[MAX_COLORS];
uniform int colours_of_interest_cnt;
uniform float colour_cone_width;
uniform float brightness_margin_width;

out vec4 finalColor;
const int Z_SAMPLES = 8;

vec4 lod_blur(vec2 uv, int lod_lvl) {
	vec4 o = vec4(0.);
	float step = 1.0/float(Z_SAMPLES);
	for (int i=0; i<Z_SAMPLES; i++) {
		o += textureLod(texture0, vec3(uv, float(i)*step), lod_lvl);
	}
	return o * step;
}

float rgb2value(vec3 c) {
	return (1.5 - abs(1.5 - (c.x + c.y + c.z))) * 0.75;
}

float characterize(vec3 col) {
	float best_fit = colour_cone_width;
	float o = -1.;
	float tmp = 0.;
	for (int i=1; i<colours_of_interest_cnt; i++) {
		tmp = distance(normalize(col), normalize(colours_of_interest[i-1]));
		if (tmp <= best_fit) {
			o = float(i) / float(colours_of_interest_cnt);
			best_fit = tmp;
		}
	}
	return o;
}

float noise(vec2 pt) {
	return fract(sin(dot(pt, vec2(12.9898, 4.1414))) * 43758.5453);
}

const float PI = 3.14159265359;
const float HALF_GOLDEN_ANGLE = 1.1999816148643266611157777533165;
vec4 golden_gaussian_3d(vec2 center) {
	vec3 scale = float(Z_SAMPLES) / 2.0 / textureSize(texture0, 0);
	vec4 color = vec4(0.0);
	float initial = noise(center) * (2.0 * PI);
	for (int i = 0; i<Z_SAMPLES; i++) {
		float theta = initial + HALF_GOLDEN_ANGLE * i; //prolly wrong
		float phi = acos(1.0 - 2.0*(float(i)+0.5) / float(Z_SAMPLES));
		vec3 norm = vec3(cos(theta) * sin(phi), sin(theta) * sin(phi), cos(phi));
		color += vec4(texture(texture0, vec3(center, 0.0)+norm*scale*noise(norm.xy)));
	}
	return color / float(Z_SAMPLES);
}

void main() {
	vec4 rgba = 
	golden_gaussian_3d(fragTexCoord);
	//lod_blur(fragTexCoord, 2);
	float char = characterize(rgba.rgb);
	if (char < 0.0 || rgb2value(rgba.rgb) < brightness_margin_width) {
		//clear colour?
		finalColor = vec4(vec3(0.0), 1.0);
	} else {
		finalColor = vec4(rgba.rgb, char);
	}
}
