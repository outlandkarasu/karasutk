/**
 *  main functions for SDL application
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.mains;

import karasutk.gui.mains;
import karasutk.gui.sdl.context;

import std.string : toStringz;
import derelict.sdl2.sdl;
import derelict.opengl3.gl3 : DerelictGL3;
import karasutk.dbg : dwritefln;
import karasutk.gui.sdl.utils : enforceSdl;

/**
 *  Run a dg during GUI.
 *
 *  Params:
 *      options = GUI options.
 *      mainFunction = the main function or delegate.
 */
void doGuiMain(F)(ref const(GuiOptions) options, F mainFunction) if(isMainFunction!F) {
    DerelictSDL2.load();
    scope(exit) DerelictSDL2.unload();

    DerelictGL3.load();
    scope(exit) DerelictGL3.unload();

    enforceSdl(SDL_Init(SDL_INIT_EVERYTHING) == 0);
    scope(exit) SDL_Quit();

    // set up OpenGL
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

    // create the main window
    auto window = enforceSdl(SDL_CreateWindow(
        toStringz(options.windowTitle),
        options.windowCenterX ? SDL_WINDOWPOS_CENTERED : options.windowPositionX,
        options.windowCenterY ? SDL_WINDOWPOS_CENTERED : options.windowPositionY,
        options.windowWidth,
        options.windowHeight,
        SDL_WINDOW_OPENGL | options.windowFlags));
    scope(exit) SDL_DestroyWindow(window);

    // create the OpenGL context.
    auto context = enforceSdl(SDL_GL_CreateContext(window));
    scope(exit) SDL_GL_DeleteContext(context);

    // enable OpenGL3
    DerelictGL3.reload();
    dwritefln("OpenGL version: %s", DerelictGL3.loadedVersion);

    auto app = new SdlContext(window);
    try {
        mainFunction(app);
    } catch(Throwable e) {
        import std.stdio;
        stderr.writefln("error: %s", e);
    }
}

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

