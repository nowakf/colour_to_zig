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
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e + 1.0), q.x);
}

float hsv(sampler2D s, vec2 uv) {
	vec4 initial = texture(s, uv);
	vec3 col = rgb2hsv(initial.rgb);
	float n = 1.0;
	return col.g *(n-fwidth(col.b))* (n-fwidth(col.r)) * (n-fwidth(col.g));
}


float sample(vec2 uv) {
	return
			(hsv(tex0, uv)  +
			hsv(tex1, uv)  +
			hsv(tex2, uv)  +
			hsv(tex3, uv)  +
			hsv(tex4, uv)  +
			hsv(tex5, uv)  +
			hsv(tex6, uv)  +
			hsv(tex7, uv)  +
			hsv(tex8, uv)  +
			hsv(tex9, uv)  +
			hsv(tex10, uv) +
			hsv(tex11, uv) +
			hsv(tex12, uv) +
			hsv(tex13, uv) +
			hsv(tex15, uv)) / 16.;// - 0.15);
}
//from shadertoy, with modifications and some errors introduced
//this should be made into a noise-driven PHI thingy to reduce sample count
const float TWO_PI = 6.28318530718;
float gaussian_blur(vec2 uv) {
	const float directions = 8.0;
	const float quality = 1.5;
	const float size = 0.01;
	vec2 radius = vec2(size);///_resolution.xy;
	float color = 0.;
	for (float th=0; th<TWO_PI; th+=TWO_PI/directions) {
		for (float i=0; i<quality; i+=1.0/quality) {
			color += sample(uv + vec2(cos(th), sin(th)) * size * i);
		}
	}
	return color / (directions * quality * quality);
}

void main() {
	//vec4 col = gaussian_blur(fragTexCoord);
	//finalColor = vec4(ceil(hsv.g*2.0-0.2));

	float col = sample(fragTexCoord);

	finalColor = vec4(col*2.);
}
