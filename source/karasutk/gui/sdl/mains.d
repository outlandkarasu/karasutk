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
import karasutk.gui.sdl.context : SdlContext;
import karasutk.gui.sdl.utils : enforceSdl;
import karasutk.gui.sdl.window : SdlWindow;

/**
 *  Run a dg during GUI.
 *
 *  Params:
 *      options = GUI options.
 *      mainFunction = the main function or delegate.
 */
void sdlDoGuiMain(F)(
        ref const(GuiOptions) options,
        F mainFunction) if(isMainFunction!F) {
    DerelictSDL2.load();
    scope(exit) DerelictSDL2.unload();

    DerelictGL3.load();
    scope(exit) DerelictGL3.unload();

    enforceSdl(SDL_Init(SDL_INIT_EVERYTHING) == 0);
    scope(exit) SDL_Quit();

    // create the main window
    auto window = enforceSdl(SDL_CreateWindow(
        toStringz(options.windowTitle),
        options.windowCenterX ? SDL_WINDOWPOS_CENTERED : options.windowPositionX,
        options.windowCenterY ? SDL_WINDOWPOS_CENTERED : options.windowPositionY,
        options.windowWidth,
        options.windowHeight,
        SDL_WINDOW_OPENGL | options.windowFlags));
    scope(exit) SDL_DestroyWindow(window);
    auto sdlWindow = new SdlWindow(window);

    // create the OpenGL context.
    scope context = new SdlContext(window);

    // enable OpenGL3
    DerelictGL3.reload();
    dwritefln("OpenGL version: %s", DerelictGL3.loadedVersion);

    try {
        mainFunction(context, sdlWindow);
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

