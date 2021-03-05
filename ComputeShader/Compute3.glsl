#version 430
layout(local_size_x = 1, local_size_y = 1) in;
layout(rgba32f,binding = 0) uniform image2D img_output;
shared vec3 res;
void main()
{
	if(gl_LocalInvocationID == uvec3(0,0,0))
	{
		res = vec3(0);
	}
	memoryBarrierShared();
	barrier();
	res += vec3(gl_WorkGroupID.xy,0)/1000;
	memoryBarrierShared();
	barrier();
	
	if(gl_LocalInvocationID == uvec3(0,0,0))
	{
		ivec2 pixel_coords = ivec2(gl_WorkGroupID.xy);
		imageStore(img_output,pixel_coords,vec4(res,0));
	}
	barrier();
	return;

}