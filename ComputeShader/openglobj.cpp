// openglobj.cpp : This file contains the 'main' function. Program execution begins and ends there.
//
#define STB_IMAGE_IMPLEMENTATION
#define GLEW_STATIC
#include <GL/glew.h>
//#include <GLFW/glfw3.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <GL/GL.h>
//#include <iostream>
//#include <assimp/Importer.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include "stb_image.h"
#include <vector>
#include <ctime>
#include <random>
#include <cstdlib>
//#include <glm/gtc/matrix_transform.hpp>
//#include <imgui-features-premake5/misc/single_file/imgui_single_file.h>
//#include <imgui-features-premake5/examples/imgui_impl_opengl3.h>
//#include <imgui-features-premake5/examples/imgui_impl_glfw.h>
//#include "Model.h"
#include "Shader.h"
#include "Teapot.h"
struct sphere
{
    
    glm::vec4 dat;
    glm::vec4 albedo;
    glm::vec4 specular;
    
    glm::vec4 emmission;
    glm::vec4 smoothnes;
};
void GLAPIENTRY
MessageCallback(GLenum source,
    GLenum type,
    GLuint id,
    GLenum severity,
    GLsizei length,
    const GLchar* message,
    const void* userParam)
{
    fprintf(stderr, "GL CALLBACK: %s type = 0x%x, severity = 0x%x, message = %s\n",
        (type == GL_DEBUG_TYPE_ERROR ? "** GL ERROR **" : ""),
        type, severity, message);
}


 int tex_w = 1920, tex_h = 1080;
 using namespace std;

 float frand()
 {
         static std::default_random_engine e;
         static std::uniform_real_distribution<> dis(0, 0.9999); // rage 0 - 1
         return dis(e);
 } 
 glm::vec4 randvec()
 {
     return glm::vec4(frand(), frand(), frand(), frand());
 };
 unsigned int loadCubemap(vector<std::string> faces)
 {
     unsigned int textureID;
     glGenTextures(1, &textureID);
     glBindTexture(GL_TEXTURE_CUBE_MAP, textureID);
        
     int width, height, nrChannels;
     for (unsigned int i = 0; i < faces.size(); i++)
     {
         unsigned char* data = stbi_load(faces[i].c_str(), &width, &height, &nrChannels, 0);
         if (data)
         {
             glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i,1, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
             stbi_image_free(data);
         }
         else
         {
             std::cout << "Cubemap tex failed to load at path: " << faces[i] << std::endl;
             stbi_image_free(data);
         }
     }
     glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
     glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
     glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
     glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
     glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

     return textureID;
 }

int main(void)
{
    const char* model = "C:/Users/matthew/source/repos/openglobj/openglobj/mesh.obj";
    const char* vertex = "Vertex.glsl";
    const char* fragment = "Fragment.glsl";
    const char* fragment2 = "Fragment2.glsl";
    const char* compute = "compute2.glsl";
    GLFWwindow* window;
    /* Initialize the library */
    if (!glfwInit())
        return -1;
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
   // glfwWindowHint(GLFW_DOUBLEBUFFER, GL_FALSE);

    /* Create a windowed mode window and its OpenGL context */
    window = glfwCreateWindow(tex_w, tex_h, "Hello World", NULL, NULL);
    if (!window)
    {
        glfwTerminate();
        return -1;
    }
   
    
    /* Make the window's context current */
    glfwMakeContextCurrent(window);
    if (glewInit() != GLEW_OK)
    {
        std::cout << "error with glew :c" << std::endl;
        std::cin;
        return 0;
    }
    glEnable(GL_DEBUG_OUTPUT);
    glDebugMessageCallback(MessageCallback, 0);
    Shader shader(vertex,fragment);
    Shader shader2(vertex, fragment2);
    Shader comp(compute);

    float vertices[] = {
        -1.0f,  1.0f, 0.0f, 1.0f,//top left
         1.0f,  1.0f, 1.0f, 1.0f,//top right
         1.0f, -1.0f, 1.0f, 0.0f,//bottom right
        -1.0f, -1.0f, 0.0f, 0.0f//bottom left
    };
    int indices[] = {
        0 , 1 , 3,
        3 , 2 , 1
    };
    
    glm::vec4 spheres[]
    {
       glm::vec4(0.7,-1.1f,-3.f,0.4),glm::vec4(0),
       glm::vec4(-0.0,-1.1,-1.5f,0.9),glm::vec4(2),
       glm::vec4(-0.2,-1.0,-0.6f,0.1),glm::vec4(1),
    };

    glm::vec4 Materials[]
    {
        glm::vec4(8,103,136,0)/255.f,glm::vec4(0.2,0.2,0.2,0),glm::vec4(0.0),glm::vec4(2.0),glm::vec4(0.f),glm::vec4(0),
        glm::vec4(0.0,0.0,0.0,0.0),glm::vec4(0.7,0.7,0.7,0.0),glm::vec4(180.0),glm::vec4(0.0),glm::vec4(0.0f),glm::vec4(0),
        glm::vec4(1.0f,1.0,1.0,0.0),glm::vec4(1.0,1.0,1.0,0.0),glm::vec4(0.0),glm::vec4(1.0),glm::vec4(0.0f,0.f,0,0),glm::vec4(1.0f)
    };

    glm::vec4 Vertex[]
    {
        glm::vec4(0.0,1.f,-0.5f,0.f),
        glm::vec4(-1.0,0.4,-1.8f,0.f),
        glm::vec4(0.f,5.f,0.f,0.f),
        glm::vec4(2)
    };

    unsigned int index[teapot_count];
    for (unsigned int i =0; i<teapot_count; i++)
    {
        index[i] = i;
    }
    //shade.use();
    unsigned int VBO, VAO, EBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);

    glBindVertexArray(VAO);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);


    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void*)(2*sizeof(float)));
    glEnableVertexAttribArray(1);



    unsigned int ssbo;
    glGenBuffers(1, &ssbo);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, ssbo);
    glBufferData(GL_SHADER_STORAGE_BUFFER, 6 * 4 * sizeof(float), &spheres, GL_STATIC_DRAW);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, ssbo);

    unsigned int ssbo_mat;
    glGenBuffers(1, &ssbo_mat);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, ssbo_mat);
    glBufferData(GL_SHADER_STORAGE_BUFFER, 4 * 6 * 3 * sizeof(float), &Materials, GL_STATIC_DRAW);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, ssbo_mat);
   
    //unsigned int ssbo_tris;
    //glGenBuffers(1, &ssbo_tris);
    //glBindBuffer(GL_SHADER_STORAGE_BUFFER, ssbo_tris);
    //glBufferData(GL_SHADER_STORAGE_BUFFER,/*(1732-5)*/ 1730* 4* sizeof(float), &teapot, GL_STATIC_DRAW);
    //glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, ssbo_tris);
    //
    //unsigned int ssbo_Index;
    //glGenBuffers(1, &ssbo_Index);
    //glBindBuffer(GL_SHADER_STORAGE_BUFFER, ssbo_Index);
    //glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(unsigned int) * teapot_count, &index, GL_STATIC_DRAW);
    //glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 4, ssbo_Index);


    vector<string> faces
    {
        "px.png",
        "nx.png",
        "py.png",
        "ny.png",
        "pz.png",
        "nz.png"
    };
   
    unsigned int texid;
    glGenTextures(1,&texid);
    glBindTexture(GL_TEXTURE_CUBE_MAP, texid);
    
    int width, height, nrChannels;

    unsigned char* data;
    for (unsigned int i = 0; i < faces.size(); i++)
    {
        data = stbi_load(faces[i].c_str(), &width, &height, &nrChannels, 0);
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i,0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
        stbi_image_free(data);
    }
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    glUniform1i(glGetUniformLocation(comp.Shader_ID, "skybox"), 1);
    shader.use();
     

    glm::mat4 view = glm::mat4(1.0);
    view = glm::translate(view, glm::vec3(-3., 1.0, -4.0));
   // view = glm::lookAt(glm::vec3(-3.0,1.0, -4.0), glm::vec3(0.0,-.0,-6.0), glm::vec3(0.0, 1.0, 0.0));
    view = glm::rotate(view, glm::radians(-130.0f), glm::vec3(0,1,0));
    view = glm::rotate(view, glm::radians(-40.0f), glm::vec3(1, 0, 0));
    glm::mat4 projection = glm::perspective(glm::radians(45.0f), float(tex_w)/float(tex_h), 0.1f, 100.0f);
    glm::mat4 CameraToWorld =view;
   
    
    comp.setMat4("CameraInverseProjection", glm::inverse(projection));
    comp.setMat4("CameraToWorld", CameraToWorld);
    
    unsigned int hdrFBO;
    glGenFramebuffers(1, &hdrFBO);
    // create floating point color buffer
    unsigned int colorBuffer;
    glGenTextures(1, &colorBuffer);
    glBindTexture(GL_TEXTURE_2D, colorBuffer);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, tex_w, tex_h, 0, GL_RGBA, GL_FLOAT, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // create depth buffer (renderbuffer)
 
    // attach buffers
    glBindFramebuffer(GL_FRAMEBUFFER, hdrFBO);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorBuffer, 0);
    //glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepth);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        std::cout << "Framebuffer not complete!" << std::endl;
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    GLuint tex_output;
    glGenTextures(1, &tex_output);
  
    glBindTexture(GL_TEXTURE_2D, tex_output);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, tex_w, tex_h, 0, GL_RGBA, GL_FLOAT, NULL);
    glBindImageTexture(0, tex_output, 0, GL_FALSE, 0, GL_WRITE_ONLY, GL_RGBA32F);
  
    /* Loop until the user closes the window */
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_DST_ALPHA);
    glEnable(GL_DEPTH_TEST);
    
    glDepthFunc(GL_ALWAYS);
    //glClear(GL_COLOR_BUFFER_BIT);
  
    unsigned int numsample = 0;
    while (!glfwWindowShouldClose(window))
    {
        glBindFramebuffer(GL_FRAMEBUFFER,hdrFBO);
        //glBindBuffer(GL_SHADER_STORAGE_BUFFER, ssbo);
        //glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(spheres), &spheres, GL_STATIC_DRAW);
        //glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, ssbo);
        //std::cout << frand() << std::endl;
     //  view = glm::rotate(view, glm::radians(0.3f), glm::vec3(0, 1, 0));
       glm::mat4 CameraToWorld = view;
       comp.setMat4("CameraToWorld",CameraToWorld);
       comp.setUniformf("seed", frand());
       // comp.setUniform2f("PixelOffset", glm::vec2(frand(), frand()));
       comp.use();
       
       glBindTexture(GL_TEXTURE_CUBE_MAP,texid);
       glDispatchCompute((GLuint)(tex_w/16) , (GLuint)(tex_h/16), 1);
       glMemoryBarrier(GL_ALL_BARRIER_BITS);
       
       /* Render here */
      // glClear(GL_COLOR_BUFFER_BIT);
       glBindVertexArray(VAO);
       shader.setUniformui("_sample", numsample);
       shader.use();
       glBindTexture(GL_TEXTURE_2D, tex_output);
       glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
       //glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
       
       glBindFramebuffer(GL_FRAMEBUFFER, 0);
       glBindVertexArray(VAO);
      //  glClear(GL_COLOR_BUFFER_BIT);
        //shader2.setUniformui("_sample", numsample);
        shader2.use();
        //glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, colorBuffer);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
      
        
       numsample++;
       /* Swap front and back buffers */
       
       glfwSwapBuffers(window);
       /* Poll for and process events */
       glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}

// Run program: Ctrl + F5 or Debug > Start Without Debugging menu
// Debug program: F5 or Debug > Start Debugging menu

// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file


