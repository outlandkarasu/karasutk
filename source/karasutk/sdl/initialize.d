/**
Authors: outland.karasu
License: BSL-1.0
*/

module karasutk.sdl.initialize;

import std.exception : enforce;
import std.traits : isCallable;

import bindbc.sdl :
    loadSDL,
    SDL_Init,
    SDL_INIT_VIDEO,
    SDL_Quit,
    sdlSupport,
    SDLSupport,
    unloadSDL;

import karasutk.sdl.exception :
    enforceSDL,
    SDLException;

/**
During SDL2 library.
Params:
    f = application function.
Throws:
    SDLException if failed.
*/
void duringSDL(F)(scope F f) if (isCallable!F)
{
    immutable support = loadSDL();
    if (support != sdlSupport)
    {
        enforce!SDLException(support != SDLSupport.noLibrary, "No library");
        enforce!SDLException(support != SDLSupport.badLibrary, "Bad library");
    }

    scope(exit) unloadSDL();

    // initialize SDL subsystem.
    enforceSDL(SDL_Init(SDL_INIT_VIDEO));
    scope(exit) SDL_Quit();

    f();
}

