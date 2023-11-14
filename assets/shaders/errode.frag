#version 330

in vec2 fragTexCoord;

uniform sampler2D texture0;

out vec4 finalColor;

const float BIAS = 0.8;

const int nbs_cnt = 8;
const vec2 nbs[] = vec2[nbs_cnt] (
	vec2(0.0, -1.0),
	vec2(1.0, -1.0),
	vec2(1.0,  0.0),
	vec2(1.0,  1.0),
	vec2(0.0,  1.0),
	vec2(-1.0,  1.0),
	vec2(-1.0, 0.0),
	vec2(-1.0, -1.0)
);

const int cross_cnt = 4;
const vec2 cross[] = vec2[cross_cnt] (
	vec2(0.0, -1.0),
	vec2(1.0,  0.0),
	vec2(0.0,  1.0),
	vec2(-1.0, 0.0)
);

const int cnt = nbs_cnt;
const vec2 kernel[] = nbs;

vec3 average(vec2 pos) {
	vec3 rgb = texture(texture0, pos).rgb;
	vec2 resolution = textureSize(texture0, 0);
	for (int i=0; i<cnt; i++) {
		rgb += texture(
			texture0, 
			fragTexCoord +
			kernel[i] / resolution
		).rgb;
	}
	return rgb / float(cnt + 1);
}

vec3 closest(vec2 pos, vec3 ref) {
	vec2 resolution = textureSize(texture0, 0);
	vec3 rgb = texture(texture0, pos).rgb;
	float min_dist = distance(normalize(rgb), normalize(ref));
	for (int i=0; i<cnt; i++) {
		vec3 tmp = texture(
			texture0, 
			fragTexCoord +
			kernel[i] / resolution
		).rgb;
		float tmp_dist = distance(normalize(tmp), normalize(ref));
		if (tmp_dist < min_dist) {
			min_dist = tmp_dist;
			rgb = tmp;
		}
	}
	return rgb;
}

float bw_errode() {
	float neighbors = 0.0;
	vec2 resolution = textureSize(texture0, 0);
	for (int i=0; i<cnt; i++) {
		neighbors += texture(
			texture0, 
			fragTexCoord +
			kernel[i] / resolution
		).r;
	}
	float self = texture(texture0, fragTexCoord).r;
	neighbors = ceil(neighbors / float(cnt) - 0.5);
	return min(1.0, self + neighbors * neighbors);
}

void main() {
	vec3 avg = average(fragTexCoord);
	finalColor = vec4(closest(fragTexCoord, avg), 1.0);
}
