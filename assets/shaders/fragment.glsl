#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

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
uniform sampler2D tex14;
uniform sampler2D tex15;
uniform vec4 colDiffuse;

out vec4 finalColor;

//from SO
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + 1.0), q.x);
}
//from shadertoy, with modifications and some errors introduced
const float TWO_PI = 6.28318530718;
vec4 gaussian_blur(vec2 uv) {
	const float directions = 16.0;
	const float quality = 3.0;
	const float size = 0.003;
	vec2 radius = vec2(size);///_resolution.xy;
	vec4 color = texture(tex0, uv);
	for (float th=0; th<TWO_PI; th+=TWO_PI/directions) {
		for (float i=0; i<quality; i+=1.0/quality) {
			color += texture(tex0, uv + vec2(cos(th), sin(th)) * size * i);
		}
	}
	return color / (directions * quality * quality);
}

void main() {
	vec4 col = gaussian_blur(fragTexCoord);
	vec3 hsv = rgb2hsv(col.rgb);
	//finalColor = vec4(ceil(hsv.g*2.0-0.2));
	finalColor = 
	( texture(tex0, fragTexCoord) 
	+ texture(tex1, fragTexCoord) 
	+ texture(tex2, fragTexCoord) 
	+ texture(tex3, fragTexCoord) 
	+ texture(tex4, fragTexCoord) 
	+ texture(tex5, fragTexCoord) 
	+ texture(tex6, fragTexCoord)
	+ texture(tex7, fragTexCoord) 
	+ texture(tex8, fragTexCoord) 
	+ texture(tex9, fragTexCoord) 
	+ texture(tex10, fragTexCoord) 
	+ texture(tex11, fragTexCoord) 
	+ texture(tex12, fragTexCoord) 
	+ texture(tex13, fragTexCoord) 
	+ texture(tex14, fragTexCoord) 
	+ texture(tex15, fragTexCoord)) / 15.0;
}
