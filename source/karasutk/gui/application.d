/**
 *  application module
 *
 *  Authors: outland.karasu
 *  License: BSL-1.0
 */

module karasutk.gui.application;

import karasutk.gui.mains;
import karasutk.gui.mesh;
import karasutk.gui.shader;
import karasutk.gui.texture;
import karasutk.gui.event;

import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

/// application objects holder.
abstract class Application {

    this(SdlEventQueue eventQueue,
            SdlMeshFactory meshFactory,
            SdlShaderFactory shaderFactory,
            SdlTextureFactory textureFactory) @safe @nogc nothrow {
        this.eventQueue_ = eventQueue;
        this.meshFactory_ = meshFactory;
        this.textureFactory_ = textureFactory;
        this.shaderFactory_ = shaderFactory;
    }

    @property @safe pure nothrow @nogc {
        SdlEventQueue eventQueue() {return eventQueue_;}
        SdlMeshFactory meshFactory() {return meshFactory_;}
        SdlTextureFactory textureFactory() {return textureFactory_;}
        SdlShaderFactory shaderFactory() {return shaderFactory_;}
    }

    /// draw next frame
    abstract void drawFrame(void delegate() dg);

    @property const {
        uint windowWidth();
        uint windowHeight();
    }

    void quit();

private:
    SdlEventQueue eventQueue_;
    SdlMeshFactory meshFactory_;
    SdlTextureFactory textureFactory_;
    SdlShaderFactory shaderFactory_;
}

package:

class SdlApplication : Application {

    this(SDL_Window* window) @safe {
        super(new SdlEventQueue(),
                new SdlMeshFactory(),
                new SdlShaderFactory(),
                new SdlTextureFactory());
        this.window_ = window;
    }

    override void drawFrame(void delegate() dg) {
        scope(exit) {
            glFlush();
            SDL_GL_SwapWindow(window_);
        }
        glEnable(GL_DEPTH_TEST);
        scope(exit) glDisable(GL_DEPTH_TEST);

        glEnable(GL_CULL_FACE);
        scope(exit) glDisable(GL_CULL_FACE);

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        dg();
    }

    override @property const {

        uint windowWidth() {
            int result = 0;
            SDL_GetWindowSize(cast(SDL_Window*) window_, &result, cast(int*) null);
            return result;
        }

        uint windowHeight() {
            int result = 0;
            SDL_GetWindowSize(cast(SDL_Window*) window_, cast(int*) null, &result);
            return result;
        }
    }

    override void quit() {
        SDL_Event event;
        event.type = SDL_QUIT;
        enforceSdl(SDL_PushEvent(&event));
    }

private:

    SDL_Window* window_;
}

