#pragma once
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <unordered_map>
#include <glm/glm.hpp>
#include <string>
#include <fstream>
#include <sstream>
#include <iostream>
#include <unordered_map>

class Shader
{
private:
	
	int GetUniformLocation(const char* name);
	std::unordered_map<const char*,int> LocationCache;
public:	
	Shader(const char* vertexPath, const char* fragmentPath);
	Shader(const char* ComputeShader);
	int Shader_ID;
	

	void use();
	
	void unuse();
	void setUniform4f(const char* UniformName, float a, float b,float c,float d);
	void setMat4(const char* UniformName, const glm::mat4& data);
	void setUniformf(const char* UniformName, const float data);
	void setUniformui(const char* UniformName, const unsigned int data);
	void setUniform2f(const char* UniformName, glm::vec2 data);
	
	void setUniform3f(const char* UniformName, glm::vec3 data);
};