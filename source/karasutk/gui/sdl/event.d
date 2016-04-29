/**
 *  event queue for SDL
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl.event;

import karasutk.gui.event;

import karasutk.gui.sdl.keycode;

import derelict.sdl2.sdl;

class SdlEventQueue : AbstractEventQueue {

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
}

