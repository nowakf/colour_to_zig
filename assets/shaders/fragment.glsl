#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform sampler2D tex8;
uniform sampler2D tex9;
uniform sampler2D tex10;
uniform sampler2D tex11;
uniform sampler2D tex12;
uniform sampler2D tex13;
uniform sampler2D tex15;
uniform vec4 colDiffuse;

out vec4 finalColor;

const vec4 RED = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 BLUE = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 GREEN = vec4(0.0, 0.0, 0.0, 1.0);

//from SO
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec2 hs(sampler2D s, vec2 uv) {
	vec4 initial = texture(s, uv);
	vec3 col = rgb2hsv(initial.rgb);
	float n = 1.0;
	return col.rg * vec2(1.0, col.b);
}


vec3 hue2rgb(float hue)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(hue + K.xyz) * 6.0 - K.www);
    return clamp(p - K.xxx, 0.0, 1.0);
}


vec2 sample(vec2 uv) {
	vec2 avg = (
		 	hs(tex0, uv)  +
			hs(tex1, uv)  +
			hs(tex2, uv)  +
			hs(tex3, uv)  +
			hs(tex4, uv)  +
			hs(tex5, uv)  +
			hs(tex6, uv)  +
			hs(tex7, uv)  +
			hs(tex8, uv)  +
			hs(tex9, uv)  +
			hs(tex10, uv) +
			hs(tex11, uv) +
			hs(tex12, uv) +
			hs(tex13, uv) +
			hs(tex15, uv)) / 16.;// - 0.15);
	float d0  = max(0.0, 1.0 - distance(avg, hs(tex0, uv)));
	float d1  = max(0.0, 1.0 - distance(avg, hs(tex1, uv)));
	float d2  = max(0.0, 1.0 - distance(avg, hs(tex2, uv)));
	float d3  = max(0.0, 1.0 - distance(avg, hs(tex3, uv)));
	float d4  = max(0.0, 1.0 - distance(avg, hs(tex4, uv)));
	float d5  = max(0.0, 1.0 - distance(avg, hs(tex5, uv)));
	float d6  = max(0.0, 1.0 - distance(avg, hs(tex6, uv)));
	float d7  = max(0.0, 1.0 - distance(avg, hs(tex7, uv)));
	float d8  = max(0.0, 1.0 - distance(avg, hs(tex8, uv)));
	float d9  = max(0.0, 1.0 - distance(avg, hs(tex9, uv)));
	float d10 = max(0.0, 1.0 - distance(avg, hs(tex10, uv)));
	float d11 = max(0.0, 1.0 - distance(avg, hs(tex11, uv)));
	float d12 = max(0.0, 1.0 - distance(avg, hs(tex12, uv)));
	float d13 = max(0.0, 1.0 - distance(avg, hs(tex13, uv)));
	float d14 = max(0.0, 1.0 - distance(avg, hs(tex15, uv)));
	float sum = d0 + d1 + d2 + d3 + d4 + d5 + d6 + d7 + d8 + d9 + d10 + d11 + d12 + d13;
	return (
		 	d0 * hs(tex0, uv)  +
			d1 * hs(tex1, uv)  +
			d2 * hs(tex2, uv)  +
			d3 * hs(tex3, uv)  +
			d4 * hs(tex4, uv)  +
			d5 * hs(tex5, uv)  +
			d6 * hs(tex6, uv)  +
			d7 * hs(tex7, uv)  +
			d8 * hs(tex8, uv)  +
			d9 * hs(tex9, uv)  +
			d10 * hs(tex10, uv) +
			d11 * hs(tex11, uv) +
			d12 * hs(tex12, uv) +
			d13 * hs(tex13, uv) +
			d14 * hs(tex15, uv)) / sum;
	//absolutely disgusting but I gotta dash
}
//from shadertoy, with modifications and some errors introduced
//this should be made into a noise-driven PHI thingy to reduce sample count
//const float TWO_PI = 6.28318530718;
//float gaussian_blur(vec2 uv) {
//	const float directions = 8.0;
//	const float quality = 1.5;
//	const float size = 0.01;
//	vec2 radius = vec2(size);///_resolution.xy;
//	float color = 0.;
//	for (float th=0; th<TWO_PI; th+=TWO_PI/directions) {
//		for (float i=0; i<quality; i+=1.0/quality) {
//			color += sample(uv + vec2(cos(th), sin(th)) * size * i);
//		}
//	}
//	return color / (directions * quality * quality);
//}

void main() {
	//vec4 col = gaussian_blur(fragTexCoord);
	//finalColor = vec4(ceil(hsv.g*2.0-0.2));

	vec2 col = sample(fragTexCoord);

	finalColor = vec4(hue2rgb(col.r)*ceil(col.g - 0.15), 1.0);
}
