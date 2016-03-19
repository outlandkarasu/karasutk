/**
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.mains;

import std.string : toStringz;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3 : DerelictGL3;

import karasutk.dbg : dwritefln;
import karasutk.gui.sdl : enforceSDL;

/**
 *  Run a dg during GUI.
 */
void doGuiMain(void delegate() dg) {
    DerelictSDL2.load();
    scope(exit) DerelictSDL2.unload();

    DerelictGL3.load();
    scope(exit) DerelictGL3.unload();

    enforceSDL(SDL_Init(SDL_INIT_EVERYTHING) == 0);
    scope(exit) SDL_Quit();

    // set up OpenGL
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

    // create the main window
    auto window = enforceSDL(SDL_CreateWindow(
        toStringz("test"),
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        640,
        480,
        SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN));
    scope(exit) SDL_DestroyWindow(window);

    // create the OpenGL context.
    auto context = enforceSDL(SDL_GL_CreateContext(window));
    scope(exit) SDL_GL_DeleteContext(context);

    // enable OpenGL3
    DerelictGL3.reload();
    dwritefln("OpenGL version: %s", DerelictGL3.loadedVersion);

    SDL_Delay(10000);
}

