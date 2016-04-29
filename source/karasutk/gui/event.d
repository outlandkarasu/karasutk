/**
 *  main functions for GUI application
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.event;

import std.traits : isCallable, isImplicitlyConvertible, Parameters;

import karasutk.gui.aliases;

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

    enum : Type {
        UP,
        DOWN,
    }

    Type type;
    KeyCode keyCode;
}

/// GUI event queue 
abstract class AbstractEventQueue {

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

    void dispatchKeyEvent(KeyEvent event) {
        if(keyEvent_) {keyEvent_(event);}
    }

    void dispatchQuitEvent(QuitEvent event) {
        if(quitEvent_) {quitEvent_(event);}
    }

private:
    EventHandler!KeyEvent keyEvent_;
    EventHandler!QuitEvent quitEvent_;
}

import karasutk.gui.sdl.event;
alias EventQueue = SdlEventQueue;

