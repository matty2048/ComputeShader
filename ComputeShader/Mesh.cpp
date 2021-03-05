#include "Mesh.h"

mesh::~mesh()
{
    Verticies.~vector();
    Indicies.~vector();
}

mesh::mesh(std::vector<vertex>& vertin,  std::vector<unsigned int>& indcin)
{
	this->Indicies = indcin;
	this->Verticies = vertin;


	SetupMesh();
}

void mesh::Draw(Shader shader)
{
	shader.use();
	glBindVertexArray(VAO);
    
	glDrawElements(GL_TRIANGLES, Indicies.size(), GL_UNSIGNED_INT,0);
	glBindVertexArray(0);
}

void mesh::SetupMesh()
{
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);

    glBufferData(GL_ARRAY_BUFFER, Verticies.size() * sizeof(vertex), &Verticies[0], GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, Indicies.size() * sizeof(unsigned int) ,&Indicies[0], GL_STATIC_DRAW);

    // vertex positions
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(vertex), (void*)0);
    // vertex normals
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(vertex), (void*)offsetof(vertex, Normal));
    // vertex texture coords


    glBindVertexArray(0);
}
