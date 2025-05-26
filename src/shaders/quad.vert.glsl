#version 410 core

struct Transform {
    ivec2 atlas_offset;
    ivec2 sprite_size;
    vec2 pos;
    vec2 size;
};

layout(std140) uniform TransformUBO {
    Transform transforms[1024];
};

layout(location = 0) out vec2 textureCoordsIn;

void main() {
    Transform transform = transforms[gl_InstanceID];

    const vec2 vertices[6] = vec2[6](
        transform.pos, // Top left
        vec2(transform.pos + vec2(0.0, transform.size.y)), // Bottom left
        vec2(transform.pos + vec2(transform.size.x, 0.0)), // Top right
        vec2(transform.pos + vec2(transform.size.x, 0.0)), // Top right
        vec2(transform.pos + vec2(0.0, transform.size.y)), // Bottom left
        transform.pos + transform.size // Bottom right
    );

    const float left = transform.atlas_offset.x;
    const float top = transform.atlas_offset.y;
    const float right = left + transform.sprite_size.x;
    const float bottom = top + transform.sprite_size.y;

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

    gl_Position = vec4(vertices[gl_VertexID], 1.0, 1.0);
    textureCoordsIn = textureCoords[gl_VertexID];
}
