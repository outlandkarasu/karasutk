/**
 *  SDL window module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.window;

import std.string : toStringz;
import karasutk.gui.mains : GuiOptions;
import karasutk.gui.window : AbstractWindow;
import karasutk.gui.sdl.utils : enforceSdl;
import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

/// SDL window class.
class SdlWindow : AbstractWindow {

    this(ref const(GuiOptions) opts) {
        // create the main window
        this.window_ = enforceSdl(SDL_CreateWindow(
            toStringz(opts.windowTitle),
            opts.windowCenterX ? SDL_WINDOWPOS_CENTERED : opts.windowPositionX,
            opts.windowCenterY ? SDL_WINDOWPOS_CENTERED : opts.windowPositionY,
            opts.windowWidth,
            opts.windowHeight,
            SDL_WINDOW_OPENGL | windowFlags(opts)));
        scope(failure) SDL_DestroyWindow(window_);

        // set up a OpenGL context.
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        this.context_ = enforceSdl(SDL_GL_CreateContext(window_));
    }

    ~this() @nogc nothrow {
        SDL_GL_DeleteContext(context_);
        SDL_DestroyWindow(window_);
    }

    override @property const @nogc nothrow {

        uint width() {
            int result = 0;
            SDL_GetWindowSize(cast(SDL_Window*) window_, &result, cast(int*) null);
            return result;
        }

        uint height() {
            int result = 0;
            SDL_GetWindowSize(cast(SDL_Window*) window_, cast(int*) null, &result);
            return result;
        }
    }

    override void drawFrame(void delegate() dg) {
        scope(exit) {
            glFlush();
            SDL_GL_SwapWindow(window_);
        }
        glEnable(GL_DEPTH_TEST);
        scope(exit) glDisable(GL_DEPTH_TEST);

        glEnable(GL_CULL_FACE);
        scope(exit) glDisable(GL_CULL_FACE);

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        dg();
    }

private:

    static SDL_WindowFlags windowFlags(ref const(GuiOptions) opts) @safe pure nothrow @nogc {
        with(opts) {
            SDL_WindowFlags flags;
            if(windowShown) flags |= SDL_WINDOW_SHOWN;
            if(windowHidden) flags |= SDL_WINDOW_HIDDEN;
            if(windowBorderless) flags |= SDL_WINDOW_BORDERLESS;
            if(windowResizeable) flags |= SDL_WINDOW_RESIZABLE;
            if(windowMinimized) flags |= SDL_WINDOW_MINIMIZED;
            if(windowMaximized) flags |= SDL_WINDOW_MAXIMIZED;
            if(fullScreen) flags |= SDL_WINDOW_FULLSCREEN;
            if(fullScreenDesktop) flags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
            return flags;
        }
    }

    SDL_GLContext context_;
    SDL_Window* window_;
}

