#version 430
const float pos_infinity = uintBitsToFloat(0x7F800000);
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba32f,binding = 0) uniform image2D img_output;
struct sphere
{
	vec4 sphere_dat;
};

layout(std430,binding = 1) buffer spheres
{
	sphere spher[];
};
layout(std430,binding = 2) buffer plains
{
	vec4 plain_dat;
};
struct ray
{
	vec3 o;
	vec3 d;
};
struct result
{
	float t0;
	float reflectance;
	vec3 colour;
	vec3 Normal;
	bool background;
};
vec3 checker(float u, float v)
{
  float checkSize = 0.05;
  float fmodResult = mod(floor(checkSize * u) + floor(checkSize * v), 2.0);
  float fin = max(sign(fmodResult), 0.1);
  return vec3(fin, fin, fin);
}

vec3 lightpos = vec3(-0.0,0.0,1);
vec3 lightcolour = vec3(1,1,1.0);
float hit_sphere(ray Ray, sphere CurrentSphere)
{
	vec3 oc = Ray.o - CurrentSphere.sphere_dat.xyz;
	float a = dot(Ray.d,Ray.d);
	float b = 2.0 * dot(oc,Ray.d);
	float c = dot(oc,oc) - pow(CurrentSphere.sphere_dat.w,2);
	float descrim = pow(b,2) - 4*a*c;
	if(descrim < 0){
		return -1;
	}
	else{
		 float t0 = min((-b - sqrt(descrim)) / (2.0*a),(-b + sqrt(descrim)) / (2.0*a));
		 if(sign(t0) == -1) return -1;
		 else return t0;
	}
}

result hits(ray Ray)
{
	result Result;
	float t0 = pos_infinity;

	if(sign(Ray.d.z) == 1){
		t0 = Ray.d.length() * (10/Ray.d.z); 
		Result.Normal = vec3(0.0,0.0,-1.0);
		vec2 xy = t0 * Ray.d.xy;
		Result.colour = checker(xy.x,xy.y);
		Result.reflectance = 0.0;
	}
	else 
	{
		Result.colour = vec3(0.0,0.0,0.0);
		Result.reflectance = 0.0;
	}

	for(int i=0;i<spher.length();i++)
	{
		float t1 = hit_sphere(Ray,spher[i]);
		if(t1 != -1){
			if(t1 == min(t1,t0))
			{
				t0 = t1;
				Result.reflectance = 0.9 ;
				Result.Normal = normalize(Ray.d*t0 - spher[i].sphere_dat.xyz);
				Result.colour = vec3(vec3(0.3,0.3,0.8));
			}
		}  
	}
	Result.t0 = t0;
	return Result; 
}

void main(){
	//base pixel colour
	vec4 pixel = vec4(0.0, 0.0, 0.0, 1.0);
	ivec2 pixel_coords = ivec2(gl_GlobalInvocationID.xy);
	
	float max_x = 5; //view plane is from (-5,5) to (5,-5)
	float max_y = 5;
	ivec2 dims = imageSize(img_output);

	float x = (float((pixel_coords.x) * 2.0f - dims.x)/dims.x);
	float y = (float((pixel_coords.y) * 2.0f - dims.y)/dims.y);
	
	
		
	//vec3 ray_o = vec3(x*max_x, y * max_y, 0.0); //turns -1 -> 1 to -5 -> 5 
	//vec3 ray_d = vec3(0.0,0.0,-1.0); //ortho COOOL!!!
	vec3 planepos = vec3(x*max_x, y * max_y, 6);
	vec3 ray_d = normalize(planepos);
	vec3 ray_o = vec3(0,0,0);
	ray iniray;
	iniray.d = ray_d;
	iniray.o = ray_o;
	result raysult = hits(iniray);
	if(raysult.t0 != pos_infinity)
	{
		
		vec3 rayvec = raysult.t0 * iniray.d;
		vec3 LightDir = normalize(lightpos - rayvec);
		vec3 diff = max(dot(raysult.Normal,LightDir),0.0) * lightcolour;
		
		float specstrength = 0.8f;
		vec3 ReflectDir = reflect(LightDir,raysult.Normal);
		
		
		float spec = pow(max(dot(iniray.d,ReflectDir),0.0),16);
		vec3 specular = specstrength * spec * lightcolour;	
		raysult.colour = raysult.colour * (diff + specular);

		ray ShadowRay = ray(rayvec,LightDir);
		if(hits(ShadowRay).t0 != pos_infinity){
			raysult.colour = raysult.colour*0.1;
		}

		ray ReflectionRay;
		ReflectionRay.o = rayvec;
		ReflectionRay.d = reflect(iniray.d,raysult.Normal);
		result samp = hits(ReflectionRay);
		result bounces[10];
		ray secondrays[10];
		secondrays[0] = ReflectionRay;
		bounces[0] = samp;
		float frac = 1.0f;
		vec3 final_color;
		int numbounces;
		for(int ii = 0; ii < bounces.length()-1; ii++)
		{
			if(bounces[ii].reflectance > 0.0)
			{
			
				 
				secondrays[ii+1].o = secondrays[ii].o + (secondrays[ii].d*bounces[ii].t0);
				secondrays[ii+1].d = reflect(secondrays[ii].d,bounces[ii].Normal);
				bounces[ii+1] = hits(secondrays[ii+1]);
			
				vec3 rayvec = bounces[ii+1].t0 * secondrays[ii+1].d;
				vec3 LightDir = normalize(lightpos - rayvec);
				vec3 diff = max(dot(bounces[ii+1].Normal,LightDir),0.0) * lightcolour;
		
				float specstrength = 0.8f;
				vec3 ReflectDir = reflect(LightDir,bounces[ii+1].Normal);
		
		
				float spec = pow(max(dot(secondrays[ii+1].d,ReflectDir),0.0),16);
				vec3 specular = specstrength * spec * lightcolour;	
				
				bounces[ii+1].colour = bounces[ii+1].colour * (diff + specular);
				
				final_color = mix(bounces[ii].colour,bounces[ii+1].colour,bounces[ii].reflectance*frac);
				frac = frac * bounces[ii+1].reflectance;
			}
			else if(ii == 0)
			{
				final_color = samp.colour;
			}
			

		}
	
		//if(samp.reflectance > 0.0)
		//{
		//	ray secondray;
		//	secondray.o = ReflectionRay.o + ReflectionRay.d*samp.t0;
		//	secondray.d = reflect(ReflectionRay.d,samp.Normal);
		//	result samp2 = hits(secondray);
		//	samp.colour = mix(samp.colour,samp2.colour,samp.reflectance);
		//}
	   //



		raysult.colour = mix(raysult.colour,final_color,raysult.reflectance);
		
		
		
		pixel = vec4(raysult.colour,1.0);

		
	}	
	
	imageStore(img_output, pixel_coords, pixel);
}




