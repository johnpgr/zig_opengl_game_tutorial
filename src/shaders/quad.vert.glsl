#version 410 core

struct Transform {
    ivec2 atlas_offset;
    ivec2 sprite_size;
    vec2 pos;
    vec2 size;
};

layout(std140) uniform TransformUBO {
    Transform transforms[1000];
};

uniform vec2 screen_size;
uniform mat4 projection_matrix;

layout(location = 0) out vec2 texture_coords;

void main() {
    Transform transform = transforms[gl_InstanceID];

    vec2 vertices[6] = vec2[6](
        transform.pos, // Top left
        vec2(transform.pos + vec2(0.0, transform.size.y)), // Bottom left
        vec2(transform.pos + vec2(transform.size.x, 0.0)), // Top right
        vec2(transform.pos + vec2(transform.size.x, 0.0)), // Top right
        vec2(transform.pos + vec2(0.0, transform.size.y)), // Bottom left
        transform.pos + transform.size // Bottom right
    );

    float left = transform.atlas_offset.x;
    float top = transform.atlas_offset.y;
    float right = left + transform.sprite_size.x;
    float bottom = top + transform.sprite_size.y;

    vec2 coords_normal[6] = vec2[6](
        // Triangle 1
        vec2(left, top),     // top left
        vec2(left, bottom),  // bottom left  
        vec2(right, top),    // top right
        // Triangle 2
        vec2(right, top),    // top right
        vec2(left, bottom),  // bottom left
        vec2(right, bottom)  // bottom right
    );

    vec2 pos = vertices[gl_VertexID];
    gl_Position = projection_matrix * vec4(pos, 0.0, 1.0);

    texture_coords = coords_normal[gl_VertexID];
}
