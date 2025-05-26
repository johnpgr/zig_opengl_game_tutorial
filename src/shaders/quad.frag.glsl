#version 410 core
#extension GL_ARB_explicit_uniform_location : require

layout(location = 0) in vec2 textureCoordsIn;
layout(location = 0) out vec4 fragColor;
layout(location = 0) uniform sampler2D textureAtlas;

void main() {
    vec4 textureColor = texelFetch(textureAtlas, ivec2(textureCoordsIn), 0);
    fragColor = textureColor;
}
