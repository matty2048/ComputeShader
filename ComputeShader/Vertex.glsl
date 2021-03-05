#version 430 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 tex;
out vec2  texcoords;
void main()
{
	texcoords = tex;
	gl_Position = vec4(aPos,0.0f,1.0f);
}