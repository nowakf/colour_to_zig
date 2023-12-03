#version 330
in vec2 fragTexCoord;
uniform sampler2D texture0;
uniform vec2 mouse;
out vec4 finalColor;
float sphere(in vec3 p, in vec3 c, float r) {
	return length(p - c) - r;
}
float bowl( vec3 p, float r, float h, float t)
{
    vec2 q = vec2( length(p.xz), p.y );
        
    float w = sqrt(r*r-h*h);
	        
    return ((h*q.x<w*q.y) ? length(q-vec2(w,h)) : abs(length(q)-r) ) - t;
}

float plane(vec3 p, vec4 n) {
	vec4 tex = texture(texture0, p.xy);
	return dot(p,
	n.xyz 
	) + length(tex.rgb)/3.0 * tex.a + n.w;
	//p.xy is wrong, but it seems to work OK.
	//probably should do some thinking about this to make it more robust
}

float world_map(in vec3 p) {
//	p.xy = (mat2(3,4,-4,3)/5.0)*p.xy;

	return min(
		sphere(p, vec3(0., 0., -0.1), 0.1),
		plane(p, normalize(vec4(0.,0.,1.,0.)))
	);
}

vec3 calc_normal(in vec3 p) {
	//change this to something robust:
	const vec3 small_step = vec3(0.003, 0.0, 0.0);
	float grad_x  = world_map(p + small_step.xyy) - world_map(p - small_step.xyy);
	float grad_y  = world_map(p + small_step.yxy) - world_map(p - small_step.yxy);
	float grad_z  = world_map(p + small_step.yyx) - world_map(p - small_step.yyx);
	return normalize(vec3(grad_x, grad_y, grad_z));
}

vec3 ray_march(in vec3 ro, in vec3 rd) {
	const float clear_color = 0.2;
	float total_dist_traveled = 0.0;
	const int NUM_OF_STEPS = 64;
	const float MIN_HIT_DIST = 0.001;
	const float MAX_TRACE_DIST = 8.0;

	for (int i = 0; i < NUM_OF_STEPS; ++i) {
		vec3 cur_pos = ro + total_dist_traveled * rd;
		float dist_to_closest = world_map(cur_pos);
		if (dist_to_closest < MIN_HIT_DIST) {
			vec3 n = calc_normal(cur_pos);
			vec3 lpos = vec3(-0.577);
			vec3 ldir = normalize(cur_pos - lpos);
			return vec3(max(clear_color, dot(n, ldir)));
		}
		if (total_dist_traveled > MAX_TRACE_DIST) {
			break;
		}
		total_dist_traveled += dist_to_closest;
	}
	return vec3(0.0);
}


void main() {
	//aspect ratio should be corrected:
	vec2 p = fragTexCoord - 0.5;
	//camera target 
	vec3 ro = vec3(0.0, 1.0, 1.0);
	vec3 ta = vec3(0.0);
	//camera mat
	vec3 ww = normalize(ta-ro);
	vec3 uu = normalize(cross(ww, vec3(0.,1.,0.)));
	vec3 vv = normalize(cross(uu, ww));
	//uv aspect ratio needs to be fixed
	finalColor = vec4(ray_march(
		ro,
		normalize(p.x *uu + p.y*vv + 1.5 * ww)
	), 1.0);
}
