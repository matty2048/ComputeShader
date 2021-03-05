#version 440
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba32f,binding = 0) uniform image2D img_output;
const float pos_infinity = uintBitsToFloat(0x7F800000);
uniform mat4 CameraToWorld;
uniform mat4 CameraInverseProjection;
uniform samplerCube skybox;
uniform float seed;
float _Seed;
vec2 pix;
struct sphere
{
	vec4 sphere_dat;
	vec4 albedo;
	vec4 specular;
	vec4 emmission;
	vec4 smoothness;
	vec4 transparency;
};

layout(std430,binding = 1) buffer spheres
{
	sphere spher[];
};

float rand(){
	_Seed += 1.0f;
  return fract(sin(_Seed / 100.0f * dot(pix.xy ,vec2(12.9898,78.233))) * 43758.5453);
  
}

struct RayHit
{
	vec3 position;
	float dist;
	vec3 normal;
	vec3 albedo;
	vec3 specular;
	vec3 emmission;
	float smoothness;	
	float transparency;
};
RayHit CreateRayHit()
{
	RayHit hit;
	hit.position = vec3(0.0);
	hit.dist = pos_infinity;
	hit.normal = vec3(0.0);
	hit.emmission = vec3(0.0);
	hit.smoothness = 0.0f;
	hit.transparency = 0.0f;
	return hit;
}
struct Ray
{
	vec3 origin;
	vec3 dir;
};
vec3 at(Ray ray, float t)
{
	return ray.origin + ray.dir*t;
}
Ray CreateRay(vec3 origin,vec3 direction)
{
	Ray ray;
	ray.origin = origin;
	ray.dir = direction;

	return ray;
};

RayHit IntersectSphere(Ray r, sphere S)
{
	RayHit hit = CreateRayHit();

	vec3 oc = r.origin - S.sphere_dat.xyz; 
	float a = dot(r.dir,r.dir);  
	float b = 2 * dot(oc,r.dir); 
	float c = dot(oc,oc);

	float discrim = pow(b,2) - 4*a*c;
	if(discrim < 0)
	{
		return hit;
	}
	float t0 = (-b + sqrt(discrim))/2*a; 
	float t1 = (-b - sqrt(discrim))/2*a;

	float t = max(t0,t1); 
	t = (t0 > 0 && t1 > 0) ?  min(t0,t1): 0 ; 
	
	hit.dist = t;
	hit.position = at(r,t); 
	hit.normal = normalize(hit.position - S.sphere_dat.xyz);
	hit.albedo = S.albedo.xyz;
	hit.smoothness =S.smoothness.x;
	hit.transparency = S.transparency.x;

	return hit;


}

RayHit Trace(Ray ray)
{
	RayHit best = CreateRayHit();
	for(unsigned int i = 0; i<spher.length(); i++){
		RayHit c = IntersectSphere(ray,spheres[i])
		if(c.dist < best.dist)
		{
			best = c
		}
	}
	return best; 
}



Ray CreateCameraRay(vec2 uv)
{
	vec3 origin = (CameraToWorld * vec4(0.0,0.0,0.0,1.0)).xyz; 
	vec3 direction = (CameraInverseProjection * vec4(uv,0.0,1.0)).xyz; 

	direction = (CameraToWorld * vec4(direction,0.0f)).xyz; 
	direction = normalize(direction); 

	return CreateRay(origin,direction);
}

vec3 Shade(inout Ray r, RayHit hit) 
{
	return (hit.dist < pos_infinity) ? vec3(1.0):vec3(0);
}

void main()
{
	uvec2 dims = imageSize(img_output);
	ivec2 pixel_coords = ivec2(gl_WorkGroupID.xy);
	pix = gl_WorkGroupID.xy;
	vec2 PixelOffset = vec2(rand(),rand());
	vec2 uv = vec2((gl_WorkGroupID.xy + (PixelOffset))  / dims * 2.0f - 1.0f);
	vec4 res = vec4(0);
	Ray ray = CreateCameraRay(uv);

	Hit r = Trace(ray);
	res = Shade(r);

	

	imageStore(img_output, pixel_coords, vec4(1) + res);

}