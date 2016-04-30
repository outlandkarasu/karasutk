/**
 *  SDL application module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.context;

import karasutk.gui.context;

import karasutk.gui.sdl.event;
import karasutk.gui.sdl.mesh;
import karasutk.gui.sdl.texture;
import karasutk.gui.sdl.utils;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

class SdlContext : AbstractContext {

    this(SDL_Window* window) @safe {
        super(new SdlEventQueue(),
                new SdlTextureFactory());
        this.window_ = window;
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

    override @property const {

        uint windowWidth() {
            int result = 0;
            SDL_GetWindowSize(cast(SDL_Window*) window_, &result, cast(int*) null);
            return result;
        }

        uint windowHeight() {
            int result = 0;
            SDL_GetWindowSize(cast(SDL_Window*) window_, cast(int*) null, &result);
            return result;
        }
    }

    override void quit() {
        SDL_Event event;
        event.type = SDL_QUIT;
        enforceSdl(SDL_PushEvent(&event));
    }

private:

    SDL_Window* window_;
}

