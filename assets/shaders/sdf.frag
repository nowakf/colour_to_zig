#version 330
in vec2 fragTexCoord;
uniform sampler2D texture0;
uniform sampler2D noise0;
uniform float aspect;

out vec4 finalColor;

const float CLEAR_COLOUR = 0.2;
const float SKY = 100000000000.0;
const vec3 LIGHT_DIR = vec3(-0.577);

vec3 noise(vec2 co){
    return texture(noise0, co).rgb;
}

float sphere(in vec3 p, in vec3 c, float r) {
	return length(p - c) - r;
}


float height(vec2 p) {
	vec4 tex = texture(texture0, p.xy+0.5);
	return length(tex.rgb);
}

float plane(vec3 p, vec4 n) {
	return dot(p,
	n.xyz 
	) + height(p.xy)*1.2 + n.w;
	//p.xy is wrong, but it seems to work OK.
	//probably should do some thinking about this to make it more robust
}

float plane2(vec3 p) {
	return p.z + height(p.xy);
}

float map(in vec3 p) {
	return min(
		sphere(p, vec3(0., 0., -0.1), 0.1),
		//plane(p, normalize(vec4(0.,0.,0.5,0.)))
		plane2(p)
	);
}

vec3 calc_normal(in vec3 pos) {
	//change this to something robust:
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.009;
    return normalize(   e.xyy*map( pos + e.xyy*eps ) + 
		  	e.yyx*map( pos + e.yyx*eps ) + 
		  	e.yxy*map( pos + e.yxy*eps ) + 
		  	e.xxx*map( pos + e.xxx*eps ) );
}
vec3 ray_march(in vec3 ro, in vec3 rd) {
	float total_dist_traveled = 0.0;
	const int NUM_OF_STEPS = 32;
	const float MIN_HIT_DIST = 0.001;
	const float MAX_TRACE_DIST = 8.0;

	for (int i = 0; i < NUM_OF_STEPS; ++i) {
		vec3 cur_pos = ro + total_dist_traveled * rd;
		float dist_to_closest = map(cur_pos);
		if (dist_to_closest < MIN_HIT_DIST) {
			return ro+(total_dist_traveled+dist_to_closest)*rd;
		}
		if (total_dist_traveled > MAX_TRACE_DIST) {
			break;
		}
		total_dist_traveled += max(0.01, dist_to_closest);
	}
	return vec3(SKY);
}

vec3 albedo(vec3 pos) {
	vec3 warp = noise(pos.xy) * 0.01;
	return texture(noise0, (pos.xy + warp.xy)* 0.01).rgb;
}

float smoothness(vec3 pos) {
	return mix(0., 1., 1.0 - sign(sphere(pos, vec3(0., 0., -0.1), 0.1)));
}

vec3 sky(vec3 dir) {
	return vec3(0.9, 0.9, 1.0);
}

float specular(in vec3 rd, in vec3 n) {
	return pow(max(CLEAR_COLOUR, dot(reflect(LIGHT_DIR, n), rd)), 3.0);
}

float diffuse(in vec3 n) {
	return max(CLEAR_COLOUR, dot(n, LIGHT_DIR));
}



void main() {
	//aspect ratio should be corrected:
	vec2 p = (fragTexCoord - 0.5) * vec2(aspect, 1.0);
	//camera target 
	vec3 ro = vec3(0.0, 0.5, 0.5);
	vec3 ta = vec3(0.0);
	//camera mat
	vec3 ww = normalize(ta-ro);
	vec3 uu = normalize(cross(ww, vec3(0.,1.,0.)));
	vec3 vv = normalize(cross(uu, ww));
	//uv aspect ratio needs to be fixed
	vec3 rd =  normalize(p.x *uu + p.y*vv + 1.5 * ww);

	vec3 hit = ray_march(ro, rd);
	vec3 n = calc_normal(hit);
	vec3 col_a = diffuse(n) * albedo(hit) + specular(rd, n) * smoothness(hit);
	
	vec3 ref = reflect(rd, n);
	vec3 bounce = ray_march(hit+ref*0.01, ref+noise(p)*(1.0-smoothness(hit)));
	vec3 bn = calc_normal(bounce);
	float is_sky = ceil(length(bounce/SKY+0.5));
	vec3 col_b =  mix(
		diffuse(bn) * albedo(bounce) + specular(ref, bn) * smoothness(bounce),
		sky(bn),
		is_sky
	);

	finalColor = vec4((col_a * 0.75 + col_b * 0.25), 1.0);
}
