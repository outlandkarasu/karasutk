/**
 *  event queue for SDL
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.event;

import karasutk.gui.event;

import karasutk.gui.sdl.context : SdlContext;
import karasutk.gui.sdl.keycode;
import karasutk.gui.sdl.utils : enforceSdl;

import derelict.sdl2.sdl;

class SdlEventQueue : AbstractEventQueue {

    /// constructor with context
    this(SdlContext context) {}

    override EventResult process() @system {
        SDL_Event event;
        if(!SDL_PollEvent(&event)) {
            return EventResult.EMPTY;
        }

        switch(event.type) {
        case SDL_KEYDOWN:
            dispatchKeyEvent(KeyEvent(KeyEvent.DOWN, cast(SdlKeyCode) event.key.keysym.sym));
            break;
        case SDL_KEYUP:
            dispatchKeyEvent(KeyEvent(KeyEvent.UP, cast(SdlKeyCode) event.key.keysym.sym));
            break;
        case SDL_QUIT:
            dispatchQuitEvent(QuitEvent());
            return EventResult.QUIT;
        default:
            break;
        }

        return EventResult.NOT_EMPTY;
    }

    override void quit() {
        SDL_Event event;
        event.type = SDL_QUIT;
        enforceSdl(SDL_PushEvent(&event));
    }
}

