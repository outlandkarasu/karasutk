/**
 *  main functions for GUI application
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.event;

import std.traits : isCallable, isImplicitlyConvertible, Parameters;

import derelict.sdl2.sdl;

/// event queue status result
enum EventResult {
    QUIT = -1,
    EMPTY = 0,
    NOT_EMPTY,
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

    /// check event handler type
    enum isEventHandlable(H, E)
        = isCallable!H && isImplicitlyConvertible!(const(E), Parameters!H[0]);

    /// event handler type
    alias EventHandler(E) = void delegate(ref const(E) event);

    /// generic functions to EventHandler
    auto toEventHandler(E, F)(F f) @safe if(isEventHandlable!(F, E)) {
        return delegate void(ref const(E) e) {f(e);};
    }

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

package:

class SdlEventQueue : EventQueue {

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

