#include "Model.h"


Model::~Model()
{
	for (unsigned int i = 0; i < meshes.size(); i++)
	{
		meshes[i].~mesh();
	}
}

void Model::Draw(Shader shader)
{
	for (unsigned int i = 0; i < meshes.size(); i++)
	{
		
		meshes[i].Draw(shader);

	}
}

void Model::loadModel(std::string path)
{
	Assimp::Importer importer;
	const aiScene* scene = importer.ReadFile(path, aiProcessPreset_TargetRealtime_Fast);
	if (!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode)
	{
		std::cout << "ERROR::ASSIMP::" << importer.GetErrorString() << std::endl;
		return;
	}
	directory = path.substr(0, path.find_last_of('/'));
	proccessNode(scene->mRootNode, scene);
}

void Model::proccessNode(aiNode* node, const aiScene* scene)
{
	for (unsigned int i = 0; i < node->mNumMeshes; i++)
	{
		aiMesh* mesh = scene->mMeshes[node->mMeshes[i]];
		meshes.push_back(proccessMesh(mesh, scene));
	}
	for (unsigned int i = 0; i < node->mNumChildren; i++)
	{
		proccessNode(node->mChildren[i], scene);
	}
}

mesh Model::proccessMesh(aiMesh* node, const aiScene* scene)
{
	std::vector<vertex> verticies;
	std::vector<unsigned int> indicies;
	
	vertex Vertex;
	for (unsigned int i = 0; i < node->mNumVertices; i++)
	{
		
		
		Vertex.Position = glm::vec3(node->mVertices[i].x, node->mVertices[i].y, node->mVertices[i].z );
		if (node->HasNormals()) Vertex.Normal = glm::vec3(node->mNormals[i].x, node->mNormals[i].y, node->mNormals[i].z);
		else
			Vertex.Normal = glm::vec3(0.0, 0.0, 0.0);
	//	if (node->mTextureCoords[0]) Vertex.TexCoords = glm::vec2(node->mTextureCoords[0][i].x, node->mTextureCoords[0][i].y);
	//	else 
	//		Vertex.TexCoords = glm::vec2(0.0f, 0.0f);
		verticies.push_back(Vertex);
	}
	for (unsigned int i = 0; i < node->mNumFaces; i++)
	{
		aiFace face = node->mFaces[i];
		for (unsigned int j = 0; j < face.mNumIndices; j++) {
			indicies.push_back(face.mIndices[j]);
		}
	}

	return mesh(verticies,indicies);
}
