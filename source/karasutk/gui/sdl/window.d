/**
 *  SDL window module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.window;

import karasutk.gui.window : AbstractWindow;
import karasutk.gui.sdl.utils : enforceSdl;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

/// SDL window class.
class SdlWindow : AbstractWindow {

    this(SDL_Window* window) {
        this.window_ = window;
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
    SDL_Window* window_;
}

