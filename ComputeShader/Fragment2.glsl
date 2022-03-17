
#version 430 core
out vec4 FragColor;
//uniform vec3 viewpos;
//out vec4 FragColor;
in vec2 texcoords;
//uniform uint _sample; 
uniform sampler2D texture1;
uniform float exposure;
void main()
{
   const float gamma = 1.2;
   //gonna add some denoising here
    vec3 hdrColor = texture(texture1, texcoords).rgb;
  
    // exposure tone mapping
    vec3 mapped = vec3(1.0) - exp(-hdrColor * exposure);
    // gamma correction 
    mapped = pow(mapped, vec3(1.0 / gamma));
  
    FragColor = vec4(mapped, 1.0);
  
 //FragColor = texture(texture1,texcoords);
   //FragColor = vec4(0.1,0.1,0.1,1.0);
}