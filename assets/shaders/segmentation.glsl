#version 330
in vec2 fragTexCoord;

uniform sampler3D texture0;

out vec4 finalColor;

const float SAMPLES = 10.0;

const float PI = 3.14; //update!
const float HALF_GOLDEN_ANGLE = 1.1999816148643266611157777533165;
const int TH_SAMPLES = 8;

float noise(vec2 pt) {
	return fract(sin(dot(pt, vec2(12.9898, 4.1414))) * 43758.5453);
}
//from SO
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e+0.1), q.x);
}

vec4 golden_gaussian_3d(vec2 center) {
	vec3 scale = float(TH_SAMPLES) / 2.0 / textureSize(texture0, 0);
	vec4 color = vec4(0.0);
	float initial = noise(center) * (2.0 * PI);
	for (int i = 0; i<TH_SAMPLES; i++) {
		float theta = initial + HALF_GOLDEN_ANGLE * i; //prolly wrong
		float phi = acos(1.0 - 2.0*(float(i)+0.5) / float(TH_SAMPLES));
		vec3 norm = vec3(cos(theta) * sin(phi), sin(theta) * sin(phi), cos(phi));
		color += vec4(texture(texture0, vec3(center, 0.0)+norm*scale*noise(norm.xy)));
	}
	return color / float(TH_SAMPLES);
}


void main() {
	//finalColor = golden_gaussian_3d(fragTexCoord);
	vec4 gauss = golden_gaussian_3d(fragTexCoord);
	vec3 hsv = rgb2hsv(gauss.rgb);
	finalColor = textureLod(texture0, vec3(fragTexCoord, 0.5), 2);
}
