/**
Authors: outland.karasu
License: BSL-1.0
*/

module karasutk.sdl.window;

import std.string : toStringz;
import std.typecons :
    RefCounted,
    refCounted;

import bindbc.sdl :
    SDL_WINDOW_BORDERLESS,
    SDL_WINDOW_OPENGL,
    SDL_WINDOW_RESIZABLE,
    SDL_WINDOW_SHOWN,
    SDL_WINDOW_VULKAN,
    SDL_WINDOWPOS_UNDEFINED,
    SDL_CreateWindow,
    SDL_DestroyWindow,
    SDL_TRUE,
    SDL_Vulkan_GetInstanceExtensions,
    SDL_Vulkan_CreateSurface,
    SDL_Window,
    SDL_WindowFlags;

import karasutk.sdl.exception : enforceSDL;

/**
Window creation parameters.
*/
struct WindowParameters
{
    const(char)[] title;
    int x = SDL_WINDOWPOS_UNDEFINED;
    int y = SDL_WINDOWPOS_UNDEFINED;
    uint w = 640;
    uint h = 480;
    bool openGL = false;
    bool vulkan = false;
    bool visible = true;
    bool borderless = false;
    bool resizable = false;

    private @property SDL_WindowFlags flags() const @nogc nothrow pure @safe scope
    {
        SDL_WindowFlags result = cast(SDL_WindowFlags) 0;
        result |= openGL ? SDL_WINDOW_OPENGL : 0;
        result |= vulkan ? SDL_WINDOW_VULKAN : 0;
        result |= visible ? SDL_WINDOW_SHOWN : 0;
        result |= borderless ? SDL_WINDOW_BORDERLESS : 0;
        result |= resizable ? SDL_WINDOW_RESIZABLE : 0;
        return result;
    }
}

///
@nogc nothrow pure @safe unittest
{
    WindowParameters params;
    assert(params.flags & SDL_WINDOW_SHOWN);
    assert(!(params.flags & ~SDL_WINDOW_SHOWN));

    params = params.init;
    params.visible = false;
    assert(!(params.flags & SDL_WINDOW_SHOWN));

    params = params.init;
    params.openGL = true;
    assert(params.flags & SDL_WINDOW_OPENGL);

    params = params.init;
    params.vulkan = true;
    assert(params.flags & SDL_WINDOW_VULKAN);

    params = params.init;
    params.borderless = true;
    assert(params.flags & SDL_WINDOW_BORDERLESS);

    params = params.init;
    params.resizable = true;
    assert(params.flags & SDL_WINDOW_RESIZABLE);
}

/**
SDL window.
*/
struct Window
{
    /**
    Create a window.

    Params:
        parameters = window creation parameters.
    */
    static Window create()(auto ref scope const(WindowParameters) parameters)
    {
        auto window = enforceSDL(SDL_CreateWindow(
            toStringz(parameters.title),
            parameters.x,
            parameters.y,
            parameters.w,
            parameters.h,
            parameters.flags));
        return Window(window);
    }

    @disable this();

    @property SDL_Window* ptr() @nogc nothrow pure scope return
    {
        return payload_.refCountedPayload.window;
    }

    @property const(char)*[] vulkanInstanceExtensions()
    {
        // get extensions count.
        uint count;
        enforceSDL(SDL_Vulkan_GetInstanceExtensions(ptr, &count, null) == SDL_TRUE);

        // read extensions.
        auto extensions = new const(char)*[](count);
        enforceSDL(SDL_Vulkan_GetInstanceExtensions(ptr, &count, extensions.ptr) == SDL_TRUE);
        return extensions;
    }

    void* vulkanCreateSurface(void* instance)
    in (instance)
    out (r; r)
    {
        void* surface;
        enforceSDL(SDL_Vulkan_CreateSurface(ptr, instance, &surface) == SDL_TRUE);
        return surface;
    }

private:

    this()(SDL_Window* window) @nogc nothrow scope
    {
        this.payload_ = window;
    }

    struct Payload
    {
        @disable this(this);

        ~this() @nogc nothrow scope
        {
            if (window)
            {
                SDL_DestroyWindow(window);
            }
        }

        SDL_Window* window;
    }

    RefCounted!Payload payload_;
}

