#version 330

#define MAX_COLORS 256

in vec2 fragTexCoord;

uniform sampler3D texture0;
uniform int head;
uniform vec3 colours_of_interest[MAX_COLORS];
uniform int colours_of_interest_cnt;
uniform float colour_cone_width = 0.10;
uniform float brightness_margin_width = 0.15;

out vec4 finalColor;
const int Z_SAMPLES = 8;

float rgb2value(vec3 c) {
	return (1.5 - abs(1.5 - (c.x + c.y + c.z))) * 0.75;
}

vec3 value2rgb(float value) {
	vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
	vec3 p = abs(fract(value - K.xyz) * 6.0 - K.www);
	return clamp(p - K.xxx, 0., 1.);
}

float noise(vec2 pt) {
	return fract(sin(dot(pt, vec2(12.9898, 4.1414))) * 43758.5453);
}

const float PI = 3.14; //update!
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
vec4 golden_gaussian_2d(vec2 center) {
	vec3 scale = float(Z_SAMPLES) / 2.0 / textureSize(texture0, 0);
	vec4 color = vec4(0.0);
	float initial = noise(center) * (2.0 * PI);
	for (int i = 0; i<Z_SAMPLES; i++) {
		float theta = initial + HALF_GOLDEN_ANGLE * i; //prolly wrong
		vec2 norm = vec2(sin(theta), cos(theta));
		color += texture(texture0, vec3(vec2(center + norm * scale.xy), float(head) * scale.z));
	}
	return color / float(Z_SAMPLES);
}

vec4 closest_lod_norm(vec2 center, int lod_lvl) {
	float step = 1.0/float(Z_SAMPLES);
	float mindist = 1.0;
	vec4 o = vec4(0.);
	vec3 lod = normalize(textureLod(texture0, vec3(center, float(head)*step), lod_lvl).rgb);
	for (int i = 0; i<Z_SAMPLES; i++) {
		vec4 tmp = texture(texture0, vec3(center, i*step));
		float dist = distance(normalize(tmp.rgb), lod);
		if (dist <  mindist) {
			mindist = dist;
			o = tmp;
		}
	}
	return o;
}
float characterize(vec3 col) {
	float best_fit = colour_cone_width;
	float o = 1.;
	for (int i=0; i<colours_of_interest_cnt; i++) {
		float tmp = distance(normalize(col), normalize(colours_of_interest[i-1]));
		if (tmp < best_fit) {
			o = float(i) / float(colours_of_interest_cnt);
			best_fit = tmp;
		}
	}
	return o;
}

void main() {
	vec4 rgba = golden_gaussian_3d(fragTexCoord);
	float midrange = ceil(rgb2value(rgba.rgb) - brightness_margin_width);
	float char = characterize(rgba.rgb);
	if (char == 1.0 || rgb2value(rgba.rgb) < brightness_margin_width) {
		finalColor = vec4(1.0);
	} else {
		finalColor = vec4(value2rgb(char), 1.0);
	}
}
