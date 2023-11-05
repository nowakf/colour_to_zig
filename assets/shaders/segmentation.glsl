#version 330
in vec2 fragTexCoord;

uniform sampler3D texture0;
uniform int head;
uniform vec3 colours_of_interest[] = vec3[12] (
	vec3(1.0, 0.0, 0.0),
	vec3(0.0, 1.0, 0.0),
	vec3(0.0, 0.0, 1.0),
	vec3(1.0, 1.0, 0.0),
	vec3(0.0, 1.0, 1.0),
	vec3(1.0, 0.0, 1.0),
	vec3(0.5, 1.0, 0.0),
	vec3(0.0, 0.5, 1.0),
	vec3(1.0, 0.0, 0.5),
	vec3(1.0, 0.5, 0.0),
	vec3(0.0, 1.0, 0.5),
	vec3(0.5, 0.0, 1.0)
);
uniform float colour_cone_width = 0.55;
uniform float brightness_margin_width = 0.10;

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
	float o = 0.;
	for (int i=1; i<=12; i++) {
		float tmp = distance(normalize(col), normalize(colours_of_interest[i-1]));
		if (tmp < best_fit) {
			o = float(i) / float(12);
			best_fit = tmp;
		}
	}
	return o;
}

void main() {
	vec4 rgba = closest_lod_norm(fragTexCoord, 4);
	float midrange = ceil(rgb2value(rgba.rgb) - brightness_margin_width);
	if (rgb2value(rgba.rgb) < brightness_margin_width) {
		finalColor = vec4(1.0);
	} else {
		finalColor = vec4(value2rgb(characterize(rgba.rgb)), 1.0);
	}
}
