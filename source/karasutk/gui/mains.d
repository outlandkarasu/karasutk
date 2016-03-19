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
 *  GUI option structure.
 */
struct GuiOptions {
    string windowTitle = "karasutk.gui";
    ushort windowHeight = 1024;
    ushort windowWidth = 768;
    ushort windowPositionX = 0;
    ushort windowPositionY = 0;
    bool windowCenterX = true;
    bool windowCenterY = true;
    bool windowShown = true;
    bool windowHidden = false;
    bool windowBorderless = false;
    bool windowResizeable = false;
    bool windowMinimized = false;
    bool windowMaximized = false;
    bool fullScreen = false;
    bool fullScreenDesktop = false;
}

/**
 *  Run a dg during GUI.
 *
 *  Params:
 *      options = GUI options.
 *      dg = the main function delegate.
 */
void doGuiMain(ref const(GuiOptions) options, void delegate() dg) {
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
        toStringz(options.windowTitle),
        options.windowCenterX ? SDL_WINDOWPOS_CENTERED : options.windowPositionX,
        options.windowCenterY ? SDL_WINDOWPOS_CENTERED : options.windowPositionY,
        options.windowWidth,
        options.windowHeight,
        SDL_WINDOW_OPENGL | options.windowFlags));
    scope(exit) SDL_DestroyWindow(window);

    // create the OpenGL context.
    auto context = enforceSDL(SDL_GL_CreateContext(window));
    scope(exit) SDL_GL_DeleteContext(context);

    // enable OpenGL3
    DerelictGL3.reload();
    dwritefln("OpenGL version: %s", DerelictGL3.loadedVersion);

    dg();

    SDL_Delay(10000);
}

private:

SDL_WindowFlags windowFlags(ref const(GuiOptions) options) @safe pure nothrow @nogc {
    SDL_WindowFlags flags;
    if(options.windowShown) flags |= SDL_WINDOW_SHOWN;
    if(options.windowHidden) flags |= SDL_WINDOW_HIDDEN;
    if(options.windowBorderless) flags |= SDL_WINDOW_BORDERLESS;
    if(options.windowResizeable) flags |= SDL_WINDOW_RESIZABLE;
    if(options.windowMinimized) flags |= SDL_WINDOW_MINIMIZED;
    if(options.windowMaximized) flags |= SDL_WINDOW_MAXIMIZED;
    if(options.fullScreen) flags |= SDL_WINDOW_FULLSCREEN;
    if(options.fullScreenDesktop) flags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
    return flags;
}

