#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

const float TWO_PI = 6.28318530718;

vec4 gaussian_blur(vec2 uv) {
	const float directions = 8.0;
	const float quality = 3.0;
	const float size = 0.006;
	vec2 radius = vec2(size);///_resolution.xy;
	vec4 color = texture(texture0, uv);
	for (float th=0; th<TWO_PI; th+=TWO_PI/directions) {
		for (float i=0; i<quality; i+=1.0/quality) {
			color += texture(texture0, uv + vec2(cos(th), sin(th)) * size * i);
		}
	}
	return color / (directions * quality * quality);
}

void main() {
	vec4 col = gaussian_blur(fragTexCoord.xy);
	if (length(col) > 1.5) {
		finalColor = col;
	} else {
		finalColor = vec4(0.0);
	}

}
