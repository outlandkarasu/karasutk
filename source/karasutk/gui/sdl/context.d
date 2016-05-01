/**
 *  SDL application module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.context;

import karasutk.gui.context;
import karasutk.gui.sdl.utils : enforceSdl;
import derelict.sdl2.sdl;

/// SDL context class.
class SdlContext : AbstractContext {

    this(SDL_Window* window) {
        // set up a OpenGL context.
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        this.context_ = enforceSdl(SDL_GL_CreateContext(window));
    }

    ~this() {
        SDL_GL_DeleteContext(context_);
    }

private:
    SDL_GLContext context_;
}

