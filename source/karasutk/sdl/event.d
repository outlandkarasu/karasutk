/**
Authors: outland.karasu
License: BSL-1.0
*/

module karasutk.sdl.event;

import bindbc.sdl :
    SDL_Delay,
    SDL_Event,
    SDL_GetPerformanceCounter,
    SDL_GetPerformanceFrequency,
    SDL_GL_SwapWindow,
    SDL_QUIT,
    SDL_QuitEvent,
    SDL_PollEvent,
    SDL_Window;

import karasutk.sdl.window : Window;

/**
Event handlers.
*/
struct EventHandlers
{
    /**
    Event handler result.
    */
    enum Result
    {
        /**
        Continue loop.
        */
        continueLoop,

        /**
        Quit loop.
        */
        quitLoop,
    }

    /**
    Event handler type.
    */
    alias Handler = Result delegate(scope ref const(SDL_Event));

    /**
    Draw function.
    */
    alias DrawHandler = Result delegate();

    Handler onQuit;
    DrawHandler onDraw;
    float fps = 60.0f;

    /**
    Handle current event.

    Params:
        event = current event.
    */
    Result handle(ref const(SDL_Event) event)
    {
        switch (event.type)
        {
        case SDL_QUIT: return callHandler(onQuit, event);
        default: return Result.continueLoop;
        }
    }

private:

    static Result callHandler(scope Handler handler, ref const(SDL_Event) event)
    {
        if (handler)
        {
            return handler(event);
        }

        // default handler.
        return (event.type == SDL_QUIT) ? Result.quitLoop : Result.continueLoop;
    }
}

/**
Run event loop.

Params:
    window = event target window.
    handlers = event handlers.
    fps = frames per second.
*/
void runEventLoop()(auto scope ref Window window, auto scope ref EventHandlers handlers, float fps = 60.0f)
{
    immutable performanceFrequency = SDL_GetPerformanceFrequency();
    immutable countPerFrame = performanceFrequency / fps;

    auto fpsStart = SDL_GetPerformanceFrequency();
    uint frameCount = 0;
    immutable fpsMesureSeconds = 3.0f;
    immutable fpsMesureInterval = fpsMesureSeconds * performanceFrequency;
    float actualFPS = 0.0f;

    for (SDL_Event event; ;)
    {
        immutable frameStart = SDL_GetPerformanceCounter();

        // update actual FPS.
        if (frameStart - fpsStart > fpsMesureInterval)
        {
            actualFPS = frameCount / fpsMesureSeconds;
            fpsStart = frameStart;
            frameCount = 0;
        }

        while (SDL_PollEvent(&event))
        {
            if (handlers.handle(event) == EventHandlers.Result.quitLoop)
            {
                // quit event loop.
                return;
            }
        }

        // draw a frame.
        if (handlers.onDraw)
        {
            handlers.onDraw();
            SDL_GL_SwapWindow(window.ptr);
        }

        // wait next frame timing.
        immutable drawDelay = SDL_GetPerformanceCounter() - frameStart;
        immutable waitDelay = (countPerFrame < drawDelay)
            ? 0 : cast(uint)((countPerFrame - drawDelay) * 1000.0 / performanceFrequency);
        ++frameCount;
        SDL_Delay(waitDelay);
    }
}

