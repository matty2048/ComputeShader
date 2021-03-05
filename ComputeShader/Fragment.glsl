
#version 430 core
//precision highp float;
//uniform vec3 viewpos;
out vec4 FragColor;
in vec2 texcoords;
uniform uint _sample; 
uniform sampler2D texture1;

void main()
{
   double alpha = 1.0f / (_sample + 1.0f);
  FragColor = vec4(texture(texture1,texcoords).rgb,alpha);
 //FragColor = texture(texture1,texcoords);
}