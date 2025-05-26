#version 410 core

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

void main() 
{
    gl_Position = vec4(vertices[gl_VertexID], 0.0, 1.0);
}
