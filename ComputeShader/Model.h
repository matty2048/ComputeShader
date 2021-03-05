#pragma once
#include "Mesh.h"
#include <assimp/scene.h>
#include <assimp/Importer.hpp>
#include <assimp/postprocess.h>

class Model
{
public:
	Model()
	{
	};
	Model(const char* path)
	{
		loadModel(path);
	};
	~Model();
	void Draw(Shader shader);
private:
	void loadModel(std::string path);
	std::vector<mesh> meshes;
	std::string directory;
	void proccessNode(aiNode* node, const aiScene* scene);
	mesh proccessMesh(aiMesh* node, const aiScene* scene);
};