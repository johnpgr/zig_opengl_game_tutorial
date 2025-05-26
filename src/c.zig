pub const c = @cImport({
    @cDefine("SDL_DISABLE_OLDNAMES", {});
    @cDefine("GL_GLEXT_PROTOTYPES", {});
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3_ttf/SDL_ttf.h");
    @cInclude("SDL3_image/SDL_image.h");
    @cInclude("SDL3/SDL_opengl.h");
});
