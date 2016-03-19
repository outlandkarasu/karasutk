/**
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.mains;

import std.string : toStringz;
import std.traits : isCallable, isImplicitlyConvertible, Parameters;

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

/// check for main function.
enum isMainFunction(F) = isCallable!F && isImplicitlyConvertible!(EventQueue, Parameters!F[0]);

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

    auto eventQueue = new SDLEventQueue();

    mainFunction(eventQueue);
}

/// event queue status result
enum EventResult {
    QUIT = -1,
    EMPTY = 0,
    NOT_EMPTY,
}

@safe pure nothrow @nogc {
    bool isQuit(EventResult r) {return r == EventResult.QUIT;}
    bool isEmpty(EventResult r) {return r == EventResult.EMPTY;}
    bool isNotEmpty(EventResult r) {return r == EventResult.NOT_EMPTY;}
}

/// event handler type
alias EventHandler(E) = void delegate(ref const(E) event);

/// check event handler type
enum isEventHandlable(H, E)
    = isCallable!H && isImplicitlyConvertible!(const(E), Parameters!H[0]);

/// generic functions to EventHandler
auto toEventHandler(E, F)(F f) @safe if(isEventHandlable!(F, E)) {
    return delegate void(ref const(E) e) {f(e);};
}

/// application quit event structure.
struct QuitEvent {
}

/// Key down up event structure
struct KeyEvent {

    /// event type
    alias Type = int;

    /// key code type
    alias Code = uint;

    enum : Type {
        UP,
        DOWN,
    }

    Type type;
    Code code;
}

/// GUI event queue 
abstract class EventQueue {

    /**
     *  process a queued event.
     *
     *  Returns:
     *      queue status
     */
    abstract EventResult process() @system;

    @property void onKey(F)(F f) @safe if(isEventHandlable!(F, KeyEvent)) {
        keyEvent_ = toEventHandler!KeyEvent(f);
    }

    @property void onQuit(F)(F f) @safe if(isEventHandlable!(F, QuitEvent)) {
        quitEvent_ = toEventHandler!KeyEvent(f);
    }

private:

    void dispatchKeyEvent(KeyEvent event) {if(keyEvent_) {keyEvent_(event);}}
    EventHandler!KeyEvent keyEvent_;

    void dispatchQuitEvent(QuitEvent event) {if(quitEvent_) {quitEvent_(event);}}
    EventHandler!QuitEvent quitEvent_;
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

class SDLEventQueue : EventQueue {

    override EventResult process() @system {
        SDL_Event event;
        if(!SDL_PollEvent(&event)) {
            return EventResult.EMPTY;
        }

        switch(event.type) {
        case SDL_KEYDOWN:
            dispatchKeyEvent(KeyEvent(KeyEvent.DOWN, event.key.keysym.sym));
            break;
        case SDL_KEYUP:
            dispatchKeyEvent(KeyEvent(KeyEvent.UP, event.key.keysym.sym));
            break;
        case SDL_QUIT:
            dispatchQuitEvent(QuitEvent());
            return EventResult.QUIT;
        default:
            break;
        }

        return EventResult.NOT_EMPTY;
    }
}

