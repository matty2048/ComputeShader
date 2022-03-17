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

struct mat{
	vec4 albedo;
	vec4 specular;
	vec4 emmission;
	vec4 smoothness;
	vec4 transparency;
	vec4 volumetric;
};

struct sphere
{
	vec4 sphere_dat;
	vec4 MaterialID;
};

struct tris
{
	vec4 point[3];
};


layout(std430,binding = 1) buffer S
{
	sphere spher[];
};

layout(std430,binding = 2) buffer M
{
	mat Material[];
};

layout(std430,binding = 3) buffer V 
{
	vec4 pos[2]; //2 points on box outlining mesh
	vec4 MaterialID;
	tris triangles[];
};

layout(std430, binding = 4) buffer I{
	unsigned int Index[];
};



struct Box
{
	vec4 minpos;
	vec4 maxpos;

	int triptr; //start of triangle index
	int nrtri;  //number of triangles
	ivec2 pad;
};

layout(std430,binding =5) buffer BBs
{
	Box boxes[];
};


struct Node
{
	int BBref;
	uint child[4];
};

layout(std430,binding = 6) buffer QT
{
	Node Nodes[];
};

//vec3 direction = normalize(vec3(-0.6f,-0.6f,-0.5f));
//vec4 directional_light = vec4(direction,0.9);



vec2 PixelOffset;
const float PI = 3.14159265f;
vec2 pix;
float _Seed; 

float rand(){
	_Seed += 1.0f;
  return fract(sin(_Seed / 100.0f * dot(pix.xy ,vec2(12.9898,78.233))) * 43758.5453);
  
}

mat3 GetTangentSpace(vec3 normal)
{
	vec3 helper = vec3(1.0,0.0,0.0);
	if(abs(normal.x) > 0.99) helper = vec3(0,0,1);

	vec3 tangent = normalize(cross(normal,helper));
	vec3 binormal =  normalize(cross(normal,tangent));
	return mat3(tangent,binormal,normal);
}

vec3 SampleHemisphere(vec3 normal,float alpha)
{
	float cosTheta = pow(rand(),1.0f/(alpha+1.0f));
	float sinTheta = sqrt(1.0f-pow(cosTheta,2));
	float phi = 2 * PI * rand();
	vec3 tangentSpaceDir = vec3(cos(phi) * sinTheta, sin(phi) * sinTheta,cosTheta);
	return GetTangentSpace(normal)* tangentSpaceDir;
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
	vec3 specular;
	vec3 emmission;
	float smoothness;	
	vec3 transparency;
	vec4 volumetric;
	float ior;
	bool inside;
};
RayHit CreateRayHit()
{
	RayHit hit;
	hit.position = vec3(0.0);
	hit.dist = pos_infinity;
	hit.normal = vec3(0.0);
	hit.emmission = vec3(0.0);
	hit.smoothness = 0.0f;
	hit.transparency = vec3(0.0f);
	hit.ior = 0;
	hit.volumetric = vec4(0);
	hit.inside = false;
	return hit;
}


bool IntersectTriangle_MT97(Ray ray, vec3 vert0, vec3 vert1, vec3 vert2,
     inout RayHit BestHit, int MatID)
{
    float t;
	float u; 
	float v;
    // find vectors for two edges sharing vert0
    vec3 edge1 = vert1 - vert0;
    vec3 edge2 = vert2 - vert0;
    // begin calculating determinant - also used to calculate U parameter
    vec3 pvec = cross(ray.dir, edge2);
    // if determinant is near zero, ray lies in plane of triangle
    float det = dot(edge1, pvec);
    // use backface culling
	float norm_mult = 1;
    if (det < EPSILON) norm_mult = -1;
    float inv_det = 1.0f / det;
    // calculate distance from vert0 to ray origin
    vec3 tvec = ray.origin - vert0;
    // calculate U parameter and test bounds
    u = dot(tvec, pvec) * inv_det;
    if (u < 0.0 || u > 1.0f)
        return false;
    // prepare to test V parameter
    vec3 qvec = cross(tvec, edge1);
    // calculate V parameter and test bounds
    v = dot(ray.dir, qvec) * inv_det;
    if (v < 0.0 || u + v > 1.0f)
        return false;
    // calculate t, ray intersects triangle
    t = dot(edge2, qvec) * inv_det;
    if((t > 0) && (t < BestHit.dist)){
		BestHit.dist = t;
        BestHit.position = ray.origin + t * ray.dir;
        BestHit.normal = normalize(cross(vert1 - vert0, vert2 - vert0)) * norm_mult;
		BestHit.albedo = Material[MatID].albedo.xyz;
		BestHit.specular = Material[MatID].specular.xyz;
		BestHit.emmission = Material[MatID].emmission.xyz; 
		BestHit.smoothness = Material[MatID].smoothness.x;
		BestHit.transparency = Material[MatID].transparency.xyz;
		}
}
void intersectsphere(Ray ray,inout RayHit bestHit, sphere sphere)
{
	vec3 oc = ray.origin - sphere.sphere_dat.xyz;
	float a = dot(ray.dir,ray.dir);
	float b = 2.0 * dot(oc,ray.dir);
	float c = dot(oc,oc) - pow(sphere.sphere_dat.w,2);
	float descrim = pow(b,2) - 4*a*c;
	if(descrim < 0){
		return;
	}
	else{
		 float tmin = min((-b - sqrt(descrim)) / (2.0*a), (-b + sqrt(descrim)) / (2.0*a));
		 float t0 = min((-b - sqrt(descrim)) / (2.0*a) > 0 ? (-b - sqrt(descrim)) / (2.0*a):(-b + sqrt(descrim)) / (2.0*a),(-b + sqrt(descrim)) / (2.0*a) > 0 ? (-b + sqrt(descrim)) / (2.0*a):0);

		 if( t0 > 0 && t0 < bestHit.dist)
		 {
			bestHit.dist = t0;
			bestHit.position = at(ray,t0);
			bestHit.normal = normalize(bestHit.position - sphere.sphere_dat.xyz);
			bestHit.albedo = Material[int(sphere.MaterialID.x)].albedo.xyz;
			bestHit.specular = Material[int(sphere.MaterialID.x)].specular.xyz;
			bestHit.emmission = Material[int(sphere.MaterialID.x)].emmission.xyz;
			bestHit.smoothness = Material[int(sphere.MaterialID.x)].smoothness.x;
			
			bestHit.transparency = Material[int(sphere.MaterialID.x)].transparency.xyz;
			
			bestHit.ior = Material[int(sphere.MaterialID.x)].transparency.y/1;
			bestHit.volumetric = Material[int(sphere.MaterialID.x)].volumetric;

			if(tmin < 0.0f){
				bestHit.inside = true;
				bestHit.normal *= -1;
			}//if inside sphere
			else {
				bestHit.inside = false;
				bestHit.ior = 1/Material[int(sphere.MaterialID.x)].transparency.y; //if outside sphere
			}
		}
	}
}



void IntersectGroundPlain(Ray ray, inout RayHit BestHit)
{
	float t = ((-ray.origin.y-1.5) / ray.dir.y) ;
	if (t > 0 && t < BestHit.dist)
	{
		BestHit.dist = t;
		BestHit.position = at(ray,t);

		BestHit.normal = vec3(0.0,1.0,0.0);
		BestHit.albedo = vec3(0.6,0.7,0.8);
		BestHit.specular = vec3(0.5);
		BestHit.emmission = vec3(0.0);
		BestHit.smoothness = 0.9f;
		BestHit.transparency = vec3(0.0f);
	}
};



void swap(inout float  i, inout float j)
{
	float t = i;
	i = j;
	j = t;
}

bool AABB_Intersect(Ray ray, vec3 min_p, vec3 max_p) //checks for an intersection with a box
{
     float tmin = (min_p.x - ray.origin.x) / ray.dir.x; 
    float tmax = (max_p.x - ray.origin.x) / ray.dir.x; 
 
    if (tmin > tmax) swap(tmin, tmax); 
 
    float tymin = (min_p.y - ray.origin.y) / ray.dir.y; 
    float tymax = (max_p.y - ray.origin.y) / ray.dir.y; 
 
    if (tymin > tymax) swap(tymin, tymax); 
 
    if ((tmin > tymax) || (tymin > tmax)) 
        return false; 
 
    if (tymin > tmin) 
        tmin = tymin; 
 
    if (tymax < tmax) 
        tmax = tymax; 
 
    float tzmin = (min_p.z - ray.origin.z) / ray.dir.z; 
    float tzmax = (max_p.z - ray.origin.z) / ray.dir.z; 
 
    if (tzmin > tzmax) swap(tzmin, tzmax); 
 
    if ((tmin > tzmax) || (tzmin > tmax)) 
        return false; 
 
    if (tzmin > tmin) 
        tmin = tzmin; 
 
    if (tzmax < tmax) 
        tmax = tzmax; 
	
    return true; 
	

}

float DE(vec3 pos) {
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	int Iterations = 10;
	float Power = power;
	float Bailout = 10;
	for (int i = 0; i < Iterations ; i++) {
		r = length(z);
		if (r>Bailout) break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y,z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;
		
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


//void IntersectFractal(inout RayHit BestHit,Ray ray)
//{
//	float t = 0;
//	float dt = 0; //sets the initial distance estimate to infinity
//	vec3 from = ray.origin; //gets the origin location of the ray
//	vec3 direction = ray.dir; //the direction of the ray
//	int MaximumRaySteps = 100;
//	float totalDistance = 0;
//	float MinimumDistance = 0.000000001;
//	float mindist = pos_infinity;
//	int steps;
//	for (steps = 0; steps < MaximumRaySteps; steps++) {
//		ray.origin = from + totalDistance * direction;
//		float dist = DE(ray.origin);
//		totalDistance += dist;
//		mindist = min(mindist,dist);
//		if (dist < MinimumDistance) break;
//	}
//
//	
//	t = totalDistance;
//	if(t > 100) t = pos_infinity;
//	else
//	if (t > 0 && t < BestHit.dist)
//	{
//	vec3 pos = at(ray,t);
//	vec3 xDir = vec3(1,0,0);
//	vec3 yDir = vec3(0,1,0);
//	vec3 zDir = vec3(0,0,1);
//	vec3 n = normalize(vec3(DE(pos+xDir)-DE(pos-xDir),
//		                DE(pos+yDir)-DE(pos-yDir),
//		                DE(pos+zDir)-DE(pos-zDir)));
//
//		BestHit.dist = t;
//		BestHit.position = at(ray,t);
//		BestHit.normal = -n;
//		BestHit.albedo = vec3(1.,1.,1.) * 10/steps;
//		BestHit.specular = vec3(0);
//		BestHit.emmission = vec3(0.0);
//		BestHit.smoothness = 0;
//		BestHit.transparency = vec3(0.0f,0,0);
//		
//	}
//	
//}
int len = Index.length()/3;
RayHit Trace(Ray ray)
{
	RayHit BestHit = CreateRayHit();
	IntersectGroundPlain(ray,BestHit);
	for (int jj =0; jj < spher.length(); jj++)
	{
		intersectsphere(ray,BestHit,spher[jj]);
	}
	//IntersectFractal(BestHit,ray);
	if(AABB_Intersect(ray,pos[0].xyz,pos[1].xyz)){
		for( int i = 0; i < len; i+=1)
		{
		IntersectTriangle_MT97(ray,triangles[i].point[0].xyz,
									triangles[i].point[1].xyz,
									triangles[i].point[2].xyz, 
									BestHit, 
									int(MaterialID.x));
		}
	}

	return BestHit;
};
float sdot(vec3 x, vec3 y,float f)
{
	
	return clamp(dot(x,y)*f,0.0,1.0); //takes dot product, multiplies by f and clamps to between 0 & 1
}
float energy(vec3 color)
{
	return dot(color,vec3(1.0f/0.3f));
}
float SmoothnessToPhongAlpha(float s)
{
    return pow(1000.0f, s * s);
}


float fresnel(vec3 v, vec3 n, float ior)
{
	float kr = 0;
	float cosi = dot(v,n);
	float etai = 1, etat = ior;
	if(cosi > 0) swap(etai,etat);
	float sint = etai / etat * sqrt(max(0.f, 1 - cosi * cosi)); 
	if (sint >= 1) { //total internal reflection
        kr = 1; 
    } else { 
        float cost = sqrt(max(0.f, 1 - sint * sint)); 
        cosi = abs(cosi); 
        float Rs = ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost)); 
        float Rp = ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost)); 
        kr = (Rs * Rs + Rp * Rp) / 2; 
    } 
	return 1-kr;
}

vec3 Shade(inout Ray ray, RayHit hit)
{
	float roulette = rand();
	float dist = distance(ray.origin , hit.position);

		if(hit.dist < pos_infinity)
		{
			if(hit.volumetric.x > 0 )
			{
				ray.origin = hit.position - hit.normal*0.001; //moves ray into sphere
				if(!hit.inside){ ray.absorb = vec3(0.1,0.1,0.1) * 7; }
				if(hit.inside){ 
								ray.energy *= exp(-dist * ray.absorb);
								ray.absorb = vec3(0);
				}
				return hit.emmission;
			}

			if(hit.transparency.x * fresnel(ray.dir,hit.normal,hit.transparency.y)  >  rand()){ 
				float dist = distance(ray.origin , hit.position); //returns how far the ray has traveled inside the medium
				ray.origin = hit.position - hit.normal*0.001; //moves ray into sphere
				//if(hit.ior > 1) ray.energy *= exp(-dist * vec3(0,0.9,0.9) * 2); //calculates the light only runs for the ray within the 
				if(hit.ior < 1)	{
				
					ray.dir = refract(ray.dir,hit.normal, hit.ior);
					ray.absorb += vec3(hit.volumetric.yzw) * 10;
				}
				if(hit.ior > 1){
					float alpha = SmoothnessToPhongAlpha(hit.smoothness);
					ray.dir = SampleHemisphere(refract(ray.dir,hit.normal,hit.ior),alpha);
					ray.energy *= exp(-dist * ray.absorb);
					ray.absorb -= vec3(hit.volumetric.yzw) * 10;
				}
				return hit.emmission;
			}

			hit.albedo = min(1.0-hit.specular,hit.albedo);
			float specChance = energy(hit.specular);
			float DiffChance = energy(hit.albedo);

			float sum = specChance + DiffChance;
			specChance /= sum;
			DiffChance /= sum;

			if(roulette < specChance)
			{ 
				//specular shading
				float alpha = SmoothnessToPhongAlpha(hit.smoothness); //gets an alpha from a smoothness
				ray.origin = hit.position + hit.normal * 0.001; //moves the origin of the ray slightly away from the sphere
				ray.dir = SampleHemisphere(reflect(ray.dir,hit.normal),alpha); //samples from the hemisphere in the perfect reflection direction
				float f = (alpha + 2)/(alpha + 1);   //some magic
				ray.energy *= (1.0f/specChance)*hit.specular*sdot(hit.normal,ray.dir,f) * exp(-dist * ray.absorb); //updates the rays energy 
			}
			else{
				//diffuse shading
				ray.origin = hit.position + hit.normal *0.001; //moves away from object slightly to avoid acne 
				ray.dir = SampleHemisphere(hit.normal,1.0f); //looks in circle centred arround the hit point
				ray.energy *= (1.0f/DiffChance) * 2 * hit.albedo * sdot(hit.normal,ray.dir,1.0f)* exp(-dist * ray.absorb);; //updates ray energy
			}

			return hit.emmission;
		}
		else
		{
			ray.energy = vec3(0.0f);
			return texture(skybox,ray.dir).rgb;

		}
	
};

bvec3 testrayenergy(vec3 energy){
	return bvec3(energy.x > 0.0,energy.y > 0.0,energy.z > 0.0);
};


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
	for(int i = 0; i<5; i++)
	{
		if(!any(testrayenergy(ray.energy))) break;
		RayHit hit = Trace(ray);
		vec3 rayenergytemp = ray.energy;
		result += rayenergytemp * Shade(ray,hit);
	}	  

	imageStore(img_output, pixel_coords, vec4(result,0));
	return;
}



//just in case i mess up
		//if(hit.transparency.x * fresnel(ray.dir,hit.normal,hit.transparency.y)  > rand()){ 
		//	float dist = distance(ray.origin , hit.position); //returns how far the ray has traveled inside the medium
		//	ray.dir = refract(ray.dir,hit.normal, hit.ior);
		//	ray.origin = hit.position - hit.normal*0.001; //moves ray into sphere
		//	if(hit.ior > 1) ray.energy *= exp(-dist * vec3(0,0.9,0.9) * 2); //calculates the light only runs for the ray within the 
		//	return hit.emmission;
		//}