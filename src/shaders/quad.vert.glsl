#version 430 core

void main() 
{
    vec2 vertices[6] = {
        //topleft
        vec2(-0.5, 0.5),
        //bottomleft
        vec2(-0.5, -0.5),
        //topright
        vec2(0.5, 0.5),
        //topright
        vec2(0.5, 0.5),
        //bottomleft
        vec2(-0.5, -0.5),
        //bottomright
        vec2(0.5, -0.5)
    };

    gl_Position = vec4(vertices[gl_VertexID], 1.0, 1.0);
}
