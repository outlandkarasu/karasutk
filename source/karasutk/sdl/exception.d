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
        throw createCurrentError(file, line);
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
        throw createCurrentError(file, line);
    }

    return result;
}

/**
Enforce SDL result.
Params:
    file = file name.
    line = line no.
    result = result flag.
Returns:
    result code.
Throws:
    SDLException if result is false.
*/
int enforceSDL(string file = __FILE__, size_t line = __LINE__)(bool result)
{
    if (!result)
    {
        throw createCurrentError(file, line);
    }

    return result;
}

private:

SDLException createCurrentError(string file, size_t line) nothrow
{
    immutable message = fromStringz(SDL_GetError()).idup;
    return new SDLException(message, file, line);
}

