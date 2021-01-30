/**
Authors: outland.karasu
License: BSL-1.0
*/

module karasutk.sdl.exception;

import std.exception : basicExceptionCtors;
import std.string : fromStringz;
import std.traits : isPointer;

import bindbc.sdl : SDL_GetError;

/**
Exception for SDL2 errors.
*/
@safe
class SDLException : Exception
{
    ///
    mixin basicExceptionCtors;
}

/**
Enforce SDL result.
Params:
    file = file name.
    line = line no.
    result = result code.
Returns:
    result code.
Throws:
    SDLException if result is nonzero.
*/
int enforceSDL(string file = __FILE__, size_t line = __LINE__)(int result)
{
    if (result != 0)
    {
        immutable message = fromStringz(SDL_GetError()).idup;
        throw new SDLException(message, file, line);
    }

    return result;
}

/**
Enforce SDL result.
Params:
    file = file name.
    line = line no.
    P = pointer type.
    result = result code.
Returns:
    result code.
Throws:
    SDLException if result is nonzero.
*/
P enforceSDL(string file = __FILE__, size_t line = __LINE__, P)(scope P result) if (isPointer!P)
{
    if (!result)
    {
        immutable message = fromStringz(SDL_GetError()).idup;
        throw new SDLException(message, file, line);
    }

    return result;
}

