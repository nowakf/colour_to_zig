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

float average(vec2 pos) {
	float a = texture(texture0, pos).a;
	vec2 resolution = textureSize(texture0, 0);
	for (int i=0; i<cnt; i++) {
		a += texture(
			texture0, 
			pos +
			kernel[i] / resolution
		).a;
	}
	return a / float(cnt+1);
}

float closest(vec2 pos, float ref) {
	vec2 resolution = textureSize(texture0, 0);
	float o = texture(texture0, pos).a;
	float min = abs(ref-o);
	for (int i=0; i<cnt; i++) {
		float tmp = texture(
			texture0,
			pos + kernel[i] / resolution
		).a;
		if (abs(ref-tmp) < min) {
			min = abs(ref-tmp);
			o = tmp;
		}
	}
	return o;
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
	vec4 col = texture(texture0, fragTexCoord);
	float avg = average(fragTexCoord);
	finalColor = vec4(col.rgb, closest(fragTexCoord, avg));
}
