#pragma once
#include <vector>
#include <iostream>

#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include "Shader.h"
#include <glm/glm.hpp>
struct vertex
{
	glm::vec3 Position;
	glm::vec3 Normal;
};
struct Texture
{
	unsigned int id;
	std::string type;
};
class mesh
{
public:
	std::vector<vertex> Verticies;
	~mesh();
	std::vector<unsigned int> Indicies;
	mesh(std::vector<vertex>&vertin, std::vector<unsigned int>& indcin);
	void Draw(Shader shader);
	unsigned int VAO;
private:
	unsigned int VBO, EBO;
	void SetupMesh();
};