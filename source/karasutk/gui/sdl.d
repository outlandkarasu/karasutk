/**
 *  SDL utility module.
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.sdl;

import std.string : fromStringz;
import std.format : format;

import derelict.sdl2.sdl : SDL_GetError;

/**
 *  SDL related exceptions.
 */
class SdlException : Exception {
    @nogc @safe pure nothrow this(
            string msg,
            string file = __FILE__,
            size_t line = __LINE__,
            Throwable next = null) {
        super(msg, file, line, next);
    }

    @nogc @safe pure nothrow this(
            string msg,
            Throwable next,
            string file = __FILE__,
            size_t line = __LINE__) {
        super(msg, file, line, next);
    }
}

/// Enforce that the SDL not have error.
T enforceSdl(T)(
        T value,
        lazy const(char)[] msg = null,
        string file = __FILE__,
        size_t line = __LINE__) if (is(typeof((){if(!value){}}))) {
    if(!value) {
        auto errorMessage = format("%s : %s", fromStringz(SDL_GetError()), msg);
        throw new SdlException(errorMessage, file, line);
    }
    return value;
}

