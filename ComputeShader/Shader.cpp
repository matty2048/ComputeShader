#include "Shader.h"


using namespace std;
Shader::Shader(const char* vertexPath, const char* fragmentPath)
	
{
	string vertexCode;
	string FragemntCode;
	ifstream vShaderFile;
	ifstream fShaderFile;
	int success;
	char infolog[512];

	vShaderFile.exceptions(ifstream::failbit|ifstream::badbit);
	fShaderFile.exceptions(ifstream::failbit|ifstream::badbit);
	try {
		vShaderFile.open(vertexPath);
		fShaderFile.open(fragmentPath);
		stringstream vShaderStream, fShaderStream;

		vShaderStream << vShaderFile.rdbuf();
		fShaderStream << fShaderFile.rdbuf();

		vShaderFile.close();
		fShaderFile.close();

		vertexCode = vShaderStream.str();
		FragemntCode = fShaderStream.str();

		

	}
	catch(ifstream::failure e)
	{
		cout << "error in shader :c" << endl;
	}
	const char* vShaderCode = vertexCode.c_str();
	const char* fShaderCode = FragemntCode.c_str();

	unsigned int VertexShader;
	unsigned int FragmentShader;

	VertexShader = glCreateShader(GL_VERTEX_SHADER);
	FragmentShader = glCreateShader(GL_FRAGMENT_SHADER);

	glShaderSource(VertexShader, 1, &vShaderCode, NULL);
	glCompileShader(VertexShader);
	glGetShaderiv(VertexShader, GL_COMPILE_STATUS, &success);
	if (!success)
	{
		glGetShaderInfoLog(VertexShader, 512, NULL, infolog);
		cout << "vertex shader error " << infolog << endl;
		return;
	}
	
	glShaderSource(FragmentShader, 1, &fShaderCode, NULL);
	glCompileShader(FragmentShader);
	
	glGetShaderiv(FragmentShader, GL_COMPILE_STATUS, &success);
	if (!success)
	{
		glGetShaderInfoLog(FragmentShader, 512, NULL, infolog);
		cout << "Fragemnt shader error " << infolog << endl;
		return;
	}

	Shader_ID = glCreateProgram();
	glAttachShader(Shader_ID, VertexShader);
	glAttachShader(Shader_ID, FragmentShader);
	glLinkProgram(Shader_ID);
	glGetProgramiv(Shader_ID, GL_LINK_STATUS, &success);
	if (!success)
	{
		glGetProgramInfoLog(Shader_ID, 512, NULL, infolog);
		cout << "Link error " << infolog << endl;
	}
	glDeleteShader(VertexShader);
	glDeleteShader(FragmentShader);

}

Shader::Shader(const char* ComputeShaderPath)
{
	string ComputeCode;
	ifstream cShaderFile;

	cShaderFile.open(ComputeShaderPath);
	stringstream cShaderStream;
	cShaderStream << cShaderFile.rdbuf();
	cShaderFile.close();
	ComputeCode = cShaderStream.str();
	int success;
	char infolog[512];
	const char* cShaderCode = ComputeCode.c_str();

	unsigned int ComputeShader;

	ComputeShader = glCreateShader(GL_COMPUTE_SHADER);
	glShaderSource(ComputeShader, 1, &cShaderCode, NULL);
	glCompileShader(ComputeShader);
	glGetShaderiv(ComputeShader, GL_COMPILE_STATUS, &success);
	if (!success)
	{
		glGetShaderInfoLog(ComputeShader, 512, NULL, infolog);
		cout << "Compute shader error " << infolog << endl;
		return;
	}

	Shader_ID = glCreateProgram();
	glAttachShader(Shader_ID, ComputeShader);
	glLinkProgram(Shader_ID);
	glGetProgramiv(Shader_ID, GL_LINK_STATUS, &success);
	if (!success)
	{
		glGetProgramInfoLog(Shader_ID, 512, NULL, infolog);
		cout << "Link error " << infolog << endl;
	}
}



void Shader::use()
{
	glUseProgram(Shader_ID);
}



void Shader::unuse()
{
	glUseProgram(0);
}

void Shader::setUniform4f(const char* UniformName, float a, float b, float c, float d)
{
	glUseProgram(Shader_ID);
	glUniform4f(GetUniformLocation(UniformName), a, b, c, d);
	glUseProgram(0);
}
void Shader::setUniform3f(const char* UniformName, glm::vec3 data)
{
	glUseProgram(Shader_ID);
	glUniform3f(GetUniformLocation(UniformName), data.x, data.y,data.z);
	glUseProgram(0);
}

void Shader::setMat4(const char* UniformName,const glm::mat4& data)
{
	glUseProgram(Shader_ID);
	glUniformMatrix4fv(GetUniformLocation(UniformName), 1, GL_FALSE, &data[0][0]);
	glUseProgram(0);
}
void Shader::setUniformf(const char* UniformName, const float data)
{
	glUseProgram(Shader_ID);
	glUniform1f(GetUniformLocation(UniformName), data);
	glUseProgram(0);
}
void Shader::setUniformui(const char* UniformName, const unsigned int data)
{
	glUseProgram(Shader_ID);
	glUniform1ui(GetUniformLocation(UniformName), data);
	glUseProgram(0);
}
void Shader::setUniform2f(const char* UniformName, glm::vec2 data)
{
	glUseProgram(Shader_ID);
	glUniform2f(GetUniformLocation(UniformName), data.x,data.y);
	glUseProgram(0);
}

int Shader::GetUniformLocation(const char* name)
{
	if (LocationCache.find(name) != LocationCache.end())
		return LocationCache[name];
	int location = (glGetUniformLocation(Shader_ID ,name));
	if (location == -1)
		std::cout << "warning uniform " << name << " doesn't exist" << std::endl;
	else
	{
		LocationCache[name] = location;
	}
	return location;

}