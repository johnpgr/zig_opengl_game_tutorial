#version 410 core

layout(location = 0) out vec2 textureCoordsIn;

const vec2 vertices[6] = vec2[6](
    // Triangle 1
    vec2(-0.5,  0.5), // top left
    vec2(-0.5, -0.5), // bottom left  
    vec2( 0.5,  0.5), // top right
    // Triangle 2
    vec2( 0.5,  0.5), // top right
    vec2(-0.5, -0.5), // bottom left
    vec2( 0.5, -0.5)  // bottom right
);

const float left = 0.0;
const float top = 0.0;
const float right = 16.0;
const float bottom = 16.0;

const vec2 textureCoords[6] = vec2[6](
    // Triangle 1
    vec2(left, top),     // top left
    vec2(left, bottom),  // bottom left  
    vec2(right, top),    // top right
    // Triangle 2
    vec2(right, top),    // top right
    vec2(left, bottom),  // bottom left
    vec2(right, bottom)  // bottom right
);

void main() 
{
    gl_Position = vec4(vertices[gl_VertexID], 0.0, 1.0);
    textureCoordsIn = textureCoords[gl_VertexID];
}
