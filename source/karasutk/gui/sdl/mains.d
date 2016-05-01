/**
 *  main functions for SDL application
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.mains;

import karasutk.gui.mains;
import karasutk.gui.sdl.context;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3 : DerelictGL3;
import karasutk.dbg : dwritefln;
import karasutk.gui.sdl.context : SdlContext;
import karasutk.gui.sdl.event : SdlEventQueue;
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

    // create main window.
    scope window = new SdlWindow(options);

    // enable OpenGL3
    DerelictGL3.reload();
    dwritefln("OpenGL version: %s", DerelictGL3.loadedVersion);

    // call main function.
    scope context = new SdlContext();
    scope eventQueue = new SdlEventQueue();
    mainFunction(GuiEnvironment(context, window, eventQueue));
}

