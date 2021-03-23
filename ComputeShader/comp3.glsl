#version 440

const int numsamples = 16;
const float pos_infinity = uintBitsToFloat(0x7F800000);
const float EPSILON = 1*pow(10,-8);

layout(local_size_x = 16, local_size_y = 16) in;
layout(rgba32f,binding = 0) uniform image2D img_output;
uniform mat4 CameraToWorld;
uniform mat4 CameraInverseProjection;
uniform samplerCube skybox;
uniform float seed;
shared vec4 pixel[numsamples];
uniform float power;
uniform float k;

vec2 PixelOffset;
const float PI = 3.14159265f;
vec2 pix;
float _Seed; 

float rand(){
	_Seed += 1.0f;
  return fract(sin(_Seed / 100.0f * dot(pix.xy ,vec2(12.9898,78.233))) * 43758.5453);
  
}
struct Ray
{
	vec3 origin;
	vec3 dir;
	vec3 energy;
	vec3 absorb;
};

Ray CreateRay(vec3 origin,vec3 direction)
{
	Ray ray;
	ray.origin = origin;
	ray.dir = direction;
	ray.energy = vec3(1.0);
	ray.absorb = vec3(0.);
	return ray;
};

Ray CreateCameraRay(vec2 uv)
{
	vec3 origin = (CameraToWorld * vec4(0.0,0.0,0.0,1.0)).xyz;
	vec3 direction = (CameraInverseProjection * vec4(uv,0.0,1.0)).xyz;

	direction = (CameraToWorld * vec4(direction,0.0f)).xyz;
	direction = normalize(direction);

	return CreateRay(origin,direction);
};


vec3 at(Ray ray, float t)
{
	return ray.origin + ray.dir*t;
}

struct RayHit
{
	vec3 position;
	float dist;
	vec3 normal;
	vec3 albedo;
	
};
RayHit CreateRayHit()
{
	RayHit hit;
	hit.position = vec3(0.0);
	hit.dist = pos_infinity;
	hit.normal = vec3(0.0);
	
	return hit;
}

float DE(vec3 pos) {
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	int Iterations = 500;
	float Power = power;
	float Bailout = 3000;
	for (int i = 0; i < Iterations ; i++) {
		r = length(z);
		if (r>Bailout) break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y,z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 0.1;
		
		// scale and rotate the point
		float zr = pow( r,Power);
		theta = theta*Power;
		phi = phi*Power;
		
		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z+=pos;
	}




	return 0.5*log(r)*r/dr;
}



//float DE(vec3 z)
//{
//	vec3 a1 = vec3(1,1,1);
//	vec3 a2 = vec3(-1,-1,1);
//	vec3 a3 = vec3(1,-1,-1);
//	vec3 a4 = vec3(-1,1,-1);
//	vec3 c;
//	int n = 0;
//	float Scale = 2;
//	int Iterations = 4;
//	float dist, d;
//	while (n < Iterations) {
//		 c = a1; dist = length(z-a1);
//	        d = length(z-a2); if (d < dist) { c = a2; dist=d; }
//		 d = length(z-a3); if (d < dist) { c = a3; dist=d; }
//		 d = length(z-a4); if (d < dist) { c = a4; dist=d; }
//		z = Scale*z-c*(Scale-1.0);
//		n++;
//	}
//
//	return length(z) * pow(Scale, float(-n));
//}

//float DE(vec3 z)
//{
//  z.xy = mod((z.xy),1.0) - vec2(0.5); // instance on xy-plane
//  return length(z)-0.3;             // sphere DE
//}


void IntersectFractal(inout RayHit BestHit,Ray ray)
{
	float t = 0;
	float dt = 0; //sets the initial distance estimate to infinity
	vec3 from = ray.origin; //gets the origin location of the ray
	vec3 direction = ray.dir; //the direction of the ray
	int MaximumRaySteps = 200;
	float totalDistance = 0;
	float MinimumDistance = 0.000001;
	float mindist = pos_infinity;
	int steps;
	for (steps = 0; steps < MaximumRaySteps; steps++) {
		ray.origin = from + totalDistance * direction;
		float dist = DE(ray.origin);
		totalDistance += dist;
		mindist = min(mindist,dist);
		if (dist < MinimumDistance) break;
	}

	
	t = totalDistance;
	if(t > 100) t = pos_infinity;
	else
	if (t > 0 && t < BestHit.dist)
	{
	vec3 pos = at(ray,t);
	vec3 xDir = vec3(1,0,0);
	vec3 yDir = vec3(0,1,0);
	vec3 zDir = vec3(0,0,1);
	

	vec3 n = normalize(vec3(DE(pos+xDir)-DE(pos-xDir),
		                DE(pos+yDir)-DE(pos-yDir),
		                DE(pos+zDir)-DE(pos-zDir)));

		BestHit.dist = t;
		BestHit.position = at(ray,t);
		BestHit.normal = -n;
		BestHit.albedo = mix(vec3(0.01),vec3( (sin(mindist * 100000) *sin(steps * 0.003))  ,steps * 0.02 ,steps * 0.01),clamp(exp(- steps  * (0.005 * k)),0,1));
		
		
	}
	
}

RayHit Trace(Ray ray)
{
	RayHit BestHit = CreateRayHit();
	
	IntersectFractal(BestHit,ray);
	//if(AABB_Intersect(ray,pos[0].xyz,pos[1].xyz)){
	//	for( int i = 0; i < triangles.length(); i+=1)
	//	{
	//	IntersectTriangle_MT97(ray,triangles[i].point[0].xyz,
	//								triangles[i].point[1].xyz,
	//								triangles[i].point[2].xyz, 
	//								BestHit, 
	//								int(MaterialID.x));
	//	}
	//}

	return BestHit;
};

vec3 Shade(Ray r, RayHit hit)
{
	return hit.albedo;
}

void main(){
	ivec2 pixel_coords;
	_Seed = seed;
	pixel_coords = ivec2(gl_GlobalInvocationID.xy);
	pix = gl_GlobalInvocationID.xy;
	uvec2 dims = imageSize(img_output);


	vec3 result = vec3(0.0f);
	PixelOffset = vec2(rand(),rand());
	vec2 uv = vec2((gl_GlobalInvocationID.xy + (PixelOffset))  / dims * 2.0f - 1.0f);
	Ray ray = CreateCameraRay(uv);

		
	RayHit hit = Trace(ray);
	vec3 rayenergytemp = ray.energy;
	result = Shade(ray,hit);
	imageStore(img_output, pixel_coords, vec4(result,0));
	return;
}	  

	