#version 330
in vec2 fragTexCoord;
uniform sampler2D texture0;
uniform sampler2D noise0;
uniform sampler2D noise1;
uniform sampler2D surface;
uniform sampler2D depths;
uniform float aspect;
uniform float time;

out vec4 finalColor;
const int BOUNCES = 5;
const vec4 SPHERE_VALS = vec4(0.,-0.09,-0.1, 0.08);
const float HEIGHT_FACTOR = 0.5;
const float CLEAR_COLOUR = 0.0;
const float SKY = 100000.0;
const vec3 LIGHT_DIR = vec3(0.577);
const float EPS = 0.001;
const float MIN_HIT_DIST = EPS;
const float NORM_STEP = 0.002;
const float CLEARANCE = 0.1;
const int NUM_OF_STEPS = 32;
const float MAX_TRACE_DIST = 8.0;

vec3 noise(vec2 co){
    return texture(noise0, co).rgb;
}

float sphere(in vec3 p, in vec3 c, float r) {
	return length(p - c) - r;
}


float height(vec2 p) {
	vec4 tex = texture(texture0, p.xy+0.5);
	return length(tex.rgb)/3.0;
}

float plane(vec3 p) {
	return p.z + height(p.xy) * HEIGHT_FACTOR;
}

float map(in vec3 p) {
	return min(
		sphere(p, SPHERE_VALS.xyz, SPHERE_VALS.w),
		plane(p)
	);
}

vec3 calc_normal(in vec3 pos) {
    vec2 e = vec2(1.0,-1.0)*0.5773;
    return normalize(   e.xyy*map( pos + e.xyy*NORM_STEP) + 
		  	e.yyx*map( pos + e.yyx*NORM_STEP) + 
		  	e.yxy*map( pos + e.yxy*NORM_STEP) + 
		  	e.xxx*map( pos + e.xxx*NORM_STEP) );
}
vec3 ray_march(in vec3 ro, in vec3 rd) {
	float total_dist_traveled = 0.0;

	for (int i = 0; i < NUM_OF_STEPS; ++i) {
		vec3 cur_pos = ro + total_dist_traveled * rd;
		float dist_to_closest = map(cur_pos);
		if (dist_to_closest < MIN_HIT_DIST) {
			return ro+(total_dist_traveled+dist_to_closest)*rd;
		}
		if (total_dist_traveled > MAX_TRACE_DIST) {
			break;
		}
		total_dist_traveled += max(EPS, dist_to_closest);
	}
	return vec3(SKY);
}

float smoothness(vec3 pos) {
	return 1.0 - max(0.0, sign(
	sphere(pos, SPHERE_VALS.xyz, SPHERE_VALS.w) 
	- MIN_HIT_DIST));
}

vec3 albedo(vec3 pos) {
	vec2 uv = pos.xy + 0.5;
	float z = height(pos.xy)*3.;
	float high_contrast = fract(pow(abs(z + 0.5), 3.0));
	float scale = texture(noise1, uv).r;
	return mix(mix(
		texture(depths, uv).rgb * vec3(1.0, 1.0, 0.8),
		texture(surface, uv+time*noise(pos.xy*0.01).xy*0.1*scale).rgb * vec3(0.05, 0.05, 0.4),
		z
	), vec3(0.8,0.8,0.), smoothness(pos)*0.1);
}

vec3 sky(vec3 dir) {
	return vec3(1.0, 0.9, 0.9);
}

float specular(in vec3 rd, in vec3 n) {
	return pow(max(CLEAR_COLOUR, dot(reflect(LIGHT_DIR, n), rd)), 5.0);
}

float diffuse(in vec3 n) {
	return max(CLEAR_COLOUR, dot(n, LIGHT_DIR));
}



void main() {
	//aspect ratio should be corrected:
	vec2 p = (fragTexCoord - 0.5) * vec2(aspect, 1.0);
	//camera target 
	vec3 ro = vec3(0.0, 0.4, 0.5);
	vec3 ta = vec3(0.0);
	//camera mat
	vec3 ww = normalize(ta-ro);
	vec3 uu = normalize(cross(ww, vec3(0.,1.,0.)));
	vec3 vv = normalize(cross(uu, ww));
	vec3 rd =  normalize(p.x *uu + p.y*vv + 1.5 * ww);

	vec3 hit = ray_march(ro, rd);
	vec3 n = calc_normal(hit);
	vec3 col_a = diffuse(n) * albedo(hit) * (1.0-smoothness(hit)) + specular(rd, n) * smoothness(hit) * albedo(hit);

	vec3 shadow = ray_march(hit, LIGHT_DIR);

	col_a *= 1.0 - floor(length(shadow/SKY+EPS))*0.5;

	vec3 col_b = vec3(0.0);
	
	for (int i=0; i<BOUNCES; i++) {
		vec3 ref = reflect(rd, n);
		vec3 bounce = ray_march(
				hit+ref*CLEARANCE, 
				normalize((ref + 
					mix(noise(p.xy+float(i)),
						ref,
						smoothness(hit)
					)) /2.0) * -sign(0.5-smoothness(hit))
		);
		vec3 bn = calc_normal(bounce);
		float is_sky = ceil(length(bounce/vec3(SKY))-0.9);
		col_b +=  mix(
			diffuse(bn) * albedo(bounce) + specular(ref, bn) * smoothness(bounce),
			sky(bn),
			is_sky
		);
	}
	col_b /= float(BOUNCES);

	finalColor = vec4((col_a*0.75+col_b*0.25), 1.0);
}
